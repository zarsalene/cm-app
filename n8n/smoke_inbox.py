"""End-to-end smoke test for the unified inbox backend.

Creates a throw-away user + session through the n8n Data Tables API, exercises
the public webhook, then deletes both rows. Nothing is left behind.

Usage:
    python -I n8n/smoke_inbox.py
"""

from __future__ import annotations

import hashlib
import json
import os
import secrets
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

API_BASE = os.environ.get("N8N_API_URL", "").rstrip("/")
API_KEY = os.environ.get("N8N_API_KEY", "")
WEBHOOK = os.environ.get(
    "CM_WEBHOOK_URL", "https://n8ntest.microzed.tn/webhook/cm-app"
)
USERS = "qkaHDmKBqzLp7ezj"
SESSIONS = "SOJ0ICbIQdsMOyJP"

if not API_BASE or not API_KEY:
    sys.exit("N8N_API_URL / N8N_API_KEY are required")


def n8n(path: str, method: str = "GET", payload=None):
    body = None if payload is None else json.dumps(payload).encode()
    request = urllib.request.Request(
        f"{API_BASE}/api/v1{path}",
        data=body,
        method=method,
        headers={
            "X-N8N-API-KEY": API_KEY,
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        raw = response.read()
        return json.loads(raw) if raw else None


def webhook(action: str, token: str | None = None, **extra):
    headers = {"Content-Type": "application/json; charset=utf-8"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        WEBHOOK,
        data=json.dumps({"action": action, **extra}).encode(),
        method="POST",
        headers=headers,
    )
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            return response.status, json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        return error.code, json.loads(error.read() or b"{}")


def delete_rows(table: str, column: str, value: str) -> None:
    filters = json.dumps(
        {
            "type": "and",
            "filters": [{"columnName": column, "condition": "eq", "value": value}],
        },
        separators=(",", ":"),
    )
    query = urllib.parse.urlencode(
        {"filter": filters}, quote_via=urllib.parse.quote, safe=""
    )
    n8n(f"/data-tables/{table}/rows/delete?{query}", "DELETE")


def main() -> None:
    username = f"qa_inbox_{secrets.token_hex(4)}"
    password = secrets.token_urlsafe(18)
    password_hash = hashlib.sha256(f"{username}:{password}".encode()).hexdigest()

    inserted = n8n(
        f"/data-tables/{USERS}/rows",
        "POST",
        {"data": [{"username": username, "password_hash": password_hash}],
         "returnType": "all"},
    )
    print(f"temp user: {username} (row {inserted[0]['id']})")
    token = None
    try:
        status, session = webhook("login", username=username, password=password)
        assert status == 200, (status, session)
        token = session["token"]
        print(f"login: {status} token={token[:8]}...")

        status, inbox = webhook("conversations", token)
        assert status == 200, (status, inbox)
        items = inbox.get("items", [])
        print(f"conversations: {status} items={len(items)}")
        assert items, "conversations returned no items"

        for item in items[:5]:
            print(
                "  -",
                item.get("platform"),
                item.get("sender_id"),
                repr(item.get("customer_name")),
                item.get("mode"),
                item.get("status"),
                repr(item.get("last_message"))[:40],
            )

        # A bot-mode conversation without an open escalation exercises the
        # relaxed chat gate (it used to require an escalation row).
        target = next(
            (i for i in items if i["mode"] == "bot" and i["status"] == "active"),
            None,
        )
        if target is None:
            target = next((i for i in items if i["mode"] == "bot"), None)
        assert target is not None, "no bot conversation to test"

        sender = target["sender_id"]
        platform = target["platform"]
        print(f"target: {platform}/{sender} mode={target['mode']} status={target['status']}")

        status, chat = webhook("chat", token, sender_id=sender, platform=platform)
        print(f"chat (bot): {status} mode={chat.get('mode')} name={chat.get('customer_name')!r}")
        assert status == 200, (status, chat)
        assert chat["mode"] == "bot"

        status, toggled = webhook(
            "set_ai_mode", token, sender_id=sender, platform=platform, mode="human"
        )
        print(f"set_ai_mode human: {status} {toggled}")
        assert status == 200 and toggled["mode"] == "human"

        status, chat = webhook("chat", token, sender_id=sender, platform=platform)
        print(f"chat (human): {status} mode={chat.get('mode')}")
        assert status == 200 and chat["mode"] == "human"

        status, toggled = webhook(
            "set_ai_mode", token, sender_id=sender, platform=platform, mode="bot"
        )
        print(f"set_ai_mode bot: {status} {toggled}")
        assert status == 200 and toggled["mode"] == "bot"

        status, chat = webhook("chat", token, sender_id=sender, platform=platform)
        print(f"chat (restored): {status} mode={chat.get('mode')}")
        assert status == 200 and chat["mode"] == "bot"

        status, bad = webhook("set_ai_mode", token, sender_id=sender, platform=platform, mode="nope")
        print(f"set_ai_mode invalid: {status} {bad}")
        assert status == 400

        status, unknown = webhook("chat", token, sender_id="99999999999", platform="whatsapp")
        print(f"chat unknown: {status} {unknown}")
        assert status == 400
    finally:
        if token:
            delete_rows(SESSIONS, "token", token)
            print("temp session deleted")
        delete_rows(USERS, "username", username)
        print("temp user deleted")


if __name__ == "__main__":
    main()
