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
