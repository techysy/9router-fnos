# 9Router / HermesAgent / fn-netdiag 整体发布说明

> 2026-08-20
> 针对朋友机器白屏问题 + 各项功能改进的完整发布汇总

---

## 一、本次发布总览

| 应用 | Release | 包 | 核心修复 |
|------|---------|-----|---------|
| 9Router | v0.5.55 | 4 个 fpk | SQLite WAL/SHM 启动清理、install_callback 多路径检测、wizard/install MIT 协议 |
| HermesAgent | v1.2.4 | 2 个 fpk | proxy.py 配置目录多级兜底（解决手动/dsh 拉起读错配置） |
| fn-netdiag | v1.1.0 | 2 个 fpk | 局域网连通性探测、移动容器动态判断、版本号动态化 |

---

## 二、本次要解决的问题

### 问题 1：9Router 首次安装后 Internal Server Error / 数据库打不开
- **根因**：SQLite WAL/SHM 文件属主错误，node:sqlite 无法打开数据库
- **修复**：cmd/main 启动前清理 WAL/SHM 残留
- **附带修复**：install_callback 多路径检测（x86 离线版不误触发在线构建）、wizard/install MIT 协议

### 问题 2：HermesAgent 白屏（proxy 读错配置）
- **根因**：proxy.py 依赖 `HERMES_CONF_DIR` env 找配置，env 没设对就读错/读不到，静默 fallback 127.0.0.1
- **修复**：多级兜底定位配置目录（env → fnOS 数据目录 → 工作目录），不依赖单一 env；读失败打日志；启动日志显示实际配置路径

### 问题 3：fn-netdiag 白屏 + 功能增强
- **根因**：install_callback 没主动拉起服务（appcenter 不自启）；版本号硬编码；移动容器固定域名不可靠
- **修复**：install_callback 主动拉起 server.py；版本号动态化；移动容器 UA + FN Connect 动态判断
- **增强**：连通性探测加局域网（局域网 IP 服务 + 网关）

---

## 三、给朋友的重装指引

> 朋友机器上白屏，需重装最新版 + 正确配置。

### 第 1 步：下载最新 fpk
从 GitHub Release 下载（或从交付目录拷贝）：

| 应用 | 文件 |
|------|------|
| 9Router | `9router-0.5.55-x86.fpk`（或 `-all.fpk`） |
| HermesAgent | `HermesAgent-1.2.4-all.fpk` |
| fn-netdiag | `fn-netdiag-1.1.0-all.fpk` |

### 第 2 步：fnOS App Center 手动安装
飞牛 Web UI → **App Center → 手动安装** → 选择 fpk。

### 第 3 步：装后配置

**HermesAgent**（需指向实际 Hermes dashboard）：
- 装时安装向导填**目标 IP + 端口**（Hermes 所在机器的局域网 IP + 9119）
- 若已装好：编辑 `/vol1/@appdata/HermesAgent/dashboard.conf`，写入：
  ```
  TARGET_IP=<Hermes 机器 IP>
  TARGET_PORT=9119
  ```
- 然后重启 HermesAgent 应用

**fn-netdiag / 9Router**：装完即用，无需额外配置。

### 第 4 步：验证
- 应用中心打开各应用，应显示正常页面（非白屏）
- fn-netdiag：首页显示 v1.1.0，连通性含局域网/网关项

---

## 四、注意事项

1. **9Router 初始密码**：默认 `123456`，首次登录后建议修改。
2. **9Router all 在线版**：装时需联网 npm install + next build（10~30 分钟），建议先用 x86 离线版。
3. **重装不丢数据**：fnOS 升级保留 `/vol4/@appdata/<App>` 数据（数据库、配置），不会清空。

---

## 五、排障记录（完整版）

各应用详细排障文档：
- 9Router: `docs/v0.5.55-troubleshooting.md`
- HermesAgent: `docs/whitescreen-hardening-v1.2.4.md`
- fn-netdiag: `docs/v1.1.0-changes-and-troubleshooting.md`

**通用坑（重要）**：
- `install-fpk` 可能不替换 app.tgz 里的 server.py → 装完用 `grep` 对比文件特征确认
- 改代码后必须 kill 旧进程重启才生效
- `pkill -f "xxx.py"` 会误杀含该字样的 SSH 会话 → 用具体 PID
