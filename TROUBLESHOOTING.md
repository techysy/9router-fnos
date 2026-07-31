# TROUBLESHOOTING / 故障排除

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
