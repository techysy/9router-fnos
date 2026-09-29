# CLAUDE.md

9Router for fnOS — 把上游 [decolua/9router](https://github.com/decolua/9router) 原样打包成飞牛 NAS (fnOS) 应用（.fpk）。本仓库**不承载任何功能代码**：智能路由 / 多格式翻译 / token 节省等能力全部来自上游；功能层面的本地增强在姊妹仓库 [techysy/10router](https://github.com/techysy/10router)，不要混到本仓库。

详细面向用户的说明见 [README.md](README.md)，版本历史见 [CHANGELOG.md](CHANGELOG.md)。

## 核心原则（改动前必读）

- **上游源码逐字节保持原样**。对上游源码的**唯一允许改动**是 `patches/update-check-9router-fnos.mjs`（把仪表盘更新检查从 npm 指向本仓库 Releases）。想加功能 → 去 10router 仓库。
- 该补丁是**标记式**的：找不到上游标记就退出非零并报 "Upstream drifted"，此时必须人工 review 补丁，**不允许静默跳过**。
- 版本号跟随上游（上游 `v0.5.91` → 本仓库 Release `v0.5.91`）；`build.sh` 不传版本参数时自动读上游 `package.json`。

## 仓库结构

```
build.sh                              一键构建：上游克隆 → 补丁 → 构建 → 打四个 fpk
patches/update-check-9router-fnos.mjs 唯一的上游源码改动（更新检查重定向）
cmd/                                  fnOS 生命周期胶水（bash）:
  lib.sh                                公用函数：数据目录 / server / node 定位、.env 修正、在线构建
  main                                  启动：定位运行时、生成 .env（随机 JWT_SECRET）、清 SQLite WAL/SHM、启停
  install_init / install_callback       安装（callback 检测在线构建产物 + node_modules 兜底软链）
  upgrade_* / uninstall_* / config_*    升级 / 卸载 / 配置回调
app/ui/                               桌面图标 + ui/config（url=浏览器打开 | iframe=桌面内嵌）
config/privilege, config/resource     权限与数据共享声明
wizard/install                        安装向导（MIT License 确认页）
scripts/generate-icons.py             生成 ICON*.PNG 与 app/ui/images/*（build.sh 的输入）
scripts/check_pw.py                   排障：查看 SQLite 里的密码哈希 / requireLogin
docs/architecture.svg                 架构图（跟随 GitHub 深浅色主题）
.github/ISSUE_TEMPLATE/               issue 模板（bug / 更新请求）
```

仓库里**没有** manifest 文件——真实 manifest 由 build.sh 每个 variant 用 heredoc 生成到 staging 目录（`appname=9router`、端口 20128、`install_dep_apps=nodejs_v24`、platform 按变体），要改清单字段直接改 build.sh。

## 构建与发布

```bash
./build.sh                       # 自动版本，四个变体全打
./build.sh 0.5.91                # 指定版本，四个变体全打
./build.sh 0.5.91 x86            # 指定版本，只打 x86 离线变体
./build.sh 0.5.91 "" v0.5.91     # 锁定上游 tag（CI 用法；版本号与 tag 不一致会直接失败）
```

ARCH 参数仅接受留空 / `x86` / `all`（ARM 用 `all` 变体），其他值直接报错。

- 前置：git、node 22+、npm、curl；`fnpack`（固定 1.2.1，SHA256 校验）自动下载到 `~/.local/bin`，无需 root。
- 产物（repo 根目录）：`9router-<v>-x86.fpk`（离线）、`-iframe-x86.fpk`（离线内嵌）、`-all.fpk`（在线构建，x86/ARM 通用）、`-iframe-all.fpk`。
- x86 变体 = standalone 构建产物 + 补拷 `node-forge / sql.js / next / better-sqlite3` 等运行时依赖，装时免联网；all 变体 = 内置上游源码树，装时在 NAS 上 `npm install + next build`。
- **发布流程：上游更新 → CI（`.github/workflows/build.yml`）自动打包 → 产物发到本仓库 GitHub Releases**。CI 每天轮询上游最新 tag，把 tag 传给 `build.sh` 第三参数锁定上游源码（保证版本号与源码一致），四产物逐个断言 + 上传 artifact 兜底，再 `gh release create`；同版本 Release 已存在则幂等跳过。
- 注意：fnpack 的临时目录必须落在真实磁盘（build.sh 已用 `TMPDIR=${BUILD_DIR}-fnpack-tmp` 处理 tmpfs 配额问题），别改回去。

## 运行时事实（排障用）

| 项 | 值 |
|---|---|
| 端口 | `20128`（避免与 10Router 冲突，勿改） |
| 数据目录 | `TRIM_PKGVAR`，兜底 `<卷>/@appdata/9router/`（不写死卷号） |
| Node 运行时 | fnOS App Center `nodejs_v24`（manifest `install_dep_apps`） |
| 初始登录密码 | `123456`，`cmd/main` 首次启动写入 `${DATA_DIR}/.env`（持久目录，不会被升级覆盖）；`JWT_SECRET` 首次生成随机值 |
| 部署布局 | 兼容两种：`${APP_DIR}/server` 与 `${APP_DIR}/target/server` |

已知坑（都有对应修复，别回退）：启动前清理 `data.sqlite-shm/wal` 残留（node:sqlite "unable to open database file"）；移动 App WebView iframe 存不住登录 cookie，完整体验用浏览器直连；`cmd/*` 是无扩展名 bash，`.gitattributes` 已强制 LF（CRLF 会导致 NAS 上 `#!/bin/bash\r` 报错）；在线构建的失败必须非零退出，否则 App Center 会「安装成功」但点开空白页。

## 约定

- 文档 / 注释 / commit message 用中文，技术名词保留英文。commit 前缀风格：`build.sh:`、`Fix:`、`Docs:`、`chore:`。
- CHANGELOG 按版本分节（`### 新增 / Added`、`### 修复 / Fixed`、`### 变更 / Changed`），重大定位变更单独成节。
