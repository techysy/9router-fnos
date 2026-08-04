# 9Router for fnOS

[![GitHub release](https://img.shields.io/github/v/release/techysy/9router-fnos?label=Latest&color=blue)](https://github.com/techysy/9router-fnos/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/techysy/9router-fnos/blob/main/LICENSE)
[![fnOS 1.1.31xx](https://img.shields.io/badge/fnOS-1.1.31xx+-orange.svg)](https://developer.fnnas.com/docs/guide)
[![9Router v0.5.45](https://img.shields.io/badge/9Router-v0.5.45-cyan.svg)](https://github.com/decolua/9router)

> 9Router — FREE AI Router & Token Saver for 飞牛 NAS (fnOS). Connect Claude Code / Codex / Cursor to 40+ free AI providers. Save 20-40% tokens with RTK, auto-fallback never stops coding.

Packages [decolua/9router](https://github.com/decolua/9router) as a fnOS desktop app, ready to use.

- [中文 README](./README.md)

---

## ✨ Features

- **One endpoint for all AI**: Point Claude Code, Codex, Cursor, Cline to `http://<NAS-IP>:20128/v1` to reach 40+ free AI providers
- **Auto-fallback**: Switch providers on rate-limit/failure without interrupting coding
- **RTK Token Saver**: Save 20-40% tokens
- **RMB pricing**: Built-in currency patch shows ¥ on the Pricing page (see "Enhancements" below)

## 🚀 Quick Install

1. Download `9router-x.x.x.fpk` from [Releases](https://github.com/techysy/9router-fnos/releases)
2. In fnOS **App Center → Manual Install** → select the fpk
3. Click the **9Router** icon on the desktop to open the Dashboard

## 📖 Usage

### Connect AI tools

```bash
# Point CLI tools (Claude Code / Codex / Cursor / Cline) to the 9Router endpoint
# Base URL: http://<NAS-IP>:20128/v1
# API Key: 9Router Dashboard → Endpoint & Key
```

Configure AI providers (e.g. Kiro AI free models) in the Dashboard, then start using.

### Port & Data

| Item | Value |
|---|---|
| Port | `20128` |
| Data dir | `/vol4/@appdata/9router/` |
| Node runtime | fnOS App Center `nodejs_v24` |

### Login

This app ships with **login disabled** (`requireLogin=false`) to work with the fnOS mobile app container. API calls are still guarded by API Key.

### ⚠️ fnOS Mobile App Limits

The fnOS mobile app (iOS/Android) opens every app in its own WebView iframe, with limitations:

- **Cannot log in**: `SameSite=lax` login cookies don't persist in the container (login loop). This app disables login to work around it.
- **Limited UI persistence**: `localStorage` / theme switching / currency patch (¥) may not visibly apply.

> 💡 For the full experience, use a **desktop browser** or **mobile browser** directly at `http://<NAS-IP>:20128`.

## 🔧 Enhancements vs Upstream

Compared to upstream [decolua/9router](https://github.com/decolua/9router), this package adds:

| Enhancement | Description |
|---|---|
| **RMB (¥) pricing patch** | Pricing page shows ¥ instead of $ |
| **Cloudflare fix** | Fixes Cloudflare card wrongly showing "No connections" |

These patches are applied automatically on each build (integrated into `scripts/prepare-server.sh`).

## 🛠️ Build from Source

> For developers. Most users should use the Release.

```bash
git clone https://github.com/techysy/9router-fnos.git
cd 9router-fnos

# Extract 9Router standalone + apply enhancement patches
# Add fnOS node to PATH first: export PATH=/vol4/@appcenter/nodejs_v24/bin:$PATH
bash scripts/prepare-server.sh 0.5.45

# Build the fpk (must run on the fnOS NAS)
fnpack build
```

## 🐛 Troubleshooting

Build/install/run issues and fixes: see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

## 🔮 Roadmap

Repack once upstream [decolua/9router](https://github.com/decolua/9router) releases a new version:

- Track upstream updates
- Auto-sync new upstream models to Dashboard
- RTK token-saving algorithm improvements

## 📚 Related

- [decolua/9router](https://github.com/decolua/9router) — upstream open-source project
- [Hermes WebUI](https://github.com/techysy/hermes-webui-fnos) · [MetaCubeXD](https://github.com/techysy/metacubexd-fnos) · [Strava Panel](https://github.com/techysy/strava-panel-fnos) — more fnOS apps
- [fnOS Developer Docs](https://developer.fnnas.com/docs/guide)

## License

MIT — same as [decolua/9router](https://github.com/decolua/9router)
