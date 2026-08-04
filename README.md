# 9Router for fnOS

[![GitHub release](https://img.shields.io/github/v/release/techysy/9router-fnos?label=Latest&color=blue)](https://github.com/techysy/9router-fnos/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/techysy/9router-fnos/blob/main/LICENSE)
[![fnOS 1.1.31xx](https://img.shields.io/badge/fnOS-1.1.31xx+-orange.svg)](https://developer.fnnas.com/docs/guide)
[![9Router v0.5.45](https://img.shields.io/badge/9Router-v0.5.45-cyan.svg)](https://github.com/decolua/9router)

> 9Router 免费 AI 路由器的飞牛 NAS (fnOS) 应用包。连接 Claude Code / Codex / Cursor 等工具到 40+ 免费 AI 提供商，RTK 节省 20-40% token，自动 fallback 不中断。

**9Router for fnOS** 将 [decolua/9router](https://github.com/decolua/9router) 打包为 fnOS 桌面应用，开箱即用。

- [English README](./README.en.md)

---

## ✨ 功能亮点

- **一个端点连所有 AI**：Claude Code、Codex、Cursor、Cline 等工具指向 `http://<NAS-IP>:20128/v1` 即接入 40+ 免费提供商
- **自动 fallback**：某个提供商限流/故障时自动切换，不中断编码
- **RTK Token 节省**：减少 20-40% token 消耗
- **中文定价显示**：内置货币补丁，Pricing 页面以 ¥ 显示（见下方"本项目增强"）

## 🚀 快速安装

1. 从 [Releases](https://github.com/techysy/9router-fnos/releases) 下载 `9router-x.x.x.fpk`
2. 飞牛 **App Center → 手动安装** → 选择 fpk
3. 桌面出现 **9Router** 图标，点击打开 Dashboard

## 📖 使用说明

### 接入 AI 工具

```bash
# CLI 工具（Claude Code / Codex / Cursor / Cline 等）指向 9Router 端点
# Base URL: http://<NAS-IP>:20128/v1
# API Key: 在 9Router Dashboard → Endpoint & Key 获取
```

Dashboard 里配置 AI 提供商（如 Kiro AI 免费模型）后即可使用。

### 端口与数据

| 项 | 值 |
|---|---|
| 端口 | `20128` |
| 数据目录 | `/vol4/@appdata/9router/` |
| Node 运行时 | fnOS App Center `nodejs_v24` |

### 登录说明

本应用**默认关闭登录**（`requireLogin=false`），适配飞牛移动 App 容器。API 调用仍受 API Key 保护。

### ⚠️ 飞牛移动 App 限制

飞牛移动 App（iOS/Android）用 **WebView iframe** 打开所有应用，存在限制：

- **无法登录**：登录 cookie（`SameSite=lax`）无法在容器内保存，会反复跳回登录页（本应用已关闭登录规避）
- **UI 持久化有限**：`localStorage` / 主题切换 / 货币补丁（¥）在容器内可能不生效

> 💡 完整体验请用**电脑浏览器**或**手机浏览器**直接访问 `http://<NAS-IP>:20128`。

## 🔧 本项目增强

相比上游 [decolua/9router](https://github.com/decolua/9router)，本包额外提供：

| 增强 | 说明 |
|---|---|
| **货币 ¥ 补丁** | Pricing 定价页面从 `$` 改为 `¥` 显示 |
| **Cloudflare 修复** | 修复 Cloudflare 卡片误显示"无连接" |

这些补丁在每次构建时自动应用（`scripts/prepare-server.sh` 集成）。

## 🛠️ 从源码构建

> 面向开发者。普通用户直接用 Release 即可。

```bash
git clone https://github.com/techysy/9router-fnos.git
cd 9router-fnos

# 提取 9Router standalone + 自动应用增强补丁
# 需在 PATH 中加入 fnOS 的 node：export PATH=/vol4/@appcenter/nodejs_v24/bin:$PATH
bash scripts/prepare-server.sh 0.5.45

# 构建 fpk（需在飞牛 NAS 上执行）
fnpack build
```

## 🐛 问题排查

构建/安装/运行的常见问题与修复，见 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)。

## 🔮 迭代计划

等待上游 [decolua/9router](https://github.com/decolua/9router) 发布新版本后重新打包：

- 跟进上游版本更新
- 上游新增模型自动同步到 Dashboard
- RTK token 节省算法优化

## 📚 相关项目

- [decolua/9router](https://github.com/decolua/9router) — 上游开源项目
- [Hermes WebUI](https://github.com/techysy/hermes-webui-fnos) · [MetaCubeXD](https://github.com/techysy/metacubexd-fnos) · [Strava Panel](https://github.com/techysy/strava-panel-fnos) — 更多 fnOS 应用
- [fnOS 开发者文档](https://developer.fnnas.com/docs/guide)

## License

MIT — 与 [decolua/9router](https://github.com/decolua/9router) 一致
