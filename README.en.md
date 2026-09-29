<div align="center">

<img src="ICON_256.PNG" width="96" alt="9Router for fnOS">

# 9Router for fnOS

**Packages upstream [decolua/9router](https://github.com/decolua/9router) as-is into a fnOS (飞牛 NAS) app: pristine upstream source + fnOS glue + one update-check patch, no feature changes**

[![Release](https://img.shields.io/github/v/release/techysy/9router-fnos?label=Version&color=2563eb)](https://github.com/techysy/9router-fnos/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/techysy/9router-fnos/total?label=Downloads&color=16a34a)](https://github.com/techysy/9router-fnos/releases)
[![9Router](https://img.shields.io/github/v/tag/decolua/9router?label=Upstream&color=cyan)](https://github.com/decolua/9router)
[![fnOS](https://img.shields.io/badge/fnOS-1.1.31xx+-orange)](https://developer.fnnas.com/docs/guide)
[![Platform](https://img.shields.io/badge/platform-x86%20%7C%20ARM-6b7280)](#download)
[![License](https://img.shields.io/github/license/techysy/9router-fnos?label=License&color=f59e0b)](LICENSE)

[Download](#download) · [Architecture](#architecture) · [Quick start](#quick-start) · [Update check](#update-check) · [CI](#automated-build-ci) · [Build from source](#build-from-source) · [Structure](#project-structure) · [Changelog](CHANGELOG.md) · [Troubleshooting](TROUBLESHOOTING.md)

</div>

> **Positioning**: the fnOS distribution channel for upstream 9Router. Feature-level customization lives entirely in [techysy/10router](https://github.com/techysy/10router) (a locally-optimized snapshot); this repo only packs "upstream source → fpk", with the **single** source change being the dashboard update check pointing at this repo's Releases (see [Update check](#update-check)).

---

## Download

Grab the fpk from [**Releases**](https://github.com/techysy/9router-fnos/releases/latest), then fnOS **App Center → manual install**:

| File | Architecture | Desktop mode |
|------|------|---------|
| `9router-<ver>-x86.fpk` | x86 | Browser, offline |
| `9router-<ver>-iframe-x86.fpk` | x86 | Embedded in desktop, offline |
| `9router-<ver>-all.fpk` | x86/ARM | Browser, built online |
| `9router-<ver>-iframe-all.fpk` | x86/ARM | Embedded in desktop, built online |

- **x86**: ships build output and runtime deps; installs without network access
- **all**: bundles the upstream source tree and runs `npm install + next build` on the NAS at install time; works on x86/ARM. First install is slow — low-memory devices should add swap first.

> Version numbers follow upstream (e.g. upstream `v0.5.91` → this repo's Release `v0.5.91`). Re-pack after upstream releases; `build.sh` reads the version from upstream's `package.json` automatically.

## Architecture

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/architecture.svg">
  <img src="docs/architecture.svg" alt="9Router for fnOS architecture: upstream source → the single update-check patch → standalone build → fnOS glue overlaid → fnpack packs four fpk variants (x86 / iframe-x86 / all / iframe-all). At runtime on the NAS: desktop icon → Dashboard on port 20128 → fnOS runtime glue (cmd/) → Node.js nodejs_v24 → persistent data dir /volX/@appdata/9router/ → upstream 9Router features (smart routing, format translation, RTK token saving, automatic fallback, usage dashboard)." width="1080">
</picture>

```
decolua/9router (upstream source, shallow clone)
        │
        ▼  patches/update-check-9router-fnos.mjs   ← the ONLY change: update check → this repo's Releases
        │
        ▼  npm install + next build (standalone)
        │
        ▼  assemble app/server                     ← standalone + open-sse + src/mitm + runtime deps
        │
        ▼  overlay fnOS glue                       ← cmd/ · wizard/ · config/ · icons
        │
        ▼  fnpack build                            ← manifest (appname=9router, port 20128)
        │
        ▼
9router-<ver>-<arch>.fpk  →  GitHub Release
```

Source: [`docs/architecture.svg`](docs/architecture.svg) — a single SVG that follows GitHub's light/dark theme automatically.

## Quick start

1. Download the fpk from [Releases](https://github.com/techysy/9router-fnos/releases/latest)
2. fnOS **App Center → manual install** → pick the fpk
3. A **9Router** icon appears on the desktop; click it to open the Dashboard
4. On "Endpoint & Key", grab the API Key and point Claude Code / Codex / Cursor / Cline at `http://<NAS-IP>:20128/v1`

### Port and data

| Item | Value |
|---|---|
| Port | `20128` |
| Data dir | `/volX/@appdata/9router/` (`TRIM_PKGVAR` takes precedence; volume number depends on your setup) |
| Node runtime | fnOS App Center `nodejs_v24` |

### Login

Login is enabled by default; the initial password is **`123456`** (written to `.env` by the packaging glue `cmd/main`; first start also generates a random `JWT_SECRET`). API calls are still protected by the API Key.

> ⚠️ **fnOS mobile app limitation**: the mobile app opens apps in a WebView iframe, where the login cookie (`SameSite=lax`) cannot be persisted, so it keeps bouncing back to the login page. To use it inside the mobile container, turn off "Require Login" in Profile → Settings. For the full experience, open the URL above in a desktop/mobile browser.

## Update check

Applied at build time by [`patches/update-check-9router-fnos.mjs`](patches/update-check-9router-fnos.mjs) — the only change to upstream source:

| Change | Upstream behavior | This package |
|---|---|---|
| Source of "latest version" in `GET /api/version` | npm `9router` package | this repo's GitHub Releases `tag_name` |
| Manual-update panel command | `npm i -g 9router@latest` | points to this repo's Releases page to download a new fpk |

The patch is an exact marker replacement: if upstream drifts and the marker is missing, the build **fails** (it never silently skips), and the patch needs manual review.

## Automated build (CI)

After upstream releases, GitHub Actions packs and publishes automatically — no manual steps:

- **Trigger**: polls upstream's latest tag daily (see [`.github/workflows/build.yml`](.github/workflows/build.yml)), or trigger manually via **Actions → Build & Release fpk → Run workflow**
- **Idempotent**: if a Release for the detected version already exists it is skipped, so the daily run never re-publishes; manual runs can check `force` to re-pack, or fill in `version`
- **Flow**: read upstream's latest tag (and its commit) → `build.sh` pins the upstream source to that tag and builds four variants → assert all four artifacts exist → upload an artifact as a fallback → `gh release create` publishes with the assets
- **Version/source consistency**: `build.sh` pins the upstream tag and fails if the version number and tag disagree, so it cannot produce a package whose contents don't match its version

Scheduled runs may be delayed during GitHub's peak hours — that's normal. Before going live, make sure the repo's **Settings → Actions → General → Workflow permissions** allows read/write (CI needs `contents: write` to create Releases).

## Build from source

On a Linux machine with access to GitHub and the fnpack CDN (NAS / x86 build host):

```bash
git clone https://github.com/techysy/9router-fnos.git
cd 9router-fnos

./build.sh                       # auto version, all four variants
./build.sh 0.5.91                # specific version, all four variants
./build.sh 0.5.91 x86            # specific version, only the x86 offline variant
./build.sh 0.5.91 "" v0.5.91     # pin upstream to a tag (the CI usage: version and source stay in lockstep)
```

Dependencies: `git`, `node 22+`, `npm`, `curl`; `fnpack` is downloaded automatically on first run with SHA256 verification. Artifacts `9router-<ver>[-iframe][-x86|all].fpk` land in the repo root.

## Project structure

```
9router-fnos/
├── build.sh                          # one-shot packer: clone upstream → patch → build → fnpack
├── patches/
│   └── update-check-9router-fnos.mjs # the only change to upstream (update-check redirect)
├── cmd/                              # fnOS lifecycle callbacks
│   ├── lib.sh                        #   shared helpers (path resolution, .env fixup, online build)
│   ├── main                          #   start: resolve runtime, write .env, clear WAL/SHM, start/stop
│   ├── install_callback / upgrade_callback
│   └── uninstall_* / config_* / *_init
├── app/ui/                           # desktop icon config
├── config/                           # data-share declaration (<volume>/@appdata/9router)
├── wizard/                           # install wizard
├── scripts/                          # generate-icons.py, check_pw.py
├── .github/workflows/build.yml       # CI: poll upstream tag → build.sh → publish Release
└── TROUBLESHOOTING.md                # common issues
```

## Related projects

- [decolua/9router](https://github.com/decolua/9router) — upstream
- [techysy/10router](https://github.com/techysy/10router) — locally-optimized snapshot (feature enhancements)

## License

MIT — same as [decolua/9router](https://github.com/decolua/9router). See [LICENSE](LICENSE).
