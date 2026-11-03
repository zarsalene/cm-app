"""Wire the BotGenius test bot to the real CM App Escalate workflow.

Needs N8N_API_URL and N8N_API_KEY. Backups of both workflows go to n8n/backups/.
Restore: PUT a backup file (name, nodes, connections, settings) back to the same workflow id.
"""
import json
import os
import sys
import urllib.error
import urllib.request

BASE = os.environ['N8N_API_URL'].rstrip('/')
KEY = os.environ['N8N_API_KEY']
SP = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backups')
os.makedirs(SP, exist_ok=True)
ESC = '5EALg4K0DcjgjYCo'
BOT = 'f32N0iDTz5FEz38t'


def call(method, path, body=None):
    data = None if body is None else json.dumps(body, ensure_ascii=False).encode('utf-8')
    req = urllib.request.Request(
        f'{BASE}/api/v1{path}', data=data, method=method,
        headers={'X-N8N-API-KEY': KEY, 'Content-Type': 'application/json; charset=utf-8'})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print('HTTP', e.code, e.read().decode('utf-8')[:400])
        sys.exit(1)


def put(wid, wf):
    body = {k: wf[k] for k in ('name', 'nodes', 'connections', 'settings')}
    return call('PUT', f'/workflows/{wid}', body)


esc = call('GET', f'/workflows/{ESC}')
bot = call('GET', f'/workflows/{BOT}')
for name, wf in (('escalate', esc), ('botgenius', bot)):
    with open(os.path.join(SP, f'backup_{name}_{wf["id"]}.json'), 'w', encoding='utf-8') as f:
        json.dump(wf, f, ensure_ascii=False)
print('backups written')

# 1. Escalate: accept any letter case for the platform ("Facebook" -> "facebook").
detect = next(n for n in esc['nodes'] if n['name'] == 'Detect')
old = "const platform = input.platform;"
new = "const platform = String(input.platform || '').toLowerCase();"
assert old in detect['parameters']['jsCode'], 'Detect line not found'
detect['parameters']['jsCode'] = detect['parameters']['jsCode'].replace(old, new, 1)
put(ESC, esc)
print('escalate updated')

# 2. BotGenius: replace the simulator stub by a call to the real escalate workflow.
stub = next(n for n in bot['nodes'] if n['name'] == 'Handoff Check1')
assert stub['type'] == 'n8n-nodes-base.code' and 'Simulator stub' in stub['parameters']['jsCode']
stub['type'] = 'n8n-nodes-base.executeWorkflow'
stub['typeVersion'] = 1.1
stub['parameters'] = {
    'workflowId': {
        '__rl': True, 'value': ESC, 'mode': 'list',
        'cachedResultUrl': f'/workflow/{ESC}', 'cachedResultName': 'CM App Escalate'},
    'options': {},
}
put(BOT, bot)
print('botgenius updated')

# Verify
b2 = call('GET', f'/workflows/{BOT}')
n = next(x for x in b2['nodes'] if x['name'] == 'Handoff Check1')
e2 = call('GET', f'/workflows/{ESC}')
d2 = next(x for x in e2['nodes'] if x['name'] == 'Detect')
print('bot node:', n['type'], n['parameters']['workflowId']['value'], 'active=', b2['active'])
print('escalate active=', e2['active'], 'lowercase fix=', "toLowerCase()" in d2['parameters']['jsCode'])
print('nodes count bot', len(bot['nodes']), '->', len(b2['nodes']))
