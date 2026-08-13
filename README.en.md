# 9Router for fnOS

[![GitHub release](https://img.shields.io/github/v/release/techysy/9router-fnos?label=Latest&color=blue)](https://github.com/techysy/9router-fnos/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/techysy/9router-fnos/blob/main/LICENSE)
[![fnOS 1.1.31xx](https://img.shields.io/badge/fnOS-1.1.31xx+-orange.svg)](https://developer.fnnas.com/docs/guide)
[![9Router](https://img.shields.io/github/v/tag/decolua/9router?label=9Router&color=cyan)](https://github.com/decolua/9router)

> 9Router — FREE AI Router & Token Saver for 飞牛 NAS (fnOS). Connect Claude Code / Codex / Cursor to 40+ free AI providers. Save 20-40% tokens with RTK, auto-fallback never stops coding.

Packages [decolua/9router](https://github.com/decolua/9router) as a fnOS desktop app, ready to use.

- [中文 README](./README.md)

---

## ✨ Features

- **One endpoint for all AI**: Point Claude Code, Codex, Cursor, Cline to `http://<NAS-IP>:20128/v1` to reach 40+ free AI providers
- **Auto-fallback**: Switch providers on rate-limit/failure without interrupting coding
- **RTK Token Saver**: Save 20-40% tokens
- **Multi-currency cost**: Cost/pricing shows local currency by UI locale (¥/NT$/¥/₩/₫), toggle in Profile
- **Per-connection quota rows**: With multiple connections of the same provider, each connection's quota packs (e.g. Bonus Pack) are shown/hidden independently
- **Toggleable free providers**: noAuth free providers (opencode, MiMo) can be shown/hidden on the Usage topology canvas from the Providers page
- **No built-in dump when no connections**: with a healthy DB but zero provider connections, `/v1/models` only returns the user's explicitly added custom models (e.g. `oc/*-free`) instead of the ~680 built-in models (upstream [PR #3267](https://github.com/decolua/9router/pull/3267))

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

### 🌐 Direct browser access

The **iframe variant** (embedded in desktop) can also be opened **directly in a browser**, same experience as the desktop window:

| Access | URL |
|---|---|
| LAN (intranet) | `http://<NAS-IP>:20128` |
| Remote (internet) | `http://9route.<fnid>.fnos.net/` |

> 💡 For the full experience, use a desktop/mobile browser directly at the URLs above.

### Login

This app **enables login by default** (`requireLogin=true`, source-build default). First login uses the initial password `123456` (unified since v0.5.52, matching the login page). API calls are still guarded by API Key.

### ⚠️ fnOS Mobile App Limits

The fnOS mobile app (iOS/Android) opens every app in its own WebView iframe, with limitations:

- **Cannot log in**: `SameSite=lax` login cookies don't persist in the container (login loop). If you need to use it inside the mobile-app container, disable **Require Login** under **Profile → Settings** to work around it (toggle is available on the login page).
- **Limited UI persistence**: `localStorage` / theme switching may not visibly apply (currency is compiled into the source build, not a runtime patch).

> 💡 For the full experience, use a **desktop browser** or **mobile browser** directly — see the "🌐 Direct browser access" section above (LAN `http://<NAS-IP>:20128` / remote `http://9route.<fnid>.fnos.net/`).

## 🔧 Enhancements vs Upstream

Compared to upstream [decolua/9router](https://github.com/decolua/9router), this package adds (all with upstream PRs):

| Enhancement | Description | Upstream PR |
|---|---|---|
| **Multi-currency cost** | Cost/pricing shows local currency by UI locale: zh ¥, zh-TW NT$, ja ¥, ko ₩, vi ₫, Profile toggle | [#3118](https://github.com/decolua/9router/pull/3118) |
| **Per-connection quota rows** | Same provider with multiple connections: each connection's quota packs shown/hidden independently | [#3122](https://github.com/decolua/9router/pull/3122) |
| **Free-provider topology toggle** | noAuth free providers (opencode, MiMo) show/hide on the Usage topology canvas from the Providers page | [#3123](https://github.com/decolua/9router/pull/3123) |
| **Cloudflare fix** | Fixes Cloudflare card wrongly showing "No connections" (already in upstream v0.5.50) | [#2993](https://github.com/decolua/9router/pull/2993) |
| **No built-in dump when no connections** | With zero provider connections and a healthy DB, `/v1/models` returns only custom models/combos, not all ~680 built-in models | [#3267](https://github.com/decolua/9router/pull/3267) |

These enhancements are compiled into the package from source (`NEXT_DIST_DIR=.next-cli-build npm run build`); see "Build from Source" below.

### 📸 Screenshots

Actual screenshots of each enhancement (from the upstream PR comments): see [docs/SCREENSHOTS.md](./docs/SCREENSHOTS.md).

## 🛠️ Build from Source

> For developers. Most users should use the Release. This package is built from source (with the currency/quota/topology enhancements), not extracted from the npm package.

```bash
git clone https://github.com/techysy/9router-fnos.git
# Need the 9Router source (with the enhancement branches):
git clone https://github.com/techysy/9router.git 9router-src

cd 9router-src
npm install
NEXT_DIST_DIR=.next-cli-build npm run build   # produces the standalone

# Assemble app/server (copy .next-cli-build/standalone contents + custom-server.js into 9router-fnos/app/server)
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
