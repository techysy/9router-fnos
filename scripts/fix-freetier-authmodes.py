#!/usr/bin/env python3
"""精确修复 9Router freeTier 类缺 authModes:[\"apikey\"] 的 provider。
排除: authType:\"none\"(无需认证) / authModes 含 oauth 但无 apikey(纯OAuth)。
幂等: 已修复的跳过。自动备份。
用法: python3 fix_freetier_authmodes.py
"""
import re, glob, shutil, time

CLIENT = glob.glob("/vol4/@appcenter/9router/server/.next-cli-build/static/chunks/1321-*.js")
SERVER = glob.glob("/vol4/@appcenter/9router/server/.next-cli-build/server/chunks/*.js")
CHUNKS = CLIENT + SERVER

def find_provider_defs(c):
    defs = []
    for m in re.finditer(r'id:"([^"]+)"', c):
        start = m.start()
        nxt = c.find('id:"', start+3)
        end = nxt if nxt != -1 else start + 3000
        seg = c[start:min(end, start+3000)]
        if 'category:"' in seg:
            defs.append({'id': m.group(1), 'start': start, 'seg': seg})
    return defs

def should_fix(seg):
    """判断是否应补 authModes apikey"""
    cat = re.search(r'category:"([^"]+)"', seg)
    at = re.search(r'authType:"([^"]+)"', seg)
    am = re.search(r'authModes:\[([^\]]*)\]', seg)
    category = cat.group(1) if cat else None
    authtype = at.group(1) if at else None
    authmodes = am.group(1) if am else None

    # 只处理 freeTier
    if category != "freeTier":
        return False
    # 排除无需认证的 (authType="none")
    if authtype == "none":
        return False
    # 排除纯 OAuth (authModes 含 oauth 但无 apikey)
    if authmodes and "oauth" in authmodes and "apikey" not in authmodes:
        return False
    # 已修复则跳过
    if authmodes and "apikey" in authmodes:
        return False
    # 其余 freeTier 缺 apikey 的都修
    return True

def apply_patch(c, seg_start):
    """在 category:\"xxx\" 后插入 authType:\"apikey\",authModes:[\"apikey\"],"""
    cat_match = re.search(r'category:"([^"]+)"', c[seg_start:seg_start+3000])
    if not cat_match:
        return None
    insert_at = seg_start + cat_match.end()
    insertion = ',authType:"apikey",authModes:["apikey"]'
    # 幂等: 若后面紧跟 authType 则跳过
    if c[insert_at:insert_at+20].startswith(',authType:') or c[insert_at:insert_at+20].startswith(',authModes:'):
        return None
    return insert_at, insertion

fixed_all = []
for chunk in CHUNKS:
    try:
        c = open(chunk, encoding="utf-8", errors="ignore").read()
    except: continue
    if 'category:"' not in c: continue
    defs = find_provider_defs(c)
    fixed = []
    changed = False
    for d in defs:
        if should_fix(d['seg']):
            r = apply_patch(c, d['start'])
            if r:
                insert_at, insertion = r
                c = c[:insert_at] + insertion + c[insert_at:]
                fixed.append(d['id'])
                changed = True
    if changed:
        bak = chunk + f".freetier.{int(time.time())}"
        shutil.copy2(chunk, bak)
        open(chunk, "w", encoding="utf-8").write(c)
        fixed_all.append((chunk.split('/')[-1], fixed, bak.split('/')[-1]))

print("=== 自动修复结果 ===")
for name, ids, bak in fixed_all:
    print(f"{name}: 修复 {len(ids)} 个 -> {ids}")
    print(f"   备份: {bak}")
if not fixed_all:
    print("无需要修复的")
