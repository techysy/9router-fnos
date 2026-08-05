#!/usr/bin/env python3
"""
9Router 货币补丁（正则自适应版）：给编译后的 Next.js bundle 打补丁，
成本显示按界面语言切换本地货币。

- zh-CN → ¥ (CNY ×7.2)
- zh-TW → NT$ (TWD ×31.5)
- ja    → ¥ (JPY ×155)
- ko    → ₩ (KRW ×1350)
- vi    → ₫ (VND ×25000)
- 其他  → $ (USD)

不依赖具体 chunk 结构：正则匹配 `` `$${...toFixed(d)}` `` 成本模板，替换为 __c$ 调用。
用法：python3 patch_currency.py <chunk.js路径>
幂等，自动备份。
"""
import sys, re, shutil, time

HELPER = ('function __c$(n,p){var d=(document.cookie.match(/locale=([^;]+)/)||[])[1]||"";'
          'var l=d.toLowerCase();'
          'if(/zh-tw|zh-hk|tw/.test(l))return"NT$"+((n||0)*31.5).toFixed(p||2);'
          'if(/ja/.test(l))return"¥"+((n||0)*155).toFixed(p||2);'
          'if(/ko/.test(l))return"₩"+((n||0)*1350).toFixed(p||2);'
          'if(/vi/.test(l))return"₫"+((n||0)*25000).toFixed(p||2);'
          'if(/zh/.test(l))return"¥"+((n||0)*7.2).toFixed(p||2);'
          'return"$"+((n||0).toFixed(p||2))};')

# 匹配 `` `$${<expr>.toFixed(<prec>)}` `` 成本模板（双美元=成本；单美元 M/K 缩写不匹配）
# prec 可以是数字或变量（压缩混淆后如 toFixed(t)）
COST_RE = re.compile(r'`\$\$\{([^}]*?)\.toFixed\(([a-zA-Z_$][\w$]*|[0-9]+)\)\}`')


def main(path):
    with open(path, encoding="utf-8") as f:
        src = f.read()

    if "__c$" in src:
        print("✅ 已打过货币补丁，跳过")
        return

    bak = f"{path}.currency.bak.{int(time.time())}"
    shutil.copy2(path, bak)
    print(f"📦 备份: {bak}")

    count = 0
    def repl(m):
        nonlocal count
        expr = m.group(1).strip()
        # 去掉外层括号和 ||0：__(t||0)__ → t（__c$ 内部已处理 n||0）
        expr = re.sub(r'^\s*\(?', '', expr)
        expr = re.sub(r'(?:\|\|0)?\)?\s*$', '', expr)
        prec = m.group(2)
        count += 1
        return f"`${{__c$({expr}, {prec})}}`"

    new_src, n = COST_RE.subn(repl, src)

    if n == 0:
        # 找不到模板：打印上下文便于诊断
        print("⚠️  未匹配到成本模板 (count=0)，toFixed 上下文：")
        for mm in re.finditer(r'`[^`]*\$\$[^`]*`', src):
            print("   ", mm.group(0)[:100])
        return

    marker = '"use strict";'
    if marker in new_src:
        new_src = new_src.replace(marker, marker + HELPER, 1)
    else:
        new_src = HELPER + "\n" + new_src

    with open(path, "w", encoding="utf-8") as f:
        f.write(new_src)

    total = open(path, encoding="utf-8").read().count("__c$")
    print(f"✅ 补丁完成: 替换 {n} 处成本模板, __c$ 出现 {total} 次")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 patch_currency.py <chunk.js>")
        sys.exit(1)
    main(sys.argv[1])
