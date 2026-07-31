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

## 踩坑记录 / Pitfalls

- `cp -r app/*` 漏掉 `.next-cli-build` 隐藏目录 → 服务启动报 "Could not find a production build"
- fnOS 1.1.31xx `TRIM_APPDEST` 直接传 `/vol4/@appcenter/<App>`，cmd/main 已做双路径兼容
- fpk 复制到用户目录可能变 mode 000 → `chmod 644` 修复

详见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 相关链接 / Links

- [9Router GitHub](https://github.com/decolua/9router) · [9Router 官网](https://9router.com)
- [fnOS 开发者文档](https://developer.fnnas.com/docs/guide)

## License

MIT — 与 [decolua/9router](https://github.com/decolua/9router) 一致
