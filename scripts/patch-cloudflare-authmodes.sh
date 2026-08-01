#!/bin/bash
# ============================================================
# 9Router cloudflare-ai authModes 补丁脚本 / Patch Script
# ------------------------------------------------------------
# 修复: 提供商列表页 Cloudflare 卡片显示"无连接"
# Fixes: Cloudflare card showing "No connections" on the
#        Providers grid even when a connection is active.
#
# 根因 / Root cause:
#   cloudflare-ai provider 目录定义缺 authModes:["apikey"]，
#   导致网格页 dualAuthTypes() 只按 "oauth" 过滤，apikey 连接被排除。
#   The cloudflare-ai provider registry entry is missing
#   authModes:["apikey"], so the grid's dualAuthTypes() filters
#   by "oauth" only and drops the apikey connection.
#
# 用法 / Usage (run ON the NAS):
#   bash patch-cloudflare-authmodes.sh
#   然后浏览器硬刷新 9Router 页面 (Ctrl+Shift+R)
#   Then hard-refresh the 9Router page (Ctrl+Shift+R)
#
# 上游 issue / Upstream issue:
#   https://github.com/decolua/9router/issues/2969
# ============================================================
set -uo pipefail

APP_ROOT="/vol4/@appcenter/9router/server/.next-cli-build"
ANCHOR='hasProviderSpecificData:!0,transport:{baseUrl:"https://api.cloudflare.com/client/v4/accounts/{accountId}/ai/v1/chat/completions"'
REPL='hasProviderSpecificData:!0,authModes:["apikey"],transport:{baseUrl:"https://api.cloudflare.com/client/v4/accounts/{accountId}/ai/v1/chat/completions"'

echo "🔍 定位包含 cloudflare-ai 定义的客户端 bundle..."
CLIENT_CHUNK=$(grep -rl 'id:"cloudflare-ai"' "${APP_ROOT}/static/chunks/" 2>/dev/null | head -1)
if [ -z "$CLIENT_CHUNK" ]; then
  echo "❌ 未找到 cloudflare-ai 客户端 chunk，请检查 9Router 版本"
  exit 1
fi
echo "✅ 客户端 chunk: $(basename "$CLIENT_CHUNK")"

SERVER_CHUNK=$(grep -rl 'id:"cloudflare-ai"' "${APP_ROOT}/server/chunks/" 2>/dev/null | head -1)
[ -n "$SERVER_CHUNK" ] && echo "✅ 服务器 chunk: $(basename "$SERVER_CHUNK")" || echo "⚠️ 未找到服务器 chunk（可选）"

patch_file() {
  local p="$1"
  [ -f "$p" ] || { echo "⏭️  跳过(不存在): $p"; return; }
  local n=$(grep -o -F "$ANCHOR" "$p" | wc -l)
  if [ "$n" -eq 1 ]; then
    local bak="${p}.bak.$(date +%s)"
    cp "$p" "$bak"
    # 用 python 做精确替换（避免 sed 特殊字符问题）
    python3 - "$p" "$bak" <<'PYEOF'
import sys
p, bak = sys.argv[1], sys.argv[2]
c = open(p, encoding="utf-8").read()
anchor = 'hasProviderSpecificData:!0,transport:{baseUrl:"https://api.cloudflare.com/client/v4/accounts/{accountId}/ai/v1/chat/completions"'
repl = 'hasProviderSpecificData:!0,authModes:["apikey"],transport:{baseUrl:"https://api.cloudflare.com/client/v4/accounts/{accountId}/ai/v1/chat/completions"'
open(p, "w", encoding="utf-8").write(c.replace(anchor, repl, 1))
PYEOF
    echo "🛠️  已打补丁: $p"
    echo "  备份: $bak"
  else
    echo "⏭️  anchor 出现 $n 次(期望1)，跳过(可能已打过): $p"
  fi
}

patch_file "$CLIENT_CHUNK"
[ -n "$SERVER_CHUNK" ] && patch_file "$SERVER_CHUNK"

echo ""
echo "🎉 完成。请在浏览器硬刷新 9Router 页面 (Ctrl+Shift+R)。"
echo "完成验证:"
echo "  ssh yangyu@192.168.31.101 'curl -s \"http://127.0.0.1:20128/_next/static/chunks/$(basename "$CLIENT_CHUNK")\" | grep -o \"cloudflare-ai.*authModes:\\[\" | head -1'"
echo "  应输出含 authModes:[\"apikey\"]"
