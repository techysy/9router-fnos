# 效果图 / Screenshots

本页汇总 9Router fnOS 版相对上游的增强功能效果图，均来自已提交的上游 PR 评论。

This page collects screenshots of the enhancements in the 9Router fnOS package vs upstream, taken from the submitted upstream PR comments.

---

## 1. 多币种成本显示 / Multi-currency cost（[PR #3118](https://github.com/decolua/9router/pull/3118)）

成本/定价按界面语言显示本地货币（¥ / NT$ / ¥ / ₩ / ₫），可在 Profile 开关切换。
Cost/pricing shows local currency by UI locale (¥ / NT$ / ¥ / ₩ / ₫), toggle in Profile.

**设置页「地区货币」开关 / Regional currency toggle (Profile > Language)**

<img width="900" alt="regional-currency-toggle" src="https://github.com/user-attachments/assets/4a6f7939-9529-478b-a23f-79aad310591c" />

**简体中文 zh-CN — 使用情况页成本 ¥ / Usage page cost in ¥ (CNY)**

<img width="900" alt="cost-zh-CN-yuan" src="https://github.com/user-attachments/assets/4b284e6a-df86-44f0-bf58-01cc833d5c19" />

**繁體中文 zh-TW — 使用情况页成本 NT$ / Usage page cost in NT$ (TWD)**

<img width="900" alt="cost-zh-TW-ntd" src="https://github.com/user-attachments/assets/79727f71-3bd7-468b-ad15-db502d817782" />

**한국어 ko — 使用情况页成本 ₩ / Usage page cost in ₩ (KRW)**

<img width="900" alt="cost-ko-krw" src="https://github.com/user-attachments/assets/69f50943-988d-402a-989a-45da2db23317" />

**组合和视觉适配器页面 / Combos & Vision Adapters page**

<img width="900" alt="combos-page" src="https://github.com/user-attachments/assets/010b32f2-f830-40b1-a119-f08be7991b10" />

> 同一成本值在不同 locale 下显示对应货币；关闭「Regional currency」则统一 `$`。
> Same cost value → locale currency; "Regional currency" off → `$` for all locales.

---

## 2. 配额包按连接独立 / Per-connection quota rows（[PR #3122](https://github.com/decolua/9router/pull/3122)）

同一提供商（如 CodeBuddy CN）配置多个连接时，各连接的配额包独立显示/隐藏。
With multiple connections of the same provider, each connection's quota packs are shown/hidden independently.

**修复后 / After — 双连接独立展示配额包**
Two CodeBuddy CN connections each show their own quota packs

<img width="900" alt="quota-two-connections" src="https://github.com/user-attachments/assets/a82d2d2f-7566-43c2-b206-32cecc7b40e4" />

**修复后 / After — 连接 1 隐藏后，连接 2 不受影响**
After hiding on connection 1, connection 2 is unaffected

<img width="900" alt="quota-hide-conn1-conn2-ok" src="https://github.com/user-attachments/assets/dbd1ff14-b8a0-4263-a6ca-b7e12c34e760" />

**修复前 / Before — 隐藏连接 1 的 Bonus Pack 1，连接 2 被连带隐藏（Bug）**
Before: hiding on connection 1 also hid it on connection 2

<img width="900" alt="quota-before-two-connections" src="https://github.com/user-attachments/assets/328b19b9-0881-46a7-bf42-61149dde260f" />

<img width="900" alt="quota-before-conn2-hidden" src="https://github.com/user-attachments/assets/b484aa9c-001b-4c72-b2e1-04b8a33f2dcd" />

> 根因：`quotaVisibility` 之前以 provider id 为 key，同一 provider 的多个连接共享同一隐藏列表；修复后按连接 id 隔离。
> Root cause: `quotaVisibility` was keyed by provider id (all connections shared one list); now isolated per connection id.

---

## 3. 免费供应商拓扑开关 / Free-provider topology toggle（[PR #3123](https://github.com/decolua/9router/pull/3123)）

noAuth 免费供应商（opencode、MiMo）可在 Provider 页开关是否显示在「使用情况画布」（拓扑图）。
noAuth free providers can be shown/hidden on the Usage topology canvas from the Providers page.

**Provider 页 Free Tier 卡片上的拓扑开关**
Topology show/hide toggle on the Free Tier provider cards

<img width="900" alt="topology-toggle-card" src="https://github.com/user-attachments/assets/43f4372e-2844-4b84-aab8-1c3fb9b18c92" />

**MiMo Code Free 默认隐藏 + deprecation 提示**
MiMo Code Free hidden by default with a deprecation notice

<img width="900" alt="topology-mimo-hidden" src="https://github.com/user-attachments/assets/4f51d188-daa2-4245-8a4d-1d96557c5c92" />

**拓扑图实际显示效果 / Actual usage topology canvas**

<img width="900" alt="topology-canvas" src="https://github.com/user-attachments/assets/8c5f0684-2786-4325-9819-a2b2568357d3" />

<img width="900" alt="topology-canvas-2" src="https://github.com/user-attachments/assets/4cb63a20-4503-40b8-9cef-2554ac7471f0" />

> MiMo 免费通道已终止，默认不在拓扑图显示，但可手动开启。
> MiMo free channel has ended, hidden by default but re-toggleable.

---

## 相关 PR / Related PRs

| 增强 | PR |
|---|---|
| 多币种成本显示 / Multi-currency | [#3118](https://github.com/decolua/9router/pull/3118) |
| 配额包按连接独立 / Per-connection quota rows | [#3122](https://github.com/decolua/9router/pull/3122) |
| 免费供应商拓扑开关 / Topology toggle | [#3123](https://github.com/decolua/9router/pull/3123) |
