import sqlite3, json, sys

for path in ["app/server/cli/.build-home/.9router/db/data.sqlite",
             "/vol4/@appdata/9router/db/data.sqlite"]:
    print(f"=== {path} ===")
    try:
        con = sqlite3.connect(path)
        cur = con.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in cur.fetchall()]
        print("tables:", tables)
        if "settings" in tables:
            cur.execute("SELECT data FROM settings WHERE id=1")
            d = json.loads(cur.fetchone()[0])
            print("password hash:", d.get("password"))
            print("requireLogin:", d.get("requireLogin"))
    except Exception as e:
        print("err:", e)
