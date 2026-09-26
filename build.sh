#!/bin/bash
# build.sh — 从上游 decolua/9router 源码构建 9Router fnOS fpk（纯净上游 + 更新检查补丁）
#
# 用法:
#   ./build.sh [VERSION] [ARCH]
# 示例:
#   ./build.sh 0.5.91 x86      # 仅离线 x86（版本号缺省时自动读上游 package.json）
#   ./build.sh                 # 自动版本, 四变体全打
#
# ARCH 参数保留兼容：给定时只打该架构的离线变体；缺省打全部四个变体
#   9router-<v>-x86.fpk          离线（内置构建产物），浏览器打开
#   9router-<v>-iframe-x86.fpk   离线，桌面内嵌
#   9router-<v>-all.fpk          在线构建（内置源码树），浏览器打开, x86/ARM 通用
#   9router-<v>-iframe-all.fpk   在线构建，桌面内嵌, x86/ARM 通用
#
# 对上游源码的唯一改动 = patches/update-check-9router-fnos.mjs（更新检查指向本仓库
# Releases），其余逐字节保持上游原样。
#
# 前置依赖: git, node 22+, npm, curl, fnpack (脚本会自动下载到 ~/.local/bin)
#
# 输出: 9router-<VERSION>[-iframe][-x86|all].fpk (放在 repo 根目录)

set -euo pipefail

VERSION_ARG="${1:-}"
ARCH_ARG="${2:-}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$HOME/projects/build-9router-fpk-$$}"
FNPACK_VERSION="1.2.1"

# fnpack SHA256 校验
if [ "$ARCH_ARG" = "arm" ]; then
    FNPACK_BIN="fnpack-${FNPACK_VERSION}-linux-arm64"
    FNPACK_SHA256="aad9e16b101267d30017f39ab969e3c085fbce209716f8bd3b1e167eaf15e0cf"
else
    FNPACK_BIN="fnpack-${FNPACK_VERSION}-linux-amd64"
    FNPACK_SHA256="72d2a4095da676b64510b023731a227b369d80f8079bc45ff8a2f802ec0480c1"
fi

echo "=========================================="
echo "  9Router fnOS fpk 构建"
echo "  Arch:    ${ARCH_ARG:-x86+all}"
echo "=========================================="

# ── 1. 清理并创建构建目录 ──
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# ── 2. 克隆上游源码 ──
echo ""
echo "[1/9] 克隆 decolua/9router..."
cd "${BUILD_DIR}"
git clone --depth 1 https://github.com/decolua/9router.git upstream 2>&1 | tail -3

# ── 3. 应用更新检查补丁（唯一改动）──
echo ""
echo "[2/9] 应用 patches/update-check-9router-fnos.mjs..."
cd upstream
node "${REPO_ROOT}/patches/update-check-9router-fnos.mjs"

# ── 4. 安装依赖并构建 ──
echo ""
echo "[3/9] 安装依赖 + 构建 standalone..."
npm install --no-audit --no-fund 2>&1 | tail -3
NEXT_DIST_DIR=.next-cli-build npm run build 2>&1 | tail -5

STANDALONE=".next-cli-build/standalone"
if [ ! -d "${STANDALONE}" ]; then
    echo "ERROR: standalone 构建产物未找到 (${STANDALONE})"
    exit 1
fi

# 版本号：参数 > 上游 package.json
if [ -n "${VERSION_ARG}" ]; then
    VERSION="${VERSION_ARG}"
else
    VERSION="$(node -p "require('$(pwd)/package.json').version")"
fi
echo "  Version: ${VERSION}"

