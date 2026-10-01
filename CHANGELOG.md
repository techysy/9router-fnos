# CHANGELOG / 更新日志

---

## 热修复：x86 离线包安装/升级失败（2026-10-01）

### 修复 / Fixed
- **`cmd/lib.sh` 同行 `local` 自引用**：`9router_link_node_modules` 里 `local src_dir=... app_dir=... target_nm="${app_dir}/..."` 在 `set -u` 下展开顺序是「先展开后赋值」，抛 `app_dir: unbound variable`，`install_callback` / `upgrade_callback` 非零退出，fnOS 报 **10238（ErrCodeInstallCallbackException）** 并整体回滚。仅影响 x86 离线变体（走「已有构建产物」早退路径必经该函数）；`all` 在线构建变体不经过，不受影响。已拆成两条 `local` 声明，并在 `bash -u` 下对 lib.sh 全函数 + install_callback 完整早退路径做了冒烟验证
- 影响范围：自 c3fde94（lib.sh 抽取，2026-09-29）起的所有 CI 打包 Release（v0.5.95 等），与上游版本号无关；v0.5.91（lib.sh 之前打包）正常

---

## 文档与仓库卫生（2026-09-29）

### 新增 / Added
- **`LICENSE`**：补上 MIT 原文（此前 README 徽章指向的 `LICENSE` 文件并不存在）

### 修复 / Fixed
- **安装向导的 MIT 文本被误改**：`wizard/install` 里原文 `WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE` 被改成 `THEORY, OR LIABILITY, WHETHER IN...`，用户确认的协议与实际分发的不符；已替换为规范 MIT 文本
- **README.en.md 与中文版严重脱节**：仍写着错误参数 `[x86|arm]`、单数 fpk、无四变体矩阵 / CI / TROUBLESHOOTING 链接；已重写与 README.md 对齐

### 变更 / Changed
- **删除仓库根的 `manifest` 占位文件**：没有任何代码引用它（build.sh 用 heredoc 自行生成真实清单），且 version `0.5.55`、desc 文案均已过时，留着只会误导。文档同步说明「真实 manifest 由 build.sh 生成」
- **TROUBLESHOOTING 补「上机验证清单」**：覆盖端口/健康、`.env` 与 JWT、PID 与启停、登录链路、在线构建失败可见性、卷号推导六项，用于 `cmd/` 改动后的真机确认
- **TROUBLESHOOTING 移除个人环境信息**：重置密码示例里写死的真实 NAS IP 与用户名已泛化，卷号与路径改为占位变量

---

## 胶水脚本加固（2026-09-29）

针对 fnOS 生命周期脚本的审查修复。

### 修复 / Fixed
- **构建失败被静默吞掉**：`install_callback` / `upgrade_callback` 里 `npm install exit=$?` 的 `$?` 被 `$(date)` 命令替换覆盖，日志恒为 `exit=0`，配合失败后 `exit 0`，导致 App Center 显示「安装成功」但点开空白页。改为先落码再记日志，且致命失败以非零退出
- **`.env` 修正时机错位**：`install_callback` 的 `.env` 修正写在构建产物早退之后，x86 离线包（已内置产物）走早退时**从不修正**上游占位密码 `change-me`；现与 `upgrade_callback` 对齐，置于早退之前，无论是否重建都执行
- **`JWT_SECRET` 明文占位 + 升级丢失**：`.env` 原先写在会被升级覆盖的 `${APP_DIR}/server` 下，且 `JWT_SECRET` 是固定占位符。现移至持久数据目录 `${DATA_DIR}/.env`，首次启动生成随机 `JWT_SECRET`，并由 `cmd/main` source 作为唯一事实来源（此前 `.env` 里的 `INITIAL_PASSWORD` 对启动完全无效，改密码不生效）
- **PID 复用误判**：`kill -0` 只看 PID 存活，PID 被复用/残留时误判「已在运行」，服务永远拉不起来。新增 `pid_is_ours` 校验 `/proc/<pid>/cmdline` 确含 `custom-server.js`
- **`stop` 杀不干净 / 可能误杀**：原 `pkill -f "${SRC_DIR}/custom-server.js"` 与进程实际 cmdline（相对路径）不匹配，是死代码；改为遍历 `/proc` 只杀工作目录属于本应用的进程，并加等待退出 + SIGKILL 升级
- **x86 变体漏拷 `node-machine-id`**：上游 Dockerfile 明确要拷（`createRequire` 运行时加载，Next tracing 会漏），`src/mitm/manager.js` 与 `open-sse/shared/machineId.js` 都要用，漏拷会使派生密钥走 fail-open 兜底
- **`arm` 参数语义错误**：传 `arm` 会下载 arm64 的 fnpack 并在 x86 构建机上执行（`Exec format error`），且产出非文档化的 `-arm.fpk`。现白名单校验仅允许留空 / `x86` / `all`（ARM 用 `all` 变体），fnpack 二进制改按构建机架构选择

