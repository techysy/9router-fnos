# CHANGELOG / 更新日志

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
