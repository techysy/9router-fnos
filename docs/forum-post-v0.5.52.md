# 🚀 9Router v0.5.52 for fnOS 发布

> 9Router 是一个 **本地 AI 路由网关 + 飞牛 NAS 桌面应用**。把 Claude Code、Codex、Cursor、Cline 等工具指向一个端点，就能接入 **40+ 免费 AI 提供商**，自动 fallback 不中断编码，RTK 节省 20-40% token。

## ✨ 本次 v0.5.52 更新亮点

### 🔑 1. 修复默认密码不一致

部署 `.env` 中 `INITIAL_PASSWORD` 原为示例值 `change-me`，与前端登录页显示的默认密码 `123456` 不一致。现已统一为 `123456`，**首次登录无需修改配置**即可使用默认密码。

### 📦 2. 自动安装 Node.js 运行时

manifest 增加 `install_dep_apps=nodejs_v24`，fnOS **安装应用时自动安装 Node.js 运行时**，避免其他用户因未装 Node.js 而启动失败；`cmd/main` 改用规范运行时路径（`/var/apps/nodejs_v24/target/bin`）并增强路径探测，未找到时给出明确报错。

## 🚀 快速安装

1. 下载 fpk 安装包（普通版 / iframe 版任选）：
   - **普通版**（桌面独立窗口）：[9router-0.5.52.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.52/9router-0.5.52.fpk)
   - **iframe 版**（桌面内嵌）：[9router-0.5.52-iframe.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.52/9router-0.5.52-iframe.fpk)
2. 飞牛 **App Center → 手动安装** → 选择 fpk
3. 桌面出现 **9Router** 图标，点击打开 Dashboard

> 💡 若已安装旧版，用 **App Center → 手动安装** 选择新版 fpk 覆盖升级即可。升级后默认登录密码为 `123456`。安装时若系统缺 `nodejs_v24` 会自动安装。

## 🌐 浏览器直接访问（补充说明）

**iframe 版** 除了在桌面内嵌打开，也可以直接用**浏览器访问**：

| 访问方式 | 地址 |
|---|---|
| 内网（局域网） | `http://<NAS-IP>:20128` |
| 外网（远程） | `http://9route.<fnid>.fnos.net/` |

> 💡 完整体验推荐用电脑/手机浏览器直接访问上述地址，效果与桌面窗口一致。

## 📖 使用说明

```bash
# CLI 工具（Claude Code / Codex / Cursor / Cline）指向 9Router 端点
# Base URL: http://<NAS-IP>:20128/v1
# API Key: 在 9Router Dashboard → Endpoint & Key 获取
```

Dashboard 里配置 AI 提供商（如 Kiro AI 免费模型）后即可使用。

| 项 | 值 |
|---|---|
| 端口 | `20128` |
| 数据目录 | `/vol4/@appdata/9router/` |
| Node 运行时 | fnOS App Center `nodejs_v24`（安装时自动安装） |

## 🔗 相关链接

- **项目仓库**：[techysy/9router-fnos](https://github.com/techysy/9router-fnos)
- **Release 下载**：[v0.5.52](https://github.com/techysy/9router-fnos/releases/tag/v0.5.52)
- **上游项目**：[decolua/9router](https://github.com/decolua/9router)

> ⚠️ 小提示：安装后若打开 Dashboard 未见新功能，请浏览器**硬刷新（Ctrl+Shift+R）**清除旧 JS 缓存。
