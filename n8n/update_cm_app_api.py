"""Extend the live `CM App API` workflow with the unified-inbox actions.

Adds:
  * `conversations`  - merged view of sales_bot_user_ai_control + escalations
  * `set_ai_mode`    - real bot/human toggle, independent of an escalation
  * chat gating      - a known conversation no longer needs an escalation row

Usage:
    python -I n8n/update_cm_app_api.py            # write + validate locally
    python -I n8n/update_cm_app_api.py --apply    # also PUT the live workflow

Env: N8N_API_URL, N8N_API_KEY (same as the other n8n scripts).
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

WORKFLOW_ID = "t3q8R2tAXC1SfI1a"
ESCALATIONS_TABLE = "d4rAEGcJRHUxFFkS"
GENERATED_NODES = {
    "Conversations control",
    "List conversations",
    "Build conversations",
    "Conversations done",
    "Set AI mode",
    "Mode is bot?",
    "Close escalation (AI)",
    "AI mode done",
}
MYSQL_CREDENTIALS = {
    "mySql": {"id": "apLhSdbSQHjaIsZY", "name": "BDMigration (WA sales bot)"},
}
BACKUP_DIR = Path("n8n/backups")
OUTPUT = Path("n8n/cm_app_api.workflow.json")


def env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        sys.exit(f"Missing environment variable {name}")
    return value


BASE = env("N8N_API_URL").rstrip("/")
KEY = env("N8N_API_KEY")


def api(path: str, method: str = "GET", payload: Any = None) -> Any:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        f"{BASE}/api/v1{path}",
        data=body,
        method=method,
        headers={
            "X-N8N-API-KEY": KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        raw = response.read()
        return json.loads(raw) if raw else None


def node(
    name: str,
    node_type: str,
    version: float,
    position: list[int],
    parameters: dict[str, Any],
    **extra: Any,
) -> dict[str, Any]:
    value: dict[str, Any] = {
        "parameters": parameters,
        "id": str(uuid.uuid4()),
        "name": name,
        "type": node_type,
        "typeVersion": version,
        "position": position,
    }
    value.update(extra)
    return value


def respond(name: str, position: list[int], body: str) -> dict[str, Any]:
    return node(
        name,
        "n8n-nodes-base.respondToWebhook",
        1.1,
        position,
        {
            "respondWith": "json",
            "responseBody": body,
            "options": {
                "responseCode": 200,
                "responseHeaders": {
                    "entries": [{"name": "Cache-Control", "value": "no-store"}]
                },
            },
        },
    )


def switch_rule(rule_id: str, output: str, expression: str) -> dict[str, Any]:
    return {
        "conditions": {
            "options": {
                "caseSensitive": True,
                "leftValue": "",
                "typeValidation": "loose",
            },
            "conditions": [
                {
                    "id": rule_id,
                    "leftValue": expression,
                    "rightValue": "true",
                    "operator": {"type": "string", "operation": "equals"},
                }
            ],
            "combinator": "and",
        },
        "renameOutput": True,
        "outputKey": output,
    }


CONVERSATIONS_CODE = r"""// Unified inbox: every known conversation + its latest escalation.
const ctl = $('Conversations control').all().map((i) => i.json).filter((r) => r && r.sender_id != null);
const esc = $input.all().map((i) => i.json).filter((r) => r && r.sender_id != null);
const key = (r) => String(r.platform) + '/' + String(r.sender_id);
const iso = (v) => {
  if (v == null || v === '') return null;
  const d = new Date(v);
  return isNaN(d.getTime()) ? null : d.toISOString();
};
const map = new Map();

for (const r of ctl) {
  const platform = String(r.platform || '').toLowerCase();
  if (!['facebook', 'whatsapp'].includes(platform)) continue;
  const human = Number(r.ai_enabled) === 0;
  map.set(key({ platform, sender_id: r.sender_id }), {
    sender_id: String(r.sender_id),
    platform,
    customer_name: String(r.label || ''),
    last_message: String(r.last_message || ''),
    last_seen: iso(r.last_seen),
    mode: human ? 'human' : 'bot',
    status: human ? 'open' : 'active',
    reason: '',
    escalated_at: iso(r.escalated_at),
  });
}

