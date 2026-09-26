# 9Router for fnOS

[![Release](https://img.shields.io/github/v/release/techysy/9router-fnos?label=Version&color=2563eb)](https://github.com/techysy/9router-fnos/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/techysy/9router-fnos/total?label=Downloads&color=16a34a)](https://github.com/techysy/9router-fnos/releases)
[![9Router](https://img.shields.io/github/v/tag/decolua/9router?label=Upstream&color=cyan)](https://github.com/decolua/9router)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**9Router** — FREE AI Router & Token Saver, packaged as a fnOS (飞牛 NAS) app. Connect Claude Code / Codex / Cursor / Cline to the router at `http://<NAS-IP>:20128/v1`.

> **Pure upstream packaging**: this repo builds [decolua/9router](https://github.com/decolua/9router) as-is into an fnOS `.fpk`. The **only** source change is an update-check redirect — the dashboard checks this repo's GitHub Releases instead of npm, so fpk updates are discovered and downloaded here. All feature-level customization lives in [techysy/10router](https://github.com/techysy/10router).

- Download: [Releases](https://github.com/techysy/9router-fnos/releases/latest) → App Center → manual install. Port `20128`, first-login password `123456` (set by the packaging glue).
- Build: `./build.sh [version] [x86|arm]` — clones upstream, applies `patches/update-check-9router-fnos.mjs`, builds the standalone bundle, packs the fpk.
- 中文文档：[README.md](./README.md)

## License

MIT — same as [decolua/9router](https://github.com/decolua/9router)
