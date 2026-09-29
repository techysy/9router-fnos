#!/usr/bin/env python3
"""排障工具：查看 9router SQLite 里的密码哈希与 requireLogin 状态。

用法:
    python3 scripts/check_pw.py <data.sqlite 路径> [...]

不传参数时打印用法。默认数据目录由 cmd/main 决定（TRIM_PKGVAR 或 <卷>/@appdata/9router），
数据库位于其下的 db/data.sqlite。
"""
import json
import sqlite3
import sys


def inspect(path: str) -> None:
    print(f"=== {path} ===")
    try:
        con = sqlite3.connect(path)
        cur = con.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in cur.fetchall()]
        print("tables:", tables)
        if "settings" in tables:
            cur.execute("SELECT data FROM settings WHERE id=1")
            row = cur.fetchone()
            if row:
                d = json.loads(row[0])
                print("password hash:", d.get("password"))
                print("requireLogin:", d.get("requireLogin"))
        con.close()
    except Exception as e:  # noqa: BLE001 - 排障工具，任何异常都要打印出来
        print("err:", e)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    for path in sys.argv[1:]:
        inspect(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
