# 9Router fnOS App

[![GitHub release](https://img.shields.io/github/v/release/techysy/9router-fnos?label=Latest&color=blue)](https://github.com/techysy/9router-fnos/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/techysy/9router-fnos/blob/main/LICENSE)
[![fnOS 1.1.31xx](https://img.shields.io/badge/fnOS-1.1.31xx+-orange.svg)](https://developer.fnnas.com/docs/guide)
[![9Router v0.5.45](https://img.shields.io/badge/9Router-v0.5.45-cyan.svg)](https://github.com/decolua/9router)

> 9Router — 免费 AI 路由器，连接 Claude Code / Codex / Cursor 等工具到 40+ 免费 AI 提供商。RTK 节省 20-40% token，自动 fallback 不中断。
>
> FREE AI Router & Token Saver. Connect Claude Code / Codex / Cursor to 40+ free AI providers. Save 20-40% tokens with RTK, auto-fallback never stops coding.

将 [decolua/9router](https://github.com/decolua/9router) 打包为飞牛 NAS (fnOS) 桌面窗口应用，通过 iframe 在桌面直接打开 Dashboard。

Packages [decolua/9router](https://github.com/decolua/9router) as a fnOS desktop window app — Dashboard opens in an iframe on the fnOS desktop.

---

## 快速开始 / Quick Start

### 方式一：使用 Release（推荐） / Option 1: Release (Recommended)

1. 从 [Releases](https://github.com/techysy/9router-fnos/releases) 下载 `9router-x.x.x.fpk`
2. 飞牛 App Center → **手动安装** → 选择 fpk 文件
3. 桌面出现 **9Router** 图标，点击打开 Dashboard（端口 20128）
4. Dashboard 里配置 AI 提供商（如 Kiro AI 免费模型）
5. CLI 工具指向 `http://<NAS-IP>:20128/v1`

### 方式二：本地构建 / Option 2: Build from Source

```bash
git clone https://github.com/techysy/9router-fnos.git
cd 9router-fnos
bash scripts/prepare-server.sh 0.5.45   # 提取9Router standalone / extract9Router standalone
fnpack build                              # 构建 fpk（NAS 上执行）
```

## 端口与数据 / Port & Data

- **端口**：20128（manifest `service_port`）
- **数据目录**：`/vol4/@appdata/9router/`（fnOS 自动创建）
- **Node 运行时**：fnOS App Center `nodejs_v24`

## 已知限制 / Known Limitations

- **MITM 高级功能**需要 root（DNS 重写、根证书安装），fnOS 以 `package` 用户运行，这部分受限
- MITM features need root — fnOS apps run as `package` user; core features (routing, RTK, quota tracking) unaffected
- **📱 飞牛移动 App 容器限制 / fnOS mobile App container limitations**：
  - 飞牛移动 App（iOS/Android 客户端）用 **WebView iframe** 打开所有应用（无论 url/iframe 版），9Router 的登录 cookie（`SameSite=lax`）在该容器无法保存 → **容器内无法登录**（反复跳回登录页）。电脑端/手机浏览器直接访问 `http://<NAS>:20128` 则正常。
  - 本应用已**关闭登录（`requireLogin=false`）**以适配移动容器（内网自用，API 调用仍受 `requireApiKey` 保护）。如需恢复，将 9Router 数据库 `settings` 的 `requireLogin` 改回 `true`。
  - 移动 App 容器对 `localStorage` / JS 驱动的 UI 状态持久化有限，**主题切换、货币补丁（¥）在容器内可能不生效**——用手机浏览器直接访问 9Router 即为完整体验。
  - fnOS mobile App opens every app via its own WebView iframe, so SameSite-lax login cookies don't persist in the container (can't log in there). We disabled login (`requireLogin=false`) to accommodate it (internal use; API calls still key-guarded). Theme/currency patches may not visibly apply in the mobile container — use a mobile browser for full experience.

## 已知问题与修复 / Known Issues & Fixes

### 🐛 Cloudflare 卡片显示"无连接" / Cloudflare card shows "No connections"

**问题 / Symptom**: 提供商列表页的 **Cloudflare** 卡片即使连接已添加且活跃，仍显示"无连接"（详情页正常）。其他免费提供商（如 NVIDIA）正常。

**根因 / Root cause**: 上游 `cloudflare-ai` provider 目录定义缺少 `authModes:["apikey"]`，导致网格页 `dualAuthTypes()` 只按 `oauth` 过滤，`apikey` 类型的连接被排除在计数外。属上游 bug，已提 [issue #2969](https://github.com/decolua/9router/issues/2969)。

**修复 / Fix**: 在 NAS 上运行补丁脚本：

```bash
bash scripts/patch-cloudflare-authmodes.sh
```

然后浏览器硬刷新 9Router 页面（`Ctrl+Shift+R`）。脚本会给客户端/服务器 bundle 里的 `cloudflare-ai` 定义补上 `authModes:["apikey"]`，并自动备份原文件（`.bak.<timestamp>`）。

> ⚠️ **升级后需重新打补丁**: 该补丁改的是构建产物（bundle），升级 9Router 重新打包后会丢失，需重新运行脚本。脚本会自动定位新 chunk，无需手动改路径。

## 踩坑记录 / Pitfalls

- `cp -r app/*` 漏掉 `.next-cli-build` 隐藏目录 → 服务启动报 "Could not find a production build"
- fnOS 1.1.31xx `TRIM_APPDEST` 直接传 `/vol4/@appcenter/<App>`，cmd/main 已做双路径兼容
- fpk 复制到用户目录可能变 mode 000 → `chmod 644` 修复

详见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 相关链接 / Links

- [9Router GitHub](https://github.com/decolua/9router) · [9Router 官网](https://9router.com)
- [Hermes WebUI](https://github.com/techysy/hermes-webui-fnos) — Hermes 相关 fnOS 应用（WebUI 浏览器访问）
- [MetaCubeXD](https://github.com/techysy/metacubexd-fnos) — Hermes 相关 fnOS 应用（Mihomo 网络代理面板）
- [Strava Panel](https://github.com/techysy/strava-panel-fnos) — Hermes 相关 fnOS 应用（Strava 骑行数据面板）
- [fnOS 开发者文档](https://developer.fnnas.com/docs/guide)

## 🔮 Future / 迭代计划

等待上游 [decolua/9router](https://github.com/decolua/9router) 发布新版本后重新打包：

- 跟进上游版本更新（新功能、Bug 修复）
- 上游新增模型自动同步到9Router Dashboard
- RTK token 节省算法优化

> 📖 上游项目：[decolua/9router](https://github.com/decolua/9router) · [9Router 官网](https://9router.com)

## License

MIT — 与 [decolua/9router](https://github.com/decolua/9router) 一致
