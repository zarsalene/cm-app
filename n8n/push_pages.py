"""Push the "Z-Smart-CM" pages to n8n: viteine + APK download workflows.

- vitrine_cm_app.workflow.json  -> created/updated AND activated (public URL: /webhook/z-smart-cm)
- apk-download.workflow.json    -> created/updated but left INACTIVE (serves /data/apk/Z-Smart-CM.apk;
                                   copy the file on the server first, then activate in the UI)
Run: python -I n8n/push_pages.py   (needs env N8N_API_URL and N8N_API_KEY)
"""
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DIR = Path(__file__).resolve().parent
TARGETS = [
    ("vitrine_cm_app.workflow.json", True),   # activate
    ("apk-download.workflow.json", False),    # leave inactive
]


def api(method, path, body=None):
    req = urllib.request.Request(
        os.environ["N8N_API_URL"].rstrip("/") + "/api/v1" + path,
        method=method,
        data=json.dumps(body).encode("utf-8") if body is not None else None,
        headers={"X-N8N-API-KEY": os.environ["N8N_API_KEY"], "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            raw = r.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"n8n API {method} {path} -> {e.code}: {e.read().decode('utf-8', 'replace')[:600]}")


def find_workflow(name):
    cursor = ""
    while True:
        r = api("GET", "/workflows?limit=100" + (f"&cursor={urllib.parse.quote(cursor)}" if cursor else ""))
        for w in r.get("data", []):
            if w.get("name") == name:
                return w
        cursor = r.get("nextCursor")
        if not cursor:
            return None


def push(file_name, activate):
    path = DIR / file_name
    wf = json.loads(path.read_text(encoding="utf-8"))
    body = {k: wf[k] for k in ("name", "nodes", "connections", "settings")}
    existing = find_workflow(wf["name"])
    if existing:
        wid = existing["id"]
        api("PUT", f"/workflows/{wid}", body)
        print(f"updated   {wid}  {wf['name']}  (was active: {existing.get('active')})")
    else:
        wid = api("POST", "/workflows", body)["id"]
        print(f"created   {wid}  {wf['name']}")
    if activate:
        api("POST", f"/workflows/{wid}/activate")
        print(f"activated {wid}")
    else:
        print(f"left inactive (copy /data/apk/Z-Smart-CM.apk on the server first)  {wid}")


def main():
    sys.stdout.reconfigure(encoding="utf8")
    for file_name, activate in TARGETS:
        push(file_name, activate)


if __name__ == "__main__":
    main()
