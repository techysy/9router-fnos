#!/usr/bin/env python3
"""
9Router 货币补丁：给编译后的 Next.js bundle 打补丁，成本显示按界面语言切换本地货币。
- zh-CN 中文 → ¥ (CNY, ×7.2)
- zh-TW 台湾 → NT$ (TWD, ×31.5)
- ja    日本 → ¥ (JPY, ×155)
- ko    韩国 → ₩ (KRW, ×1350)
- vi    越南 → ₫ (VND, ×25000)
- 其他   → $ (USD)

用法：python3 patch_currency.py <chunk.js路径>
幂等，自动备份，注入 __c$ helper + 替换 4 处成本表达式。
"""
import sys, shutil, time

HELPER = ('function __c$(n,p){var d=(document.cookie.match(/locale=([^;]+)/)||[])[1]||"";'
          'var l=d.toLowerCase();'
          'if(/zh-tw|zh-hk|tw/.test(l))return"NT$"+((n||0)*31.5).toFixed(p||2);'
          'if(/ja/.test(l))return"¥"+((n||0)*155).toFixed(p||2);'
          'if(/ko/.test(l))return"₩"+((n||0)*1350).toFixed(p||2);'
          'if(/vi/.test(l))return"₫"+((n||0)*25000).toFixed(p||2);'
          'if(/zh/.test(l))return"¥"+((n||0)*7.2).toFixed(p||2);'
          'return"$"+((n||0).toFixed(p||2))};')

# 4 处成本表达式 (字面匹配): (old, new)
REPLACEMENTS = [
    ('`$${(t||0).toFixed(2)}`', '`${__c$(t||0,2)}`'),
    ('`$${(e||0).toFixed(2)}`', '`${__c$(e||0,2)}`'),
    ('`$${(e||0).toFixed(4)}`', '`${__c$(e||0,4)}`'),
    ('`$${e.toFixed(4)}`', '`${__c$(e,4)}`'),
]

def main(path):
    with open(path, encoding='utf-8') as f:
        src = f.read()

    # 幂等: 已打补丁则跳过
    if '__c$' in src:
        print("✅ 已打过货币补丁，跳过")
        return

    # 备份
    bak = f"{path}.currency.bak.{int(time.time())}"
    shutil.copy2(path, bak)
    print(f"📦 备份: {bak}")

    new_src = src
    count = 0
    for old, new in REPLACEMENTS:
        if old not in new_src:
            print(f"⚠️  替换串未匹配: {old[:40]}")
            continue
        new_src = new_src.replace(old, new)
        count += 1

    # 注入 helper 到 "use strict"; 之后
    marker = '"use strict";'
    if marker in new_src:
        new_src = new_src.replace(marker, marker + HELPER, 1)
    else:
        new_src = HELPER + "\n" + new_src

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_src)

    # 验证
    n = open(path, encoding='utf-8').read().count('__c$')
    print(f"✅ 补丁完成: 替换 {count} 处, __c$ 出现 {n} 次")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("用法: python3 patch_currency.py <chunk.js>")
        sys.exit(1)
    main(sys.argv[1])
