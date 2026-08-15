# 9Router 本项目增强与优化

> 说明 9Router for fnOS 基于**修改过的上游 fork**（[techysy/9router](https://github.com/techysy/9router)）构建时，额外包含的**优化与增强**，以及 fork 的管理方式。

---

## 1. 构建来源：修改过的 fork

**9Router for fnOS 不是从纯上游 `decolua/9router` 构建**，而是基于**修改过的 fork**（`techysy/9router`）。

fork 的状态：
- **已同步上游**：合并到 v0.5.55（2026-08-14），落后上游 0 提交
- **领先上游**：15 个本地增强提交（均提上游 PR，合并后本地保留）

> 构建用 fork（含本地增强），而非纯上游或 npm 包提取。

---

## 2. 功能增强清单

> **合并状态说明**：以下增强均**已提上游 PR，但目前尚未被上游合并**（本地独有，已随本包编译）。`✅ 已合并` = 上游已包含；`🕐 待合并` = 已提 PR 未合并。

### 2.1 多币种成本显示 `🕐 待合并`
成本/定价按界面语言显示本地货币：中文 ¥、台湾 NT$、日本 ¥、韩国 ₩、越南 ₫，Profile 开关切换。
- 上游 [PR #3118](https://github.com/decolua/9router/pull/3118)（**open，未合并**）

### 2.2 配额包按连接独立 `🕐 待合并`
同一提供商（如 CodeBuddy CN）配置多个连接时，隐藏某连接的配额包（Bonus Pack）不再影响其它连接的同类配额包。`quotaVisibility` 按连接 id 存储。
- 上游 [PR #3122](https://github.com/decolua/9router/pull/3122)（**open，未合并**）

### 2.3 免费供应商拓扑开关 `🕐 待合并`
noAuth 免费供应商（opencode、MiMo Code Free）可在 Provider 页通过开关控制是否显示在「使用情况画布」（拓扑图）。
- 上游 [PR #3123](https://github.com/decolua/9router/pull/3123)（**open，未合并**）

### 2.4 MiMo Code Free 默认显示 `🕐 待合并`
`mimo-free` 默认在「使用情况画布」显示（不再只一个大 OpenCode 图标），仍可通过 Provider 页开关隐藏/显示。

### 2.5 无连接时不暴露全部内置模型 `🕐 待合并`
数据库健康但未配置任何 provider 连接时，`/v1/models` 只返回显式添加的自定义模型（如 `oc/*-free`），不把 ~680 个内置模型全部抛给 OpenCode/Cursor 等客户端。
- 上游 [PR #3267](https://github.com/decolua/9router/pull/3267)（**open，未合并**）

### 2.6 Cloudflare 修复 `✅ 已合并（上游已含）`
修复 Cloudflare 卡片误显示"无连接"。
- 上游 [PR #2993](https://github.com/decolua/9router/pull/2993)（closed，功能已随上游 v0.5.50 包含）

### 2.7 其他本地优化
- **i18n zh-CN 翻译**：中文翻译优化
- **better-sqlite3 依赖升级**：`^12.11.1`
- **standalone 构建 workflow**：CI 辅助构建
- **初始密码统一**：`INITIAL_PASSWORD` 从 `change-me` 改为 `123456`（`.env.example` + 安装/升级自动修正）

---

## 3. 与上游的关系

| 项 | 说明 |
|----|------|
| 上游 | [decolua/9router](https://github.com/decolua/9router) |
| 构建来源 | [techysy/9router](https://github.com/techysy/9router)（fork，含本地增强） |
| 同步策略 | 上游发新版本后，fork 合并 upstream，保留本地增强 |
| 版本 | 对齐上游 v0.5.55 |

---

## 4. fork 管理（同步策略）

上游更新后，同步 fork 的流程：

```bash
# 1. fork 添加上游 remote
git remote add upstream https://github.com/decolua/9router.git

# 2. 拉取上游 master
git fetch upstream master

# 3. 合并上游 (保留本地增强, 可能需解决冲突)
git merge upstream/master

# 4. 推送回 fork
git push origin master
```

> 本地增强（currency/quota/拓扑等）在合并后保留。若上游同时改了相关文件，需解决冲突（通常在这些增强文件，如 `profile/page.js`、`currency.js`）。

---

## 5. 涉及文件（本地增强）

| 文件 | 改动 |
|------|------|
| `.env.example` | `INITIAL_PASSWORD` change-me → 123456 |
| `src/shared/utils/currency.js` | 多币种显示逻辑 |
| `src/app/(dashboard)/dashboard/profile/page.js` | Profile 货币开关 |
| `src/app/(dashboard)/dashboard/providers/page.js` | 免费供应商拓扑开关 |
| `src/lib/db/repos/settingsRepo.js` | 配额可见性按连接存储 |
| `src/shared/constants/providers.js` | 提供商配置 |
| `open-sse/providers/registry/mimo-free.js` | MiMo 默认显示 |
| `public/i18n/literals/zh-CN.json` | 中文翻译 |
| `.github/workflows/build-server.yml` | standalone 构建 workflow |

---

## 6. 相关文档

- 效果图：[docs/SCREENSHOTS.md](./SCREENSHOTS.md)
- 从源码构建：[README「从源码构建」](../README.md)