for (const r of esc) {
  const platform = String(r.platform || '').toLowerCase();
  if (!['facebook', 'whatsapp'].includes(platform)) continue;
  const k = key({ platform, sender_id: r.sender_id });
  const cur = map.get(k) || {
    sender_id: String(r.sender_id),
    platform,
    customer_name: '',
    last_message: '',
    last_seen: null,
    mode: 'human',
    status: 'open',
    reason: '',
    escalated_at: null,
  };
  cur.customer_name = String(r.customer_name || cur.customer_name || '');
  cur.reason = String(r.reason || cur.reason || '');
  cur.escalated_at = iso(r.escalated_at) || cur.escalated_at;
  const status = String(r.status || 'open').toLowerCase();
  if (status === 'open') {
    cur.status = 'open';
    cur.mode = 'human';
  } else if (cur.mode !== 'human') {
    cur.status = 'closed';
  }
  if (!cur.last_seen) cur.last_seen = cur.escalated_at;
  map.set(k, cur);
}

const items = [...map.values()]
  .sort((a, b) => String(b.last_seen || b.escalated_at || '')
    .localeCompare(String(a.last_seen || a.escalated_at || '')))
  .slice(0, 200);
return [{ json: { items } }];"""


def build() -> dict[str, Any]:
    workflow = api(f"/workflows/{WORKFLOW_ID}")
    original = copy.deepcopy(workflow)
    # Idempotent: drop nodes this script owns before rebuilding them.
    workflow["nodes"] = [
        n for n in workflow["nodes"] if n["name"] not in GENERATED_NODES
    ]
    for name in GENERATED_NODES:
        workflow["connections"].pop(name, None)
    nodes = {n["name"]: n for n in workflow["nodes"]}

    for required in ("Action", "Escalation Check", "Escalated?", "Load AI control",
                     "Load history", "Build chat"):
        if required not in nodes:
            sys.exit(f"Unexpected workflow: node {required!r} is missing")

    # ---- Action switch: insert conversations + set_ai_mode -----------------
    action = nodes["Action"]
    values = action["parameters"]["rules"]["values"]
    by_output = {rule["outputKey"]: rule for rule in values}

    conversations_rule = switch_rule(
        "Action_conversations",
        "conversations",
        "={{ String($('Webhook').first().json.body.action === 'conversations') }}",
    )
    set_mode_rule = switch_rule(
        "Action_set_ai_mode",
        "set_ai_mode",
        "={{ String($('Webhook').first().json.body.action === 'set_ai_mode' "
        "&& (['facebook', 'whatsapp'].includes($('Webhook').first().json.body.platform) "
        "&& /^\\d{5,32}$/.test(String($('Webhook').first().json.body.sender_id ?? '')) "
        "&& ['bot', 'human'].includes($('Webhook').first().json.body.mode))) }}",
    )
    bad_request = by_output["bad_request"]
    bad_request["conditions"]["conditions"][0]["leftValue"] = (
        "={{ String(['chat', 'reply', 'give_back', 'set_ai_mode']"
        ".includes($('Webhook').first().json.body.action)) }}"
    )

    ordered = [
        by_output["escalations"],
        conversations_rule,
        set_mode_rule,
        by_output["chat"],
        by_output["reply"],
        by_output["give_back"],
        by_output["logout"],
        bad_request,
    ]
    action["parameters"]["rules"]["values"] = ordered

    # ---- chat gate: known control row OR an escalation row -----------------
    escalated = nodes["Escalated?"]
    escalated["parameters"]["conditions"]["conditions"][0]["leftValue"] = (
        "={{ String(($json.ai_enabled != null) "
        "|| $('Escalation Check').all().some((i) => i.json && i.json.sender_id != null "
        "&& String(i.json.sender_id) === String($('Webhook').first().json.body.sender_id) "
        "&& i.json.platform === $('Webhook').first().json.body.platform)) }}"
    )

    # ---- Load AI control: platform-aware and before the gate ---------------
    load_control = nodes["Load AI control"]
    load_control["parameters"]["query"] = (
        "SELECT ai_enabled, label\n"
        "FROM sales_bot_user_ai_control\n"
        "WHERE sender_id = SUBSTRING($1, 3) AND platform = SUBSTRING($2, 3)\n"
        "LIMIT 1"
    )
    load_control["parameters"]["options"]["queryReplacement"] = (
        "={{ [ (v => v == null ? null : 's:' + v)"
        "(String($('Webhook').first().json.body.sender_id)), "
        "(v => v == null ? null : 's:' + v)"
        "($('Webhook').first().json.body.platform) ] }}"
    )

    # ---- Build chat: keep the control label as a real customer name --------
    build_chat = nodes["Build chat"]
    build_chat["parameters"]["jsCode"] = build_chat["parameters"]["jsCode"].replace(
        "customer_name: esc.customer_name || ''",
        "customer_name: esc.customer_name || ctl.label || ''",
    )

    # ---- New nodes ---------------------------------------------------------
    new_nodes = [
        node(
            "Conversations control",
            "n8n-nodes-base.mySql",
            2.5,
            [1100, 900],
            {
                "operation": "executeQuery",
                "query": (
                    "SELECT sender_id, platform, ai_enabled, disabled_by, "
                    "escalated_at, last_message, last_seen, label\n"
                    "FROM sales_bot_user_ai_control\n"
                    "ORDER BY last_seen DESC\n"
                    "LIMIT 200"
                ),
                "options": {},
            },
            credentials=MYSQL_CREDENTIALS,
            alwaysOutputData=True,
            executeOnce=True,
            retryOnFail=True,
            maxTries=3,
            waitBetweenTries=2000,
        ),
        node(
            "List conversations",
            "n8n-nodes-base.dataTable",
            1.1,
            [1320, 900],
            {
                "resource": "row",
                "operation": "get",
                "dataTableId": {
                    "__rl": True,
                    "mode": "id",
                    "value": ESCALATIONS_TABLE,
                },
                "returnAll": True,
                "options": {},
            },
            alwaysOutputData=True,
            executeOnce=True,
        ),
        node(
            "Build conversations",
            "n8n-nodes-base.code",
            2,
            [1540, 900],
            {"jsCode": CONVERSATIONS_CODE},
        ),
        respond(
            "Conversations done",
            [1760, 900],
            "={{ JSON.stringify($json) }}",
        ),
        node(
            "Set AI mode",
            "n8n-nodes-base.mySql",
            2.5,
            [1100, 1050],
            {
                "operation": "executeQuery",
                "query": (
                    "INSERT INTO sales_bot_user_ai_control "
                    "(sender_id, platform, ai_enabled, disabled_by, escalated_at)\n"
                    "VALUES (SUBSTRING($1, 3), SUBSTRING($2, 3), $3, "
                    "IF($3 = 0, 'cm_app', NULL), IF($3 = 0, NOW(), NULL))\n"
                    "ON DUPLICATE KEY UPDATE\n"
                    "  platform = VALUES(platform),\n"
                    "  ai_enabled = VALUES(ai_enabled),\n"
                    "  disabled_by = VALUES(disabled_by),\n"
                    "  escalated_at = VALUES(escalated_at)"
                ),
                "options": {
                    "queryReplacement": (
                        "={{ [ (v => v == null ? null : 's:' + v)"
                        "(String($('Webhook').first().json.body.sender_id)), "
                        "(v => v == null ? null : 's:' + v)"
                        "($('Webhook').first().json.body.platform), "
                        "$('Webhook').first().json.body.mode === 'human' ? 0 : 1 ] }}"
                    )
                },
            },
            credentials=MYSQL_CREDENTIALS,
            alwaysOutputData=True,
            executeOnce=True,
            retryOnFail=True,
            maxTries=3,
            waitBetweenTries=2000,
        ),
        node(
            "Mode is bot?",
            "n8n-nodes-base.if",
            2,
            [1320, 1050],
            {
                "conditions": {
                    "options": {
                        "caseSensitive": True,
                        "leftValue": "",
                        "typeValidation": "loose",
                    },
                    "conditions": [
                        {
                            "id": "Mode is bot?",
                            "leftValue": (
                                "={{ String($('Webhook').first().json.body.mode "
                                "=== 'bot') }}"
                            ),
                            "rightValue": "true",
                            "operator": {
                                "type": "string",
                                "operation": "equals",
                            },
                        }
                    ],
                    "combinator": "and",
                },
                "options": {},
            },
        ),
        node(
            "Close escalation (AI)",
            "n8n-nodes-base.dataTable",
            1.1,
            [1540, 1050],
            {
                "resource": "row",
                "operation": "update",
                "dataTableId": {
                    "__rl": True,
                    "mode": "id",
                    "value": ESCALATIONS_TABLE,
                },
                "matchType": "allConditions",
                "filters": {
                    "conditions": [
                        {
                            "keyName": "sender_id",
                            "condition": "eq",
                            "keyValue": (
                                "={{ String($('Webhook').first()"
                                ".json.body.sender_id) }}"
                            ),
                        },
                        {
                            "keyName": "platform",
                            "condition": "eq",
                            "keyValue": (
                                "={{ $('Webhook').first().json.body.platform }}"
                            ),
                        },
                    ]
                },
                "columns": {
                    "mappingMode": "defineBelow",
                    "value": {"status": "closed"},
                    "matchingColumns": [],
                    "schema": [],
                },
                "options": {},
            },
            alwaysOutputData=True,
        ),
        respond(
            "AI mode done",
            [1760, 1050],
            "={{ JSON.stringify({ ok: true, "
            "mode: $('Webhook').first().json.body.mode, "
            "status: $('Webhook').first().json.body.mode === 'human' "
            "? 'open' : 'active' }) }}",
        ),
    ]

    existing_names = {n["name"] for n in workflow["nodes"]}
    for value in new_nodes:
        if value["name"] in existing_names:
            sys.exit(f"Node {value['name']!r} already exists")
        workflow["nodes"].append(value)

    # ---- Connections -------------------------------------------------------
    def edge(name: str) -> list[dict[str, Any]]:
        return [{"node": name, "type": "main", "index": 0}]

    connections = workflow["connections"]
    connections["Action"] = {
        "main": [
            edge("List escalations"),
            edge("Conversations control"),
            edge("Set AI mode"),
            edge("Escalation Check"),
            edge("Escalation Check"),
            edge("Escalation Check"),
            edge("Delete session"),
            edge("Bad request"),
            edge("Bad action"),
        ]
    }
    connections["Conversations control"] = {"main": [edge("List conversations")]}
    connections["List conversations"] = {"main": [edge("Build conversations")]}
    connections["Build conversations"] = {"main": [edge("Conversations done")]}
    connections["Set AI mode"] = {"main": [edge("Mode is bot?")]}
    connections["Mode is bot?"] = {
        "main": [edge("Close escalation (AI)"), edge("AI mode done")]
    }
    connections["Close escalation (AI)"] = {"main": [edge("AI mode done")]}

    # The control lookup now runs before the gate; chat no longer re-runs it.
    connections["Escalation Check"] = {"main": [edge("Load AI control")]}
    connections["Load AI control"] = {"main": [edge("Escalated?")]}
    connections["Load history"] = {"main": [edge("Build chat")]}

    validate(workflow)
    return {"original": original, "updated": workflow}


def validate(workflow: dict[str, Any]) -> None:
    names = {n["name"] for n in workflow["nodes"]}
    if len(names) != len(workflow["nodes"]):
        sys.exit("Duplicate node names")
    for source, outputs in workflow["connections"].items():
        if source not in names:
            sys.exit(f"Connection from unknown node {source!r}")
        for branch in outputs.get("main", []):
            for item in branch or []:
                if item["node"] not in names:
                    sys.exit(
                        f"Connection {source!r} -> unknown node {item['node']!r}"
                    )
    for required in ("Conversations control", "Build conversations",
                     "Set AI mode", "Mode is bot?", "AI mode done"):
        if required not in names:
            sys.exit(f"Missing node {required!r}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    result = build()
    updated = result["updated"]

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup = BACKUP_DIR / f"live_CM_App_API_{WORKFLOW_ID}.json"
    backup.write_text(
        json.dumps(result["original"], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    OUTPUT.write_text(
        json.dumps(updated, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"Backup : {backup}")
    print(f"Updated: {OUTPUT}")
    print("Nodes  :", ", ".join(sorted(n["name"] for n in updated["nodes"])))

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