### 新增 / Added
- **`cmd/lib.sh`**：抽出数据目录 / server / node 定位、`.env` 修正、在线构建等公用函数，消除 `install_callback` 与 `upgrade_callback` 之间已发生的逻辑漂移
- **在线构建超时**：`npm install` 30 分钟、`next build` 60 分钟超时，避免低内存设备挂死后安装界面永久卡住

### 变更 / Changed
- `check_pw.py` 从仓库根移到 `scripts/check_pw.py` 并参数化路径（原文件含作者本机硬编码路径）
- `.gitattributes` 为无扩展名的 `cmd/*`、`wizard/*` 强制 LF（CRLF 会导致 NAS 上 `#!/bin/bash\r` 报错）
- README / TROUBLESHOOTING / CLAUDE.md 同步（数据目录不写死卷号、`.env`/`JWT_SECRET` 位置与生成方式、补全仓库结构）

---

## 自动打包 CI + 项目记忆（2026-09-29）

### 新增 / Added
- **GitHub Actions 自动打包**（`.github/workflows/build.yml`）：每天轮询上游 `decolua/9router` 最新 tag，或手动触发（可指定 `version` / `force`）；探测到的版本与已有 Release 相同则跳过（幂等，不重复发版），否则跑 `build.sh` 打四个变体后 `gh release create` 发布并附产物
- **CLAUDE.md**：项目记忆，记录核心原则（上游源码逐字节原样、唯一补丁）、仓库结构、构建发布流程、运行时事实与约定

### 修复 / Fixed（CI 审查后的加固）
- **版本与源码一致**：CI 把探测到的上游 tag 传给 `build.sh`，改用 `git clone --branch <tag>` 锁定源码；并新增版本号与 tag 的一致性校验（不吻合直接失败），避免上游默认分支领先于 tag 时打出「内容与版本号不符」的包
- **预发布 tag 排除**：上游 tag 探测正则收紧为三段式纯数字（`v0.5.91`），排除 `-beta` / `-rc` 等预发布 tag 被误判为最新正式版
- **产物完整性**：发布前逐个断言四个 fpk 存在（不再用 `9router-*.fpk` 通配符静默漏传）；新增 `actions/upload-artifact` 留存产物，`gh release create` 失败时仍可人工取回
- **脚本注入**：手动输入的 `version` / `force` 改经 `env` 传入，不再直接插值进 `run:` 的 shell
- **幂等判断**：`gh release view` 的 404（不存在，正常）与其他错误（网络/限流）区分处理，后者直接失败而非误判为需重新打包
- **Release notes 链接**：改为完整 URL，并附上游 commit 链接（此前 `${UP_TAG}` 被渲染成相对路径 404）

### 变更 / Changed
- `build.sh` 新增可选第三参数 `UPSTREAM_TAG`（缺省仍克隆默认分支，不影响本地手动构建）
- CI job 增加 `timeout-minutes: 90`
- README「从源码构建」更正 `build.sh` 用法（缺省打全部四变体，非只有 x86；架构参数为 `x86`/`all`），并新增「自动打包 (CI)」小节；项目结构补上 `.github/workflows/`

---

## 仓库重定位：纯上游打包（2026-09-27）

