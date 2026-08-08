# 🚀 9Router v0.5.51 for fnOS 发布

> 9Router 是一个 **本地 AI 路由网关 + 飞牛 NAS 桌面应用**。把 Claude Code、Codex、Cursor、Cline 等工具指向一个端点，就能接入 **40+ 免费 AI 提供商**，自动 fallback 不中断编码，RTK 节省 20-40% token。

## ✨ 本次 v0.5.51 更新亮点

### 💱 1. 成本按界面语言显示本地货币（多币种）

成本/定价不再只有 `$`，会跟随界面语言自动显示本地货币：

| 语言 | 货币 |
|---|---|
| 简体中文 | ¥ CNY |
| 繁體中文 | NT$ TWD |
| 日本語 | ¥ JPY |
| 한국어 | ₩ KRW |
| Tiếng Việt | ₫ VND |

> 在 **Profile → Language** 卡片下有「Regional currency」开关，可随时切换；关闭则统一回退 `$`。
> 上游 PR：[#3118](https://github.com/decolua/9router/pull/3118)

### 🔀 2. 配额包按连接独立显示/隐藏

同一提供商（如 CodeBuddy CN）配置**多个连接**时，每个连接的配额包（如 Bonus Pack）**独立显示、独立隐藏**——隐藏连接 1 的 Bonus Pack 1 不会再连带隐藏连接 2 的。

> 修复前：隐藏一个连接的配额包会连带隐藏其它连接；修复后按连接 id 隔离。
> 上游 PR：[#3122](https://github.com/decolua/9router/pull/3122)

### 🗺️ 3. 免费供应商可开关（拓扑图）

noAuth 免费供应商（opencode、MiMo Code Free）现在可以在 **Provider 页** 通过开关控制是否显示在「使用情况画布」（拓扑图）。MiMo 免费通道已终止，默认不再显示，但可手动开启。

> 上游 PR：[#3123](https://github.com/decolua/9router/pull/3123)

## 📸 效果图

![多币种成本-简体中文](https://github.com/user-attachments/assets/4b284e6a-df86-44f0-bf58-01cc833d5c19)

![配额包按连接独立](https://github.com/user-attachments/assets/a82d2d2f-7566-43c2-b206-32cecc7b40e4)

![免费供应商拓扑开关](https://github.com/user-attachments/assets/43f4372e-2844-4b84-aab8-1c3fb9b18c92)

> 更多效果图见 [docs/SCREENSHOTS.md](https://github.com/techysy/9router-fnos/blob/main/docs/SCREENSHOTS.md)

## 🚀 快速安装

1. 下载 fpk 安装包（普通版 / iframe 版任选）：
   - **普通版**（桌面独立窗口）：[9router-0.5.51.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.51/9router-0.5.51.fpk)
   - **iframe 版**（桌面内嵌）：[9router-0.5.51-iframe.fpk](https://github.com/techysy/9router-fnos/releases/download/v0.5.51/9router-0.5.51-iframe.fpk)
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
| 数据目录 | `/vol4/@appdata/9router/` |
| Node 运行时 | fnOS App Center `nodejs_v24` |

> 💡 完整体验请用**电脑浏览器**或**手机浏览器**直接访问 `http://<NAS-IP>:20128`。

## 🔗 相关链接

- **项目仓库**：[techysy/9router-fnos](https://github.com/techysy/9router-fnos)
- **Release 下载**：[v0.5.51](https://github.com/techysy/9router-fnos/releases/tag/v0.5.51)
- **上游项目**：[decolua/9router](https://github.com/decolua/9router)
- **效果图图库**：[docs/SCREENSHOTS.md](https://github.com/techysy/9router-fnos/blob/main/docs/SCREENSHOTS.md)

> ⚠️ 小提示：安装后若打开 Dashboard 未见新功能，请浏览器**硬刷新（Ctrl+Shift+R）**清除旧 JS 缓存。
