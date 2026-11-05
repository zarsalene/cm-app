"""Persist the Facebook profile name in `sales_bot_user_ai_control.label`.

The CM app shows the real customer name from that column. The Facebook bot
already fetches `first_name`/`last_name` in the `Sender name` node; this script
adds one MySQL update right after it. Empty API responses never overwrite an
existing name.

Usage:
    python -I n8n/update_botgenius_names.py            # dry run
    python -I n8n/update_botgenius_names.py --apply    # PUT the live workflow
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import sys
import urllib.request
import uuid
from pathlib import Path
from typing import Any

WORKFLOW_ID = "f32N0iDTz5FEz38t"
MYSQL_CREDENTIALS = {
    "mySql": {"id": "apLhSdbSQHjaIsZY", "name": "BDMigration (WA sales bot)"},
}
BACKUP_DIR = Path("n8n/backups")
OUTPUT = Path("n8n/botgenius.workflow.json")
NODE_NAME = "Save sender name"

BASE = os.environ.get("N8N_API_URL", "").rstrip("/")
KEY = os.environ.get("N8N_API_KEY", "")
if not BASE or not KEY:
    sys.exit("N8N_API_URL / N8N_API_KEY are required")


def api(path: str, method: str = "GET", payload: Any = None) -> Any:
    body = None if payload is None else json.dumps(payload).encode()
    request = urllib.request.Request(
        f"{BASE}/api/v1{path}",
        data=body,
        method=method,
        headers={"X-N8N-API-KEY": KEY, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        raw = response.read()
        return json.loads(raw) if raw else None


def build() -> dict[str, Any]:
    workflow = api(f"/workflows/{WORKFLOW_ID}")
    original = copy.deepcopy(workflow)
    nodes = {n["name"]: n for n in workflow["nodes"]}
    if "Sender name" not in nodes:
        sys.exit("Node 'Sender name' is missing")
    if NODE_NAME in nodes:
        print(f"{NODE_NAME!r} already exists; updating it")
        workflow["nodes"] = [n for n in workflow["nodes"] if n["name"] != NODE_NAME]
    nodes = {n["name"]: n for n in workflow["nodes"]}
    sender = nodes["Sender name"]

    save = {
        "parameters": {
            "operation": "executeQuery",
            "query": (
                "INSERT INTO sales_bot_user_ai_control "
                "(sender_id, platform, label)\n"
                "VALUES (SUBSTRING($1, 3), 'facebook', SUBSTRING($2, 3))\n"
                "ON DUPLICATE KEY UPDATE label = "
                "IF(VALUES(label) = '', label, VALUES(label))"
            ),
            "options": {
                "queryReplacement": (
                    "={{ [ (v => v == null ? null : 's:' + v)"
                    "($('Is valid message1').first().json.psid), "
                    "(v => v == null ? null : 's:' + v)"
                    "([$json.first_name, $json.last_name]"
                    ".filter(Boolean).join(' ').trim()) ] }}"
                )
            },
        },
        "id": str(uuid.uuid4()),
        "name": NODE_NAME,
        "type": "n8n-nodes-base.mySql",
        "typeVersion": 2.5,
        "position": [sender["position"][0], sender["position"][1] + 176],
        "credentials": MYSQL_CREDENTIALS,
        "alwaysOutputData": True,
        "executeOnce": True,
        "retryOnFail": True,
        "maxTries": 3,
        "waitBetweenTries": 2000,
    }
    workflow["nodes"].append(save)

    connections = workflow["connections"]
    # Sender name -> Save sender name -> Guided?
    connections["Sender name"] = {
        "main": [[{"node": NODE_NAME, "type": "main", "index": 0}]]
    }
    connections[NODE_NAME] = {
        "main": [[{"node": "Guided?", "type": "main", "index": 0}]]
    }
    return {"original": original, "updated": workflow}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    result = build()
    updated = result["updated"]
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup = BACKUP_DIR / f"live_BotGenius_{WORKFLOW_ID}.json"
    backup.write_text(
        json.dumps(result["original"], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    OUTPUT.write_text(
        json.dumps(updated, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Backup : {backup}")
    print(f"Updated: {OUTPUT}")

    if not args.apply:
        print("Dry run. Re-run with --apply to PUT the live workflow.")
        return

    payload = {
        "name": updated["name"],
        "nodes": updated["nodes"],
        "connections": updated["connections"],
        "settings": updated.get("settings", {}),
    }
    if updated.get("staticData") is not None:
        payload["staticData"] = updated["staticData"]
    api(f"/workflows/{WORKFLOW_ID}", "PUT", payload)
    if not updated.get("active"):
        api(f"/workflows/{WORKFLOW_ID}/activate", "POST")
    live = api(f"/workflows/{WORKFLOW_ID}")
    print(f"Live   : {live['name']} active={live['active']} nodes={len(live['nodes'])}")


if __name__ == "__main__":
    main()
