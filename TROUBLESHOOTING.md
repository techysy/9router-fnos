# TROUBLESHOOTING / 故障排除

---

## Cloudflare 卡片显示"无连接"（即使连接已添加且活跃）

**症状**: 提供商列表页的 Cloudflare 卡片显示"无连接"，但详情页连接状态是"活跃"，且 `cf/@cf/...` 模型能正常路由。

**原因**: 上游 `cloudflare-ai` provider 目录定义缺少 `authModes:["apikey"]`，网格页 `dualAuthTypes()` 只按 `oauth` 过滤，把 `apikey` 连接排除在计数外。属上游 bug（[issue #2969](https://github.com/decolua/9router/issues/2969)）。

**修复**:
```bash
bash scripts/patch-cloudflare-authmodes.sh   # 在 NAS 上运行
```

**修复后仍显示"无连接" → 浏览器缓存问题**:

补丁改的 bundle 文件名带 hash（如 `1321-3cb00d56de5fba92.js`），**hash 没变**，Next.js 发 `Cache-Control: immutable`，浏览器一直用缓存的旧 JS。此时**重启服务（停用/启用）或卸载重装都无效**——文件名 hash 不变，浏览器缓存照样命中旧的。唯一有效做法是**清浏览器缓存**:

- **强刷**: 在 9Router 标签页上 `Ctrl+Shift+R`（或 F12 → 右键刷新按钮 → 「清空缓存并硬性重新加载」）
- **清缓存**: `Ctrl+Shift+Delete` → 「缓存的图片和文件」→ 时间范围选「所有时间」→ 清除，再重开
- **最稳验证**: 用**无痕窗口**打开 9Router（无痕默认不读缓存）

**验证服务器已生效**（无需登录）:
```bash
curl -s "http://127.0.0.1:20128/_next/static/chunks/1321-3cb00d56de5fba92.js" \
  | grep -o "cloudflare-ai.*authModes:\[.\{0,10\}" | head -1
# 应输出含 authModes:["apikey"]
```

> ⚠️ 该补丁改的是构建产物（bundle），**升级 9Router 重新打包后会丢失**，需重新运行 `scripts/patch-cloudflare-authmodes.sh`。脚本会自动定位新 chunk，无需手动改路径。

---

## 无法启用 / 本地应用启动失败

**日志**: `/var/log/apps/9router.log` 显示 `cd: .../target/server: No such file or directory`

**原因**: fnOS 1.1.31xx 传 `TRIM_APPDEST=/vol4/@appcenter/9router`（server 直接在根下），而脚本硬编码了 `target/server`。

**修复**: cmd/main 已做双路径检测（先查 `${APP_DIR}/server`，再查 `${APP_DIR}/target/server`）。

**手动验证**:
```bash
# 在 NAS 上检查实际目录结构
ls /vol4/@appcenter/9router/server/custom-server.js
# 应该存在。如果不存在，说明 app/ 打包不完整。
```

## 端口被占用

```bash
# 查看谁占了 20128
ss -tlnp | grep 20128

# 如果是残留进程
pkill -f "custom-server.js"
```

## 数据目录权限问题

```bash
# 检查数据目录
ls -la /vol4/@appdata/9router/

# 如果权限不对
chown -R 9router:9router /vol4/@appdata/9router/
chmod -R 755 /vol4/@appdata/9router/
```

## Dashboard 打不开

1. 检查服务是否运行: `ss -tlnp | grep 20128`
2. 查看日志: `tail -50 /vol4/@appdata/9router/9router.log`
3. 手动启动测试:
```bash
cd /vol4/@appcenter/9router/server
DATA_DIR=/vol4/@appdata/9router PORT=20128 HOSTNAME=0.0.0.0 \
  node --max-old-space-size=4096 custom-server.js
```

## fpk 安装后图标不更新

fnOS 缓存图标数据，简单升级安装不会刷新。需要**卸载 → 重新安装**。

## 重装后进程不自动重启

fnOS 重装 fpk 不会杀旧进程。手动清理:
```bash
kill -9 $(pgrep -f '9router.*custom-server')
```
然后在 App Center 重新启用。

### 忘记 Dashboard 登录密码

9Router 密码存储在 SQLite 数据库中（bcrypt 哈希），无法反解。

**重置步骤：**

```bash
# 1. 在有 bcrypt 的机器上生成新哈希（如 Arch VM）
pip install bcrypt
python3 -c "import bcrypt; print(bcrypt.hashpw(b'你的新密码', bcrypt.gensalt(10)).decode())"
# 输出类似: $2b$10$Fj6UBdxClNY0.3/U84SW3OHQbTTLMul3b...

# 2. 将哈希写入 NAS 数据库
ssh yangyu@192.168.31.101 'python3 -c "
import sqlite3, json
conn = sqlite3.connect(\"/vol4/@appdata/9router/db/data.sqlite\")
cur = conn.cursor()
row = cur.execute(\"SELECT data FROM settings WHERE id = 1\").fetchone()
data = json.loads(row[0])
data[\"password\"] = \"<粘贴上面生成的哈希>\"
cur.execute(\"UPDATE settings SET data = ? WHERE id = 1\", (json.dumps(data),))
conn.commit()
conn.close()
print(\"密码已重置\")
"'

# 3. 重启9Router 服务
kill $(cat /vol4/@appdata/9router/9router.pid) 2>/dev/null
cd /var/apps/9router && bash cmd/main start
```

重置后登录 Dashboard → Settings 修改为你自己的密码。

---

## 货币补丁（¥）不生效

**症状**: Pricing 页面仍显示 `$`，或飞牛移动 App 容器内显示不对。

**原因**: 货币补丁分两层，分别处理：

| 位置 | 内容 | 说明 |
|---|---|---|
| i18n `zh-CN.json` | Pricing 页文字 `美元/百万 Token` → `¥/百万 Token` | 已集成进 `scripts/prepare-server.sh` 自动应用 |
| 前端 JS bundle | Usage 页 `~$0.95` 的符号 | 是 JS 硬编码，需额外 JS 补丁 |

**排查**:
```bash
# 1. 确认 i18n 补丁已应用（应显示 ¥）
grep '百万 Token' /vol4/@appcenter/9router/server/public/i18n/literals/zh-CN.json

# 2. 确认中文 locale（右上角语言切到中文 🇨🇳）
# 3. 强刷浏览器缓存（补丁改 bundle 后缓存可能命中旧的）
```

> ⚠️ 补丁在每次 `prepare-server.sh` 构建时自动应用，但**升级 9Router 重新打包后会覆盖**，需重新构建。

## 飞牛移动 App 容器内无法登录 / UI 不生效

**症状**: 在飞牛移动 App（iOS/Android）打开 9Router，反复跳回登录页，或主题切换不生效。

**原因**: 飞牛移动 App 用 **WebView iframe** 打开所有应用：

- 登录 cookie（`SameSite=lax`）无法在容器内保存 → 反复跳登录页
- `localStorage` / JS 驱动的 UI 状态持久化受限 → 主题切换可能不生效

**解决**: 本应用**默认开启登录**（`requireLogin=true`，源码构建默认），首次登录用初始密码 `123456`。若确需在移动 App 容器内使用且无法登录，可在 **Profile → Settings** 关闭「Require Login」规避（登录页可关闭）。API 调用仍受 API Key 保护。如需完整体验，用电脑浏览器或手机浏览器直接访问 `http://<NAS-IP>:20128`（货币功能已合入源码，非运行时补丁）。
