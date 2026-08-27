#!/bin/bash
# build-10router-fpk.sh — 从上游 decolua/9router 源码构建 10Router fnOS fpk
#
# 用法:
#   ./build.sh [VERSION] [ARCH]
# 示例:
#   ./build.sh 1.0.0 x86       # 构建 x86 fpk
#   ./build.sh 1.0.0 arm       # 构建 arm fpk
#   ./build.sh                 # 默认 1.0.0 x86
#
# 前置依赖: git, node 22+, npm, curl, fnpack (脚本会自动下载 fnpack)
#
# 输出: 10router-<VERSION>-<ARCH>.fpk (放在 repo 根目录)

set -euo pipefail

VERSION="${1:-1.0.0}"
ARCH="${2:-x86}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="/tmp/build-10router-fpk-$$"
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
echo "  10Router fnOS fpk 构建"
echo "  Version: ${VERSION}"
echo "  Arch:    ${ARCH}"
echo "=========================================="

# ── 1. 清理并创建构建目录 ──
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# ── 2. 克隆上游源码 ──
echo ""
echo "[1/8] 克隆 decolua/9router..."
cd "${BUILD_DIR}"
git clone --depth 1 https://github.com/decolua/9router.git upstream 2>&1 | tail -3

# ── 3. 安装依赖并构建 ──
echo ""
echo "[2/8] 安装依赖 + 构建 standalone..."
cd upstream
npm install --no-audit --no-fund 2>&1 | tail -3
NEXT_DIST_DIR=.next-cli-build npm run build 2>&1 | tail -5

STANDALONE=".next-cli-build/standalone"
if [ ! -d "${STANDALONE}" ]; then
    echo "ERROR: standalone 构建产物未找到 (${STANDALONE})"
    exit 1
fi

# ── 4. 组装 app/server ──
echo ""
echo "[3/8] 组装 app/server..."
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

# 原生模块 (better-sqlite3/sql.js 运行时需要)
mkdir -p "${BUILD_DIR}/app/server/node_modules"
for pkg in node-forge sql.js; do
    if [ -d "node_modules/${pkg}" ]; then
        cp -r "node_modules/${pkg}" "${BUILD_DIR}/app/server/node_modules/"
    fi
done

# ── 5. 复制 fnOS 打包结构 ──
echo ""
echo "[4/8] 复制 fnOS 打包结构..."
cp -r "${REPO_ROOT}/cmd" "${BUILD_DIR}/"
cp -r "${REPO_ROOT}/app/ui" "${BUILD_DIR}/app/"
cp -r "${REPO_ROOT}/config" "${BUILD_DIR}/"
cp -r "${REPO_ROOT}/wizard" "${BUILD_DIR}/"
cp "${REPO_ROOT}/ICON.PNG" "${BUILD_DIR}/"
cp "${REPO_ROOT}/ICON_256.PNG" "${BUILD_DIR}/"

# ── 6. 生成 manifest ──
echo ""
echo "[5/8] 生成 manifest..."
cat > "${BUILD_DIR}/manifest" <<EOF
appname               = 10router
version               = ${VERSION}
display_name          = 10Router
desc                  = FREE AI Router & Token Saver - AI 编码路由器（10Router 版，端口 20128）
platform              = ${ARCH}
source                = thirdparty
maintainer            = decolua
maintainer_url        = https://github.com/decolua/9router
distributor           = techysy
distributor_url       = https://github.com/techysy/9router-fnos
desktop_uidir         = ui
desktop_applaunchname = 10router.Application
service_port          = 20128
ctl_stop              = true
install_dep_apps      = nodejs_v24
EOF

# ── 7. 更新 app/ui/config ──
echo ""
echo "[6/8] 更新 UI 配置..."
cat > "${BUILD_DIR}/app/ui/config" <<'EOF'
{
  ".url": {
    "10router.Application": {
      "title": "10Router",
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
                "name": "10router",
                "permission":
                {
                    "rw": ["10router"]
                }
            },
            {
                "name": "10router/data",
                "permission":
                {
                    "rw": ["10router"]
                }
            }
        ]
    }
}
EOF

# ── 8. 清理符号链接 ──
echo ""
echo "[7/8] 清理符号链接..."
find "${BUILD_DIR}" -type l -not -path '*/.git/*' -delete 2>/dev/null || true

# ── 9. 下载并校验 fnpack ──
echo ""
echo "[8/8] 下载 fnpack + 构建 fpk..."
if [ ! -x "/usr/local/bin/fnpack" ]; then
    curl -fsSL -o /usr/local/bin/fnpack "https://static2.fnnas.com/fnpack/${FNPACK_BIN}"
    echo "${FNPACK_SHA256}  /usr/local/bin/fnpack" | sha256sum -c -
    chmod +x /usr/local/bin/fnpack
fi

cd "${BUILD_DIR}"
fnpack build -d .

# ── 10. 输出 ──
OUTPUT_FPK="10router-${VERSION}-${ARCH}.fpk"
mv 10router.fpk "${REPO_ROOT}/${OUTPUT_FPK}"

echo ""
echo "=========================================="
echo "  构建完成: ${REPO_ROOT}/${OUTPUT_FPK}"
ls -lh "${REPO_ROOT}/${OUTPUT_FPK}"
echo "=========================================="

# 清理
rm -rf "${BUILD_DIR}"
