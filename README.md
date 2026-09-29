<div align="center">

<img src="ICON_256.PNG" width="96" alt="9Router for fnOS">

# 9Router for fnOS

**把上游 [decolua/9router](https://github.com/decolua/9router) 原样打包成飞牛 NAS (fnOS) 应用：纯净上游源码 + fnOS 胶水 + 一处更新检查补丁，无任何功能改动**

[![Release](https://img.shields.io/github/v/release/techysy/9router-fnos?label=%E7%89%88%E6%9C%AC&color=2563eb)](https://github.com/techysy/9router-fnos/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/techysy/9router-fnos/total?label=%E4%B8%8B%E8%BD%BD&color=16a34a)](https://github.com/techysy/9router-fnos/releases)
[![9Router](https://img.shields.io/github/v/tag/decolua/9router?label=%E4%B8%8A%E6%B8%B8&color=cyan)](https://github.com/decolua/9router)
[![fnOS](https://img.shields.io/badge/fnOS-1.1.31xx+-orange)](https://developer.fnnas.com/docs/guide)
[![Platform](https://img.shields.io/badge/%E5%B9%B3%E5%8F%B0-x86%20%7C%20ARM-6b7280)](#下载)
[![License](https://img.shields.io/github/license/techysy/9router-fnos?label=%E8%AE%B8%E5%8F%AF&color=f59e0b)](LICENSE)

[下载](#下载) · [架构](#架构) · [快速开始](#快速开始) · [更新检查](#更新检查) · [从源码构建](#从源码构建) · [项目结构](#项目结构) · [更新日志](CHANGELOG.md)

</div>

> **定位**：上游 9Router 的 fnOS 分发渠道。功能层面的定制与增强全部由 [techysy/10router](https://github.com/techysy/10router)（本地优化快照）承载；本仓库只做「上游源码 → fpk」的打包，对源码的**唯一改动**是把仪表盘的更新检查指向本仓库的 Releases（见 [更新检查](#更新检查)）。

---

## 下载

从 [**Releases**](https://github.com/techysy/9router-fnos/releases/latest) 下载 fpk，飞牛 **App Center → 手动安装**：

| 版本 | 架构 | 桌面模式 |
|------|------|---------|
| `9router-<版本>-x86.fpk` | x86 | 普通（浏览器打开），离线 |
| `9router-<版本>-iframe-x86.fpk` | x86 | 桌面内嵌，离线 |
| `9router-<版本>-all.fpk` | x86/ARM | 普通，在线构建 |
| `9router-<版本>-iframe-all.fpk` | x86/ARM | 桌面内嵌，在线构建 |

- **x86 版**：含构建产物与运行时依赖，安装免联网
- **all 版**：内置上游源码树，安装时在 NAS 上 `npm install + next build`，x86/ARM 通用；首次安装耗时较长，低内存设备建议先加 swap

> 版本号跟随上游（如上游 `v0.5.91` → 本仓库 Release `v0.5.91`）。上游发新版后重新打包即可，`build.sh` 会自动读取上游 `package.json` 的版本号。

## 架构

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/architecture.svg">
  <img src="docs/architecture.svg" alt="9Router for fnOS 架构总览：上游源码 → 唯一补丁 → standalone 构建 → 叠加 fnOS 胶水 → fnpack 打包出四个 fpk 变体（x86 / iframe-x86 / all / iframe-all）；在飞牛 NAS 上运行时为 桌面图标 → Dashboard(20128) → fnOS 运行时胶水 → Node.js nodejs_v24 → /volX/@appdata/9router/ 数据目录 → 上游 9Router 能力（智能路由 / 多格式翻译 / RTK token 节省 / 自动 fallback / 用量仪表盘）" width="1080">
</picture>

<details>
<summary>文字版流程图</summary>

```
decolua/9router (上游源码, 浅克隆)
        │
        ▼  patches/update-check-9router-fnos.mjs   ← 唯一改动：更新检查指向本仓库 Releases
        │
        ▼  npm install + next build (standalone)
        │
        ▼  组装 app/server                          ← standalone + open-sse + src/mitm + 运行时依赖
        │
        ▼  叠加 fnOS 胶水                           ← cmd/ 启停回调 · wizard/ 安装向导 · config/ 数据共享 · 图标
        │
        ▼  fnpack build                             ← manifest (appname=9router, 端口 20128)
        │
        ▼
9router-<版本>-<arch>.fpk  →  GitHub Release
```

</details>

仓库内没有上游功能代码——所有「智能路由 / 多格式翻译 / RTK token 节省 / 自动 fallback / 用量仪表盘」能力都来自上游 9Router 本身，详见 [decolua/9router](https://github.com/decolua/9router)。

> 图源：[`docs/architecture.svg`](docs/architecture.svg)（纯 SVG，跟随 GitHub 深浅色主题自动切换，可点击查看原图）

## 快速开始

1. 从 [Releases](https://github.com/techysy/9router-fnos/releases/latest) 下载 fpk
2. 飞牛 **App Center → 手动安装** → 选择 fpk
3. 桌面出现 **9Router** 图标，点击打开 Dashboard
4. 「Endpoint & Key」页取 API Key，把 Claude Code / Codex / Cursor / Cline 等工具指向 `http://<NAS-IP>:20128/v1`

### 端口与数据

| 项 | 值 |
|---|---|
| 端口 | `20128` |
| 数据目录 | `/volX/@appdata/9router/`（`TRIM_PKGVAR` 优先，卷号按实际环境） |
| Node 运行时 | fnOS App Center `nodejs_v24` |

### 浏览器直接访问

| 访问方式 | 地址 |
|---|---|
| 内网（局域网） | `http://<NAS-IP>:20128` |
| 外网（远程） | `http://9route.<fnid>.fnos.net/` |

### 登录说明

本包默认开启登录，首次登录初始密码为 **`123456`**（由打包胶水 `cmd/main` 写入 `.env`，安装/升级时自动把上游占位值修正为该值）。API 调用仍受 API Key 保护。

> ⚠️ **飞牛移动 App 限制**：移动 App 用 WebView iframe 打开应用，登录 cookie（`SameSite=lax`）无法在容器内保存，会反复跳回登录页；如需在移动容器内使用，可在 Profile → Settings 关闭「Require Login」。完整体验请用电脑/手机浏览器直接访问上述地址。

## 更新检查

对上游源码的唯一改动，由 [`patches/update-check-9router-fnos.mjs`](patches/update-check-9router-fnos.mjs) 在构建时应用：

| 改动 | 上游行为 | 本包行为 |
|---|---|---|
| `GET /api/version` 的「最新版本」来源 | 查 npm `9router` 包 | 查本仓库 GitHub Releases 的 `tag_name` |
| 手动更新面板的命令 | `npm i -g 9router@latest` | 指向本仓库 Releases 页下载新 fpk |

补丁为精确标记替换：上游源码漂移导致标记缺失时**构建直接失败**（不静默跳过），此时需要人工评估补丁是否需要跟进。

## 自动打包 (CI)

上游发新版后由 GitHub Actions 自动打包发布，无需人工干预：

- **触发**：每天轮询一次上游最新 tag（见 [`.github/workflows/build.yml`](.github/workflows/build.yml)），或在本仓库 **Actions → Build & Release fpk → Run workflow** 手动触发
- **幂等**：探测到的版本若已有同版本 Release 则跳过，所以每天跑不会重复发版；手动触发时可勾选 `force` 强制重打，或填 `version` 指定版本
- **流程**：读上游最新 tag（同时取到对应 commit）→ `build.sh` 把上游源码锁定到该 tag 构建四个变体 → 四个产物逐个断言存在 → 上传 artifact 兜底 → `gh release create` 发布并附产物
- **版本与源码一致**：`build.sh` 锁定上游 tag 构建，并在版本号与 tag 不吻合时直接失败，避免打出「内容与版本号不符」的包

定时任务在 GitHub 高峰期可能延迟，属正常现象。首次上线前请确认仓库 **Settings → Actions → General → Workflow permissions** 允许读写（CI 创建 Release 需要 `contents: write`）。

## 从源码构建

在能访问 GitHub 与 fnpack CDN 的 Linux 机器（NAS / x86 构建机）上执行：

```bash
git clone https://github.com/techysy/9router-fnos.git
cd 9router-fnos

./build.sh                # 自动版本，打全部四个变体
./build.sh 0.5.91         # 指定版本，打全部四个变体
./build.sh 0.5.91 x86     # 指定版本，只打 x86 离线变体（兼容旧行为）
./build.sh 0.5.91 "" v0.5.91   # 锁定上游到指定 tag（CI 用法：版本号与源码强一致）
```

依赖：`git`、`node 22+`、`npm`、`curl`；`fnpack` 首次运行自动下载并做 SHA256 校验。产物 `9router-<版本>[-iframe][-x86|all].fpk` 落在仓库根目录。

## 项目结构

```
9router-fnos/
├── build.sh                          # 一键打包：克隆上游 → 补丁 → 构建 → fnpack
├── patches/
│   └── update-check-9router-fnos.mjs # 对上游的唯一改动（更新检查重定向）
├── cmd/                              # fnOS 生命周期回调
│   ├── main                          #   启动：清 WAL/SHM、写 .env、拉起 server
│   ├── install_callback / upgrade_callback
│   └── uninstall_callback / config_callback / ...
├── app/ui/                           # 桌面图标配置
├── config/                           # 数据共享声明（<卷>/@appdata/9router）
├── wizard/                           # 安装向导
├── manifest                          # fnpack 清单模板（build.sh 生成实际值）
├── .github/workflows/build.yml       # CI：轮询上游 tag → build.sh → 发 Release
└── TROUBLESHOOTING.md                # 常见问题排查
```

## 相关项目

- [decolua/9router](https://github.com/decolua/9router) — 上游开源项目
- [techysy/10router](https://github.com/techysy/10router) — 基于上游 v0.5.55 的本地优化快照（增强版，含多币种、配额包独立、模型目录收敛等）
- [fnOS 开发者文档](https://developer.fnnas.com/docs/guide)

## License

MIT — 与 [decolua/9router](https://github.com/decolua/9router) 一致
