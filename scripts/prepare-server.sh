#!/bin/bash
# 从 npm 包提取9Router standalone server 到 app/server/
# 用法: bash scripts/prepare-server.sh [版本号]
set -euo pipefail

VERSION="${1:-0.5.45}"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "📦 下载9router@${VERSION}..."
cd "$TMPDIR"
npm pack "9router@${VERSION}" 2>/dev/null

echo "📂 解压..."
tar xzf "9router-${VERSION}.tgz"

echo "📋 复制到 app/server/..."
rm -rf "../../app/server"
mkdir -p "../../app/server"

# 复制文件（包含隐藏目录如 .next-cli-build）
cp -r package/app/. ../../app/server/

# 补全 Dockerfile 里额外 COPY 的依赖（standalone tracing 可能遗漏）
for dep in node-forge; do
    if [ ! -d "../../app/server/node_modules/$dep" ]; then
        echo "⚠️  补装缺失依赖: $dep"
        cd "$TMPDIR"
        npm pack "${dep}@latest" 2>/dev/null
        mkdir -p "../../app/server/node_modules/$dep"
        tar xzf "${dep}-"*.tgz -C "../../app/server/node_modules/$dep" --strip-components=1
        cd "$TMPDIR"
    fi
done

echo "✅ app/server/ 准备完成 ($(du -sh ../../app/server | cut -f1))"
