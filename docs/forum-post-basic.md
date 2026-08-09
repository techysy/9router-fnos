# 🚀 9Router for fnOS — 免费 AI 路由器，一个端点接入 40+ AI 提供商

> 9Router 是运行在飞牛 NAS 上的 **本地 AI 路由网关**，把 Claude Code、Codex、Cursor、Cline 等工具指向一个端点，就能接入 **40+ 免费 AI 提供商**，自动切换、不中断编码，RTK 节省 20-40% token。

## 🤔 为什么用 9Router？

| 痛点 | 9Router 的解法 |
|---|---|
| 各家 AI 工具各自要配不同 API | 一个端点 http://<NAS-IP>:20128/v1 全部接入 |
| 免费提供商经常限流或挂掉 | 自动 fallback，切换不中断 |
| Token 消耗大 | RTK 节省 20-40% token |
| 要管一堆 Key 和额度 | 统一管理提供商连接、配额、用量 |

## ✨ 功能亮点

- **一个端点连所有 AI**：Claude Code、Codex、Cursor、Cline 等接入 40+ 免费提供商
- **自动 fallback**：某提供商限流或故障自动切换，编码不中断
- **RTK Token 节省**：减少 20-40% token 消耗
- **多币种成本显示**：成本按界面语言显示 ¥、NT$、¥、₩、₫
- **配额与用量可视**：Dashboard 直观查看各提供商额度与请求日志

## 🚀 快速安装

1. 下载 fpk 安装包：
   - **普通版**（桌面独立窗口）：[9router-0.5.52.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.52/9router-0.5.52.fpk)
   - **iframe 版**（桌面内嵌）：[9router-0.5.52-iframe.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.52/9router-0.5.52-iframe.fpk)
2. 飞牛 **App Center → 手动安装** → 选择 fpk
3. 桌面出现 **9Router** 图标，点击打开 Dashboard

## 📖 使用说明

```bash
# CLI 工具（Claude Code / Codex / Cursor / Cline）指向 9Router 端点
# Base URL: http://<NAS-IP>:20128/v1
# API Key: 在 9Router Dashboard → Endpoint & Key 获取
```

在 Dashboard 配置 AI 提供商（如 Kiro AI 免费模型）后即可使用。

| 项 | 值 |
|---|---|
| 端口 | 20128 |
| 数据目录 | /vol4/@appdata/9router/ |
| Node 运行时 | fnOS App Center nodejs_v24 |

> 💡 完整体验请用电脑浏览器或手机浏览器直接访问 http://<NAS-IP>:20128。

## 🔗 相关链接

- **项目仓库**：[techysy/9router-fnos](https://github.com/techysy/9router-fnos)
- **Release 下载**：[v0.5.52](https://github.com/techysy/9router-fnos/releases/tag/v0.5.52)
- **上游项目**：[decolua/9router](https://github.com/decolua/9router)

> ⚠️ 小提示：安装后若打开 Dashboard 未显示完整功能，请浏览器硬刷新（Ctrl+Shift+R）清除旧 JS 缓存。
