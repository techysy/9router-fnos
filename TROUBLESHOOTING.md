# TROUBLESHOOTING / 故障排除

> 下文示例中的 `/vol4` 是常见卷号，**请按实际环境替换**：数据目录为 `TRIM_PKGVAR`（或 `<卷>/@appdata/9router`），
> 应用安装目录为 `TRIM_APPDEST`（或 `/var/apps/9router`）。不确定时看 `env | grep TRIM`。

---

## Cloudflare 卡片显示"无连接"（即使连接已添加且活跃）

**症状**: 提供商列表页的 Cloudflare 卡片显示"无连接"，但详情页连接状态是"活跃"，且 `cf/@cf/...` 模型能正常路由。

**原因**: 上游 `cloudflare-ai` provider 目录定义缺少 `authModes:["apikey"]`，网格页 `dualAuthTypes()` 只按 `oauth` 过滤，把 `apikey` 连接排除在计数外。属上游 bug（[issue #2969](https://github.com/decolua/9router/issues/2969)）。

**状态**: 该修复已随**上游源码 v0.5.50+** 合入，本包为源码构建，**无需额外补丁**。

**仍显示"无连接" → 浏览器缓存问题**:

旧版 bundle 文件名带 hash（如 `1321-3cb00d56de5fba92.js`），**hash 没变**，Next.js 发 `Cache-Control: immutable`，浏览器一直用缓存的旧 JS。此时**重启服务（停用/启用）或卸载重装都无效**——文件名 hash 不变，浏览器缓存照样命中旧的。唯一有效做法是**清浏览器缓存**:

- **强刷**: 在 9Router 标签页上 `Ctrl+Shift+R`（或 F12 → 右键刷新按钮 → 「清空缓存并硬性重新加载」）
- **清缓存**: `Ctrl+Shift+Delete` → 「缓存的图片和文件」→ 时间范围选「所有时间」→ 清除，再重开
- **最稳验证**: 用**无痕窗口**打开 9Router（无痕默认不读缓存）

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
# 1. 在有 bcrypt 的机器上生成新哈希
pip install bcrypt
python3 -c "import bcrypt; print(bcrypt.hashpw(b'你的新密码', bcrypt.gensalt(10)).decode())"
# 输出类似: $2b$10$Fj6UBdxClNY0.3/U84SW3OHQbTTLMul3b...

# 2. 将哈希写入 NAS 数据库（DATA_DIR 见文档开头说明，按实际卷号替换）
DATA_DIR=<你的数据目录，如 /volX/@appdata/9router>
python3 -c "
import sqlite3, json, sys
conn = sqlite3.connect(sys.argv[1] + '/db/data.sqlite')
cur = conn.cursor()
row = cur.execute('SELECT data FROM settings WHERE id = 1').fetchone()
data = json.loads(row[0])
data['password'] = '<粘贴上面生成的哈希>'
cur.execute('UPDATE settings SET data = ? WHERE id = 1', (json.dumps(data),))
conn.commit()
conn.close()
print('密码已重置')
" "${DATA_DIR}"

# 3. 重启 9Router 服务（APP_DIR = 应用安装目录，见文档开头说明）
APP_DIR=<你的应用目录，如 /volX/@appcenter/9router>
bash "${APP_DIR}/cmd/main" stop
bash "${APP_DIR}/cmd/main" start
```

> 也可以直接在飞牛 **App Center** 里停用再启用该应用，效果相同。

重置后登录 Dashboard → Settings 修改为你自己的密码。

---

## 飞牛移动 App 容器内无法登录 / UI 不生效

**症状**: 在飞牛移动 App（iOS/Android）打开 9Router，反复跳回登录页，或主题切换不生效。

**原因**: 飞牛移动 App 用 **WebView iframe** 打开所有应用：

- 登录 cookie（`SameSite=lax`）无法在容器内保存 → 反复跳登录页
- `localStorage` / JS 驱动的 UI 状态持久化受限 → 主题切换可能不生效

**解决**: 本应用**默认开启登录**（`requireLogin=true`，源码构建默认），首次登录用初始密码 `123456`。若确需在移动 App 容器内使用且无法登录，可在 **Profile → Settings** 关闭「Require Login」规避（登录页可关闭）。API 调用仍受 API Key 保护。如需完整体验，用电脑浏览器或手机浏览器直接访问 `http://<NAS-IP>:20128`（货币功能已合入源码，非运行时补丁）。

---

## 上机验证清单（胶水脚本改动后）

`cmd/` 下的脚本只能在实际 fnOS 上验证。改动过 `cmd/lib.sh`、`cmd/main`、`cmd/*_callback` 后，按下面逐项确认。

**准备**：先设好两个变量，后续命令都用它，避免写死卷号：

```bash
APP_DIR=<应用安装目录，如 /volX/@appcenter/9router>
DATA_DIR=<数据目录，如 /volX/@appdata/9router>   # 即 TRIM_PKGVAR
```

### 1. 端口与健康

```bash
netstat -tlnp 2>/dev/null | grep 20128          # 应处于 LISTEN
curl -sf http://127.0.0.1:20128/api/health && echo 健康
```

### 2. 数据目录与 .env（本次改动重点）

```bash
ls -la "${DATA_DIR}"                            # 应有 .env / 9router.log / 9router.pid / db/
cat "${DATA_DIR}/.env"                          # INITIAL_PASSWORD=123456，JWT_SECRET 应为随机 64 位十六进制
ls -l "${DATA_DIR}/.env"                        # 权限应为 600
```

- [ ] `.env` 出现在**数据目录**（不是 `${APP_DIR}/server/.env`）
- [ ] `JWT_SECRET` 是随机的，不是占位字符串
- [ ] 重启服务后 `JWT_SECRET` **不变**（若变了说明每次都重生成，登录态会被踢）

### 3. PID 与启停

```bash
bash "${APP_DIR}/cmd/main" status               # running
bash "${APP_DIR}/cmd/main" stop                 # 应优雅停止；再 status 应为 stopped
ps aux | grep -c "[c]ustom-server.js"           # stop 后应为 0
bash "${APP_DIR}/cmd/main" start                # 应能重新拉起并返回 started
```

- [ ] `stop` 后进程确实消失（不再残留）
- [ ] `restart` 后端口能重新绑定（无 "address already in use"）
- [ ] 手动写一个**不存在的 PID** 到 `9router.pid`，`start` 应能识别为陈旧并正常拉起（而非误报 already running）

### 4. 登录（验证 .env 生效链路）

浏览器打开 `http://<NAS-IP>:20128`，用 `123456` 登录 → 在 Settings 改成自定义密码 → **重启服务** → 用新密码仍能登录。

- [ ] 初始密码 `123456` 可登录
- [ ] 在 `.env` 里把 `INITIAL_PASSWORD` 改成别的值后重启，新值生效（证明 `.env` 被 source）
- [ ] 改密码后重启，新密码可登录

### 5. 在线构建路径（仅 all 变体，x86 变体可跳过）

装 all 版 fpk，观察 `${DATA_DIR}/install.log`：

- [ ] 日志出现 `npm install exit=0` / `next build exit=0`（**失败时应是 `exit=<非0>`**——旧版这里恒为 0，是本轮修的 bug）
- [ ] 若构建失败（可故意断网测），App Center **应报安装失败**，而不是显示成功
- [ ] `timeout` 生效：构建卡住时会在 30/60 分钟后失败退出，而非永久挂起

### 6. 卷号推导（不写死卷号）

在**非 `/vol4`** 的卷上装（或临时改 `TRIM_PKGVAR`/`TRIM_APPDEST` 模拟）：

- [ ] 数据目录落在正确的卷上
- [ ] `cmd/main` 能找到 `nodejs_v24`（`env | grep TRIM` 看注入值）

### 回退

若 `.env` 移到数据目录后上游读不到，把 `cmd/main` 的 `ENV_FILE` 改回 `"${SRC_DIR}/.env"` 即可（其余逻辑不变）；`install_callback` / `upgrade_callback` 的 `.env` 修正逻辑走 `9router_fix_initial_password`，会同时处理两处。