# ── 5. 组装四个变体（x86/all × url/iframe）──
# 每个变体独立 staging 目录；fnpack build -d . 打包当前目录。
pack_variant() {
    MODE="$1"   # x86（离线，内置构建产物） | all（在线构建，内置源码树）
    UI="$2"     # url | iframe
    local STAGE="${BUILD_DIR}/pack-${UI}-${MODE}"
    rm -rf "${STAGE}"; mkdir -p "${STAGE}/app"

    # server 内容
    if [ "${MODE}" = "x86" ]; then
        mkdir -p "${STAGE}/app/server"
        cp -r "${STANDALONE}/." "${STAGE}/app/server/"
        if [ -f "custom-server.js" ] && [ ! -f "${STAGE}/app/server/custom-server.js" ]; then
            cp custom-server.js "${STAGE}/app/server/"
        fi
        cp -r open-sse "${STAGE}/app/server/"
        cp -r src/mitm "${STAGE}/app/server/"
        # 原生模块 / tracing 不含的运行时依赖（存在才拷）
        mkdir -p "${STAGE}/app/server/node_modules"
        for pkg in node-forge sql.js next better-sqlite3; do
            [ -d "node_modules/${pkg}" ] && cp -r "node_modules/${pkg}" "${STAGE}/app/server/node_modules/" || true
        done
        PLATFORM="x86"
    else
        # 源码树（排除 .git / node_modules / 构建产物），装时在线 npm install + build
        mkdir -p "${STAGE}/app/server"
        (tar -C . --exclude=./.git --exclude=./node_modules --exclude=./.next --exclude=./.next-cli-build -cf - .) | tar -C "${STAGE}/app/server" -xf -
        PLATFORM="all"
    fi

    # fnOS 胶水 + 图标
    cp -r "${REPO_ROOT}/cmd" "${STAGE}/"
    cp -r "${REPO_ROOT}/app/ui" "${STAGE}/app/"
    cp -r "${REPO_ROOT}/config" "${STAGE}/"
    cp -r "${REPO_ROOT}/wizard" "${STAGE}/"
    cp "${REPO_ROOT}/ICON.PNG" "${REPO_ROOT}/ICON_256.PNG" "${STAGE}/"

    # manifest
    cat > "${STAGE}/manifest" <<EOF
appname               = 9router
version               = ${VERSION}
display_name          = 9Router
desc                  = FREE AI Router & Token Saver - AI 编码路由器（上游 9Router，端口 20128）
platform              = ${PLATFORM}
source                = thirdparty
maintainer            = decolua
maintainer_url        = https://github.com/decolua/9router
distributor           = techysy
distributor_url       = https://github.com/techysy/9router-fnos
desktop_uidir         = ui
desktop_applaunchname = 9router.Application
service_port          = 20128
ctl_stop              = true
install_dep_apps      = nodejs_v24
EOF

    # ui/config：url（浏览器打开）| iframe（桌面内嵌）
    write_ui_config() {
        cat > "${STAGE}/app/ui/config" <<EOF
{
  ".url": {
    "9router.Application": {
      "title": "9Router",
      "icon": "images/icon_{0}.png",
      "type": "$1",
      "protocol": "http",
      "port": "20128",
      "url": "/",
      "allUsers": true
    }
  }
}
EOF
    }
    write_ui_config "${UI}"

    # 数据共享
    cat > "${STAGE}/config/resource" <<'EOF'
{
    "data-share":
    {
        "shares": [
            {
                "name": "9router",
                "permission":
                {
                    "rw": ["9router"]
                }
            },
            {
                "name": "9router/data",
                "permission":
                {
                    "rw": ["9router"]
                }
            }
        ]
    }
}
EOF

    echo "  packing ${UI}-${MODE} ..."
    cd "${STAGE}"
    fnpack build -d . >/dev/null
    local SUFFIX=""
    [ "${UI}" = "iframe" ] && SUFFIX="-iframe"
    mv 9router.fpk "${REPO_ROOT}/9router-${VERSION}${SUFFIX}-${MODE}.fpk"
    cd "${BUILD_DIR}/upstream"
}

# ── 6. 下载并校验 fnpack ──
echo ""
echo "[4/9] 下载 fnpack..."
FNPACK_DIR="${FNPACK_DIR:-$HOME/.local/bin}"
mkdir -p "${FNPACK_DIR}"
if [ ! -x "${FNPACK_DIR}/fnpack" ]; then
    curl -fsSL -o "${FNPACK_DIR}/fnpack" "https://static2.fnnas.com/fnpack/${FNPACK_BIN}"
    echo "${FNPACK_SHA256}  ${FNPACK_DIR}/fnpack" | sha256sum -c -
    chmod +x "${FNPACK_DIR}/fnpack"
fi
export PATH="${FNPACK_DIR}:${PATH}"

# ── 7. 打变体 ──
echo ""
echo "[5/9] 打包变体..."
# fnpack 会把包复制到自己的临时目录 —— 落在真实磁盘上，避免 tmpfs 配额打满
export TMPDIR="${BUILD_DIR}-fnpack-tmp"
mkdir -p "${TMPDIR}"

if [ -n "${ARCH_ARG}" ]; then
    # 兼容旧行为：显式给架构 = 只打该架构离线包
    pack_variant "${ARCH_ARG}" url
else
    pack_variant x86  url
    pack_variant x86  iframe
    pack_variant all  url
    pack_variant all  iframe
fi

echo ""
echo "[6/9] 产物："
ls -lh "${REPO_ROOT}"/9router-*.fpk

# ── 8. 清理 ──
echo ""
echo "[7/9] 清理..."
rm -rf "${BUILD_DIR}" "${TMPDIR}"

echo ""
echo "=========================================="
echo "  构建完成"
ls -lh "${REPO_ROOT}"/9router-*.fpk
echo "=========================================="
