# 🚀 9Router v0.5.53 for fnOS 发布

> 9Router 是一个 **本地 AI 路由网关 + 飞牛 NAS 桌面应用**。把 Claude Code、Codex、Cursor、Cline 等工具指向一个端点，就能接入 **40+ 免费 AI 提供商**，自动 fallback 不中断编码，RTK 节省 20-40% token。

## ✨ 本次 v0.5.53 更新亮点

### 🎯 1. 无连接时不再暴露全部内置模型（重要修复）

此前，当**数据库正常但还没配置任何 provider 连接**时，`/v1/models` 会把内置的 **~680 个模型**全部返回给客户端（OpenCode / Cursor / Cline 等），导致模型列表臃肿、大量模型实际不可用。

**本次修复**：区分「数据库不可用」（仍兜底返回全部静态模型）与「数据库正常但无连接」（只返回你**显式添加**的自定义模型，如 `oc/*-free`）。

| 场景 | 修复前 | 修复后 |
|------|--------|--------|
| 数据库健康 + 无连接 | `/v1/models` 返回 ~680 个内置模型 | 只返回你添加的自定义模型（如 `oc/mimo-v2.5-free`） |
| 数据库不可用 | 返回全部静态模型（兜底） | 返回全部静态模型（兜底，不变） |
| 已配置连接 | 按连接返回模型 | 按连接返回模型（不变） |

> 实测（fnOS NAS）：修复前 `/v1/models` 返回 681 个模型，修复后仅返回 `oc/deepseek-v4-flash-free`、`oc/mimo-v2.5-free` 两个自定义模型。
> 上游 PR：[#3267](https://github.com/decolua/9router/pull/3267)

## 📦 下载安装

1. 下载 fpk 安装包（普通版 / iframe 版任选）：
   - **普通版**（桌面独立窗口）：[9router-0.5.53.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.53/9router-0.5.53.fpk)
   - **iframe 版**（桌面内嵌）：[9router-0.5.53-iframe.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.53/9router-0.5.53-iframe.fpk)
2. 飞牛 **App Center → 手动安装** → 选择 fpk
3. 桌面出现 **9Router** 图标，点击打开 Dashboard

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
| 数据目录 | `/vol1/@appdata/9router/` |
| Node 运行时 | fnOS App Center `nodejs_v24` |

> 💡 完整体验请用**电脑浏览器**或**手机浏览器**直接访问 `http://<NAS-IP>:20128`。

## 🔗 相关链接

- **项目仓库**：[techysy/9router-fnos](https://github.com/techysy/9router-fnos)
- **Release 下载**：[v0.5.53](https://github.com/techysy/9router-fnos/releases/tag/v0.5.53)
- **上游项目**：[decolua/9router](https://github.com/decolua/9router)
- **效果图图库**：[docs/SCREENSHOTS.md](https://github.com/techysy/9router-fnos/blob/main/docs/SCREENSHOTS.md)

> ⚠️ 小提示：安装后若打开 Dashboard 未见新功能，请浏览器**硬刷新（Ctrl+Shift+R）**清除旧 JS 缓存。