### 变更 / Changed
- **定位收窄为「上游 9Router 的 fnOS 分发渠道」**：构建脚本改回从 `decolua/9router` 纯上游源码打包，对源码的**唯一改动**是 `patches/update-check-9router-fnos.mjs`（仪表盘更新检查从 npm `9router` 改指本仓库 GitHub Releases 的 `tag_name`；手动更新面板指向 fpk 下载页）。此前的内置增强（多币种 / 配额包独立 / 免费供应商开关 / 模型目录收敛等）已全部由 [techysy/10router](https://github.com/techysy/10router) 承载，相关文档（docs/enhancements.md、SCREENSHOTS、论坛帖）随本版移除。
- **产物改名**：`10router-<ver>-<arch>.fpk` → `9router-<ver>-<arch>.fpk`；manifest/桌面图标/数据共享同步回 9router 身份（端口保持 20128）。
- **build.sh**：版本号缺省时自动读取上游 package.json；补丁标记缺失时构建失败（不静默跳过）；standalone 补拷清单加 next / better-sqlite3 存在性拷贝。

---

# CHANGELOG / 更新日志

---

## v0.5.55.2 (2026-08-20)

### 修复 / Fixed
- **SQLite WAL/SHM 启动清理** — cmd/main 启动前删除 `data.sqlite-shm`/`data.sqlite-wal` 残留，防止旧版/跨用户安装后属主错误导致 node:sqlite "unable to open database file"
- **install_callback 多路径检测** — 检测 `.next-cli-build`/`.next` 支持 `APP_DIR/server` 和 `APP_DIR/target/server` 两条路径，x86 离线版不再误触发在线构建
- **install_callback node_modules 兜底** — 若 `SRC_DIR` 缺 node_modules 但 `target/server` 有，自动创建符号链接

### 新增 / Added
- **wizard/install MIT 协议** — fpk 安装时显示 MIT License Agreement 确认页

---

## v0.5.55.1 (2026-08-17)

### 修复 / Fixed
- **登录密码逻辑修复** — cmd/main 启动时设置 `INITIAL_PASSWORD`（默认 `123456`），避免数据库密码缺失/requireLogin=false 时远程访问被 "Default password must be changed before remote access" 拦截。首次登录后建议在 Web UI 修改为自定义密码。
- Repack 基于线上 0.5.55 server（含最新增强），版本号对齐 0.5.55.1。

---

## v0.5.55 (2026-08-14)

### 新增 / Added

- **SAML 2.0 SSO**：原生 SAML 单点登录（与 OIDC 并列）— AuthnRequest 生成、ACS 断言处理、SP 元数据导出、管理员配置测试、防重放（`saml_state` cookie 匹配 `InResponseTo`）
- **Alibaba Token Plan**：新增阿里 token 计费计划（`token-plan.ap-southeast-1`，新加坡、仅 OpenAI 兼容传输）
- **GLM 5.3**：加入 GLM Coding 与 GLM（China）
- **Gemini 3.7 Flash**：加入 Antigravity 及 Gemini registry（含 high/medium/low 档位，带定价与配额跟踪）
- **Fish Audio TTS**：新增文字转语音提供商（模型 ID 走 HTTP `model` 头，voice 为 `reference_id`）
- **OpenCode-Go 按传输路由**：按声明的 transports 路由请求格式，不再强制所有客户端走 `/messages`，避免 Responses→OpenAI→Claude 双重翻译损耗；per-model `supportedFormats` 防护
- **Claude 配额调用去重+缓存**：120s TTL（按 access token 键控）、in-flight promise 去重、软失败时读上次成功值，避免多标签页触发 429；手动刷新（↻）发送 `force=1` 绕过缓存

### 修复 / Fixes

- **Docker 内置 sql.js**：镜像带上纯 JS 数据库回退所需的 `sql.js`（无原生驱动时不再 ENOENT 崩溃，[#3248](https://github.com/decolua/9router/pull/3248)）
- **Gemini 用量统计**：从 antigravity `{ response }` 包中读取 `usageMetadata`，修复非流式请求用量记录为 0（[#3260](https://github.com/decolua/9router/pull/3260)）
- **Claude 缓存断点**：重新锚定透传缓存断点，修复每次请求重复缓存尾部的问题（system/工具 1h TTL、最后 assistant 5m）
- **Kiro**：拦截 `x-amz-target` 方式（Kiro IDE 1.0.228+ 改用 `POST /` + header）；报告真实输出 token
- **安全**：要求 `x-9r-real-ip` 必须来自 socket 证明（[GHSA-pjm4-8fpg-f9p6](https://github.com/decolua/9router/security/advisories/GHSA-pjm4-8fpg-f9p6)）
- **版本号 `0.5.55`**（基于上游 master，含以上更新 + 本包货币/配额/拓扑增强）

> 本包从源码构建（含多币种成本显示、配额包按连接隔离、免费供应商拓扑开关、MiMo Code Free 默认显示等增强），见 README「本项目增强」。

---

## v0.5.53 (2026-08-13)

### 修复 / Fixes

- **无连接时不暴露全部内置模型** — 数据库健康但没有任何 provider 连接时，`/v1/models` 不再把内置的 ~680 个模型全部返回给客户端（OpenCode / Cursor 等），只返回用户显式添加的自定义模型（如 `oc/*-free`）。区分「数据库不可用」（兜底返回全部静态模型）与「数据库正常但无连接」（只返回自定义模型/组合）（上游 [PR #3267](https://github.com/decolua/9router/pull/3267)）
- **Don't dump full built-in catalog when DB healthy but has no connections** — with zero provider connections and a healthy DB, `/v1/models` now exposes only user-added custom models / combos instead of the entire static catalog (~680 models), avoiding flooding clients like OpenCode with mostly-unusable entries.

### 变更 / Changed

- **MiMo Code Free 默认在拓扑图显示** — 修复「免费供应商拓扑图」只有一个大 OpenCode 图标的问题：`mimo-free` 默认不再隐藏（`topologyHiddenByDefault=false`），保持与其它免费供应商一致；用户仍可通过 Provider 页开关隐藏/显示
- **MiMo Code Free shown on topology by default** — the usage-topology canvas no longer collapses to a single large OpenCode icon; `mimo-free` defaults to visible (toggle still available on the Providers page to hide/show it)
- 版本号 `0.5.53`（基于上游 master，含 models 空连接修复）
- 实测验证（fnOS NAS）：修复前 `/v1/models` 返回 681 个模型，修复后仅返回 `oc/deepseek-v4-flash-free`、`oc/mimo-v2.5-free` 两个自定义模型

---

## v0.5.52 (2026-08-09)

### 修复 / Fixes

- **默认密码不一致修复** — 修复部署 `.env` 中 `INITIAL_PASSWORD` 为示例值 `change-me`，与前端登录页显示的默认密码 `123456` 不一致的问题。现已统一为 `123456`，首次登录无需修改配置即可使用默认密码
- **Fix default password mismatch** — deployment `.env` shipped with placeholder `INITIAL_PASSWORD=change-me`, inconsistent with the `123456` default shown on the login page. Now unified to `123456`

---

## v0.5.51 (2026-08-08)

### 新增 / Added

- **配额行按连接隔离** — 同一提供商（如 CodeBuddy CN）配置多个连接时，隐藏某连接的配额包（如 Bonus Pack 1）不再影响其它连接的同类配额包。`quotaVisibility` 改为按连接 id 存储，兼容旧版 provider-key 设置（上游 [PR #3122](https://github.com/decolua/9router/pull/3122)）
- **Per-connection quota row visibility** — hiding a bonus/refill pack on one account no longer hides it on another account of the same provider

### 修复 / Fixes

- **免费供应商拓扑图开关** — noAuth 免费供应商（opencode、MiMo Code Free）现可在 Provider 页通过开关控制是否显示在「使用情况画布」（拓扑图）；MiMo 免费通道已终止，默认不显示，可手动开启（上游 [PR #3123](https://github.com/decolua/9router/pull/3123)）
- **Free-provider topology toggle** — noAuth free providers get a show/hide toggle for the usage topology canvas; MiMo free (service ended) is hidden by default but re-toggleable
- **声明 Node.js 运行时依赖** — manifest 增加 `install_dep_apps=nodejs_v24`，安装时自动检查/安装 Node.js 运行时，避免其他用户因未装 nodejs 而无法启动（`cmd/main` 改为规范路径 `/var/apps/nodejs_v24/target/bin` 并增强探测）
- **Declare Node.js runtime dependency** — `install_dep_apps=nodejs_v24` so the runtime installs automatically; `cmd/main` uses the standard path with fallback probing

### 货币显示 / Currency

- **成本按界面语言显示本地货币** — 中文 ¥、台湾 NT$、日本 ¥、韩国 ₩、越南 ₫，可在 Profile 开关（上游 [PR #3118](https://github.com/decolua/9router/pull/3118)）
- **Regional currency display** — cost shown in local currency by UI locale

### 变更 / Changed

- 版本号 `0.5.51`（源码级：货币 PR #3118 + 配额/拓扑补丁）

---

## v0.5.50.5 (2026-08-06)

### 修复 / Fixes

- **移除预估缓存算法** — 命中率估算不可靠、无法生效，已移除。只记录上游返回的**真实缓存值**，未返回则不记录（不做预估）
- **Dropped estimate algorithm** — only record real upstream cached values
- **移除 bundle 货币补丁** — 源码已实现货币功能（`currency.js` + profile 开关），不再重复打 bundle 补丁；修复「货币开关不生效」（之前 bundle 补丁覆盖了源码开关逻辑）

### 变更 / Changed

- **iframe 版本**（`app/ui/config` type=iframe）

---

## v0.5.50.4 (2026-08-05)

### 修复 / Fixes

- **缓存 Token 统计不生效（始终为 0）** — 根因：上游返回的缓存字段名是 `cached_tokens`/`cache_read_input_tokens`（非 `cached_prompt_tokens`），`recordCacheTokenStats` 读取不到真实缓存。已兼容所有缓存字段名
- **Cached-token stats showing 0** — accept `cached_tokens` / `cache_read_input_tokens` field variants
- **货币开关移到 Profile** — 从右上角头部移到 Profile > Language 卡片下（Select Language 下方）
- **Regional-currency toggle moved to Profile > Language**
- **缓存卡片 i18n** — 新增「Cache Hit Rate」翻译键；「(含预估)」标记独立避免破坏 i18n 整键匹配

### 变更 / Changed

- 本版为 **iframe 版本**（桌面窗口内嵌，`app/ui/config` type=iframe）

---

## v0.5.50.3 (2026-08-05)

### 新增 / Added

- **缓存 Token 预估统计**：概览页新增「缓存 TOKEN」「缓存命中率」卡片，按模型表格展示缓存列；上游返回真实缓存值时标记真实值，未返回时基于该模型历史命中率估算并标记 `(含预估)`（仅供参考，不计费）
- **Cached-token estimate stats**: overview shows Cached Tokens + Cache Hit Rate; per-model table adds cache column; estimates marked (含预估)
- **货币全局开关**：语言切换旁新增 💱 地区货币开关（默认开启；关闭后成本统一显示 `$`）
- **Regional-currency toggle**: header 💱 switch beside language; off → `$` everywhere

### 变更 / Changed

- `patch_currency.py` 改为正则自适应（支持混淆后 `$${a.toFixed(t)}` 模板，升级不再失效）

---

## v0.5.50.2 (2026-08-05)

### 更新 / Update

- **多币种货币补丁**：成本显示按界面语言切换本地货币
- **Multi-currency patch**: cost display switches by UI locale
  - 中文 `zh-CN` → ¥ CNY（×7.2）
  - 台湾 `zh-TW` → NT$ TWD（×31.5）
  - 日本 `ja` → ¥ JPY（×155）
  - 韩国 `ko` → ₩ KRW（×1350）
  - 越南 `vi` → ₫ VND（×25000）
  - 其他 → $ USD
- 更新 `scripts/patch_currency.py` 支持多币种

---

## v0.5.50.1 (2026-08-05)

### 更新 / Update

- **货币补丁版**：单独打一个补丁，修复升级 0.5.50 后成本显示仍为美元 `$` 的问题
- **Currency patch**: dedicated patch so cost displays ¥ (×7.2) in zh-CN UI after the 0.5.50 upgrade
- 根因：0.5.50 重新构建后 bundle chunk hash 变了，运行时 `__c$` 货币补丁丢失，成本仍硬编码 `$`
- 新增 `scripts/patch_currency.py`（可复用，幂等，自动备份），烘焙进 fpk

---

## v0.5.50 (2026-08-05)

### 更新 / Update

- 同步上游 `decolua/9router` v0.5.50
- Synced upstream `decolua/9router` v0.5.50
- 沿用货币补丁（zh-CN 显示 ¥）、freeTier authModes 补丁、node-forge 补装
- Retains currency patch (¥ in zh-CN), freeTier authModes patch, node-forge reinstall

---

## v0.5.45+ (2026-08-02)

### 修复 / Fixes

- 🔧 **freeTier 提供商连接状态补丁**：新增 `scripts/fix-freetier-authmodes.py`，自动修复所有 `category:"freeTier"` 但缺 `authModes:["apikey"]` 的提供商（Cloudflare、BytePlus、Ollama、Vertex 等），解决提供商列表页连接状态显示异常。排除 `authType:"none"`（TTS/搜索/本地）和纯 OAuth 提供商，幂等可重复运行。

---

## v0.5.45 (2026-08-01)

### 更新 / Update

- 版本号回归官方 `0.5.45`（不再用 .01 后缀）
- Version back to official `0.5.45` (dropped the .01 packaging suffix)
- 🎨 应用图标更新为官方 9Router hub logo（中心 1 大 + 外围 5 小空心圆环，对角橙色渐变）
- Updated app icon to official 9Router hub logo (1 center + 5 outer hollow rings, diagonal orange gradient)
- 💰 成本显示按界面语言切换货币：中文界面显示 ¥（乘 7.2 汇率），英文显示 $（预估成本、概览卡片、图表、Cost/call）
- Cost display switches currency by UI language: Chinese shows ¥ (×7.2), English shows $ (Est. Cost, overview, chart, Cost/call)
- 📦 打包位置改为 `/vol1/1000/fnOS App/`
- Build output moved to `/vol1/1000/fnOS App/`

### 修复 / Fixes

- 附带 Cloudflare 卡片"无连接"补丁脚本 `scripts/patch-cloudflare-authmodes.sh`

---

## v0.5.45.01 (2026-08-01)

### 更新 / Update

- 打包版本号升至 `0.5.45.01`（记录打包次数，同时触发 App Center 图标刷新）
- Packaging version bumped to `0.5.45.01` (tracks package count; also forces App Center icon refresh)
- 重打 url + iframe 两个 fpk
- Rebuilt both url + iframe fpk variants

### 更新 / Update

- 应用图标更新为官方 9Router hub logo（中心 1 大 + 外围 5 小空心圆环，对角橙色渐变）
- Updated app icon to official 9Router hub logo (1 center + 5 outer hollow rings, diagonal orange gradient)
- 图标由 `scripts/generate-icons.py` 生成（可复现，仅需 PIL）
- Icons generated by `scripts/generate-icons.py` (reproducible, PIL only)

---

## v0.5.45-patch1 (2026-08-01)

### 修复 / Fixes

- 新增 Cloudflare 卡片"无连接"显示 bug 的补丁脚本 `scripts/patch-cloudflare-authmodes.sh`
- Add patch script for the Cloudflare "No connections" grid-display bug
- 根因：上游 `cloudflare-ai` 定义缺 `authModes:["apikey"]`（[issue #2969](https://github.com/decolua/9router/issues/2969)）
- Root cause: upstream `cloudflare-ai` registry missing `authModes:["apikey"]`
- 升级 9Router 重新打包后需重新运行脚本（构建产物补丁会丢失）
- Re-run the script after repackaging/upgrading 9Router (build-artifact patch is lost on rebuild)

---

## v0.5.45 (2026-07-31)

### 初始版本 / Initial Release

- 首次打包9Router v0.5.45 为 fnOS 应用
- First fpk package of9Router v0.5.45 for fnOS
- 端口 20128，iframe 嵌入 fnOS 桌面
- Port 20128, iframe on fnOS desktop
- 兼容 fnOS 1.1.31xx+ 的 TRIM_APPDEST 路径差异
- Compatible with fnOS 1.1.31xx+ TRIM_APPDEST path variation
- 数据目录 `/vol4/@appdata/9router/`
- Data dir `/vol4/@appdata/9router/`

### 踩坑记录 / Pitfalls

- `cp -r app/*` 会漏掉隐藏目录 `.next-cli-build` → "Could not find a production build"
- `cp -r app/*` skips dot-directories like `.next-cli-build`
- fnOS `TRIM_APPDEST` 在 1.1.31xx 传 `/vol4/@appcenter/<App>`（server 在根下）
- fnOS `TRIM_APPDEST` on 1.1.31xx is `/vol4/@appcenter/<App>` (server at root)
- fpk 复制到可见目录可能变 mode 000 → 需 `chmod 644`
- fpk copied to visible dir may land mode 000 → chmod 644 needed
- standalone node_modules 缺 node-forge（MITM 证书生成用）
- standalone node_modules missing node-forge (MITM cert generation)
