#!/bin/bash
# build.sh — 从上游 decolua/9router 源码构建 9Router fnOS fpk（纯净上游 + 更新检查补丁）
#
# 用法:
#   ./build.sh [VERSION] [ARCH]
# 示例:
#   ./build.sh 0.5.91 x86      # 构建 x86 fpk（版本号缺省时自动读上游 package.json）
#   ./build.sh 0.5.91 arm      # 构建 arm fpk
#   ./build.sh                 # 自动版本, x86
#
# 对上游源码的唯一改动 = patches/update-check-9router-fnos.mjs（更新检查指向本仓库
# Releases），其余逐字节保持上游原样。
#
# 前置依赖: git, node 22+, npm, curl, fnpack (脚本会自动下载 fnpack)
#
# 输出: 9router-<VERSION>-<ARCH>.fpk (放在 repo 根目录)

set -euo pipefail

VERSION_ARG="${1:-}"
ARCH="${2:-x86}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="/tmp/build-9router-fpk-$$"
FNPACK_VERSION="1.2.1"

# fnpack SHA256 校验
if [ "$ARCH" = "arm" ]; then
    FNPACK_BIN="fnpack-${FNPACK_VERSION}-linux-arm64"
    FNPACK_SHA256="aad9e16b101267d30017f39ab969e3c085fbce209716f8bd3b1e167eaf15e0cf"
else
    FNPACK_BIN="fnpack-${FNPACK_VERSION}-linux-amd64"
    FNPACK_SHA256="72d2a4095da676b64510b023731a227b369d80f8079bc45ff8a2f802ec0480c1"
fi

echo "=========================================="
echo "  9Router fnOS fpk 构建"
echo "  Arch:    ${ARCH}"
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

# ── 5. 组装 app/server ──
echo ""
echo "[4/9] 组装 app/server..."
mkdir -p "${BUILD_DIR}/app/server"

# Next.js standalone 输出
cp -r "${STANDALONE}/." "${BUILD_DIR}/app/server/"

# custom-server.js (已在 postbuild 时拷贝到 standalone, 此处为兜底)
if [ -f "custom-server.js" ] && [ ! -f "${BUILD_DIR}/app/server/custom-server.js" ]; then
    cp custom-server.js "${BUILD_DIR}/app/server/"
fi

# open-sse 路由引擎 (Next tracing 不包含, 需手动补拷)
cp -r open-sse "${BUILD_DIR}/app/server/"

# src/mitm (MITM 功能)
cp -r src/mitm "${BUILD_DIR}/app/server/"

# 原生模块 / tracing 不含的运行时依赖（存在才拷）
mkdir -p "${BUILD_DIR}/app/server/node_modules"
for pkg in node-forge sql.js next better-sqlite3; do
    if [ -d "node_modules/${pkg}" ]; then
        cp -r "node_modules/${pkg}" "${BUILD_DIR}/app/server/node_modules/"
    fi
done

# ── 6. 复制 fnOS 打包结构 ──
echo ""
echo "[5/9] 复制 fnOS 打包结构..."
cp -r "${REPO_ROOT}/cmd" "${BUILD_DIR}/"
cp -r "${REPO_ROOT}/app/ui" "${BUILD_DIR}/app/"
cp -r "${REPO_ROOT}/config" "${BUILD_DIR}/"
cp -r "${REPO_ROOT}/wizard" "${BUILD_DIR}/"
cp "${REPO_ROOT}/ICON.PNG" "${BUILD_DIR}/"
cp "${REPO_ROOT}/ICON_256.PNG" "${BUILD_DIR}/"

# ── 7. 生成 manifest ──
echo ""
echo "[6/9] 生成 manifest..."
cat > "${BUILD_DIR}/manifest" <<EOF
appname               = 9router
version               = ${VERSION}
display_name          = 9Router
desc                  = FREE AI Router & Token Saver - AI 编码路由器（上游 9Router，端口 20128）
platform              = ${ARCH}
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

# ── 8. 更新 app/ui/config ──
echo ""
echo "[7/9] 更新 UI 配置..."
cat > "${BUILD_DIR}/app/ui/config" <<'EOF'
{
  ".url": {
    "9router.Application": {
      "title": "9Router",
      "icon": "images/icon_{0}.png",
      "type": "url",
      "protocol": "http",
      "port": "20128",
      "url": "/",
      "allUsers": true
    }
  }
}
EOF

# 更新 config/resource (数据共享)
cat > "${BUILD_DIR}/config/resource" <<'EOF'
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

# ── 9. 清理符号链接 ──
echo ""
echo "[8/9] 清理符号链接..."
find "${BUILD_DIR}" -type l -not -path '*/.git/*' -delete 2>/dev/null || true

# ── 10. 下载并校验 fnpack ──
echo ""
echo "[9/9] 下载 fnpack + 构建 fpk..."
FNPACK_DIR="${FNPACK_DIR:-$HOME/.local/bin}"
mkdir -p "${FNPACK_DIR}"
if [ ! -x "${FNPACK_DIR}/fnpack" ]; then
    curl -fsSL -o "${FNPACK_DIR}/fnpack" "https://static2.fnnas.com/fnpack/${FNPACK_BIN}"
    echo "${FNPACK_SHA256}  ${FNPACK_DIR}/fnpack" | sha256sum -c -
    chmod +x "${FNPACK_DIR}/fnpack"
fi
export PATH="${FNPACK_DIR}:${PATH}"

cd "${BUILD_DIR}"
fnpack build -d .

# ── 11. 输出 ──
OUTPUT_FPK="9router-${VERSION}-${ARCH}.fpk"
mv 9router.fpk "${REPO_ROOT}/${OUTPUT_FPK}"

echo ""
echo "=========================================="
echo "  构建完成: ${REPO_ROOT}/${OUTPUT_FPK}"
ls -lh "${REPO_ROOT}/${OUTPUT_FPK}"
echo "=========================================="

# 清理
rm -rf "${BUILD_DIR}"
