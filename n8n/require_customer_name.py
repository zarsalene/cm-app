"""Make the customer name as "required" as the platforms allow.

Changes, on the n8n server:
  BotGenius / Sender name              : retry the Facebook Graph lookup 3 times (1 s apart).
  WhatsApp chatbot v3 / Prepare Handoff Input1 : read contacts[0].profile.name without throwing.
  CM App Escalate / Detect             : add displayName = name, else "Client <channel> …<last 4>"
                                         (same label as the app). customerName stays raw.
  CM App Escalate / FCM Push, WA CM Alert : use displayName.

Escalation never blocks on a missing name.
Needs N8N_API_URL and N8N_API_KEY. Backups go to n8n/backups/. Safe to run twice.
Run: python -I -X utf8 n8n/require_customer_name.py
"""
import json
import os
import sys
import urllib.error
import urllib.request

ESC = '5EALg4K0DcjgjYCo'
BOT = 'f32N0iDTz5FEz38t'
WA = '9K2MxD4AN2Pujobo'

WA_NAME_OLD = "customerName: $('WhatsApp Trigger1').item.json.contacts[0].profile.name,"
WA_NAME_NEW = ("customerName: $('WhatsApp Trigger1').item.json.contacts?.[0]?.profile?.name || '',")

DETECT_OLD = "const customerName = /^facebook user$/i.test(rawName) ? '' : rawName;"
DETECT_NEW = DETECT_OLD + r"""
// Same label as the app (Strings.customerLabel) when the platform gave no name.
const displayName = customerName
  || `Client ${platform === 'whatsapp' ? 'WhatsApp' : 'Facebook'} …${String(userId || '').slice(-4)}`;"""

DETECT_OUT_OLD = "customerName, cleanOutput, cause, customerMessage, pushBody } }];"
DETECT_OUT_NEW = "customerName, displayName, cleanOutput, cause, customerMessage, pushBody } }];"

PUSH_OLD = "title: ($('Detect').first().json.customerName || 'Client') + ' ('"
PUSH_NEW = "title: $('Detect').first().json.displayName + ' ('"

WA_OLD = "${$('Detect').first().json.customerName || ('Client ' + $('Detect').first().json.userId)}"
WA_NEW = "${$('Detect').first().json.displayName}"


def replace_once(text, old, new, what):
    if new in text:
        print(f'  already done: {what}')
        return text
    assert old in text, f'not found: {what}'
    return text.replace(old, new, 1)


def main():
    base = os.environ['N8N_API_URL'].rstrip('/')
    key = os.environ['N8N_API_KEY']
    sp = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backups')
    os.makedirs(sp, exist_ok=True)

    def call(method, path, body=None):
        data = None if body is None else json.dumps(body, ensure_ascii=False).encode('utf-8')
        req = urllib.request.Request(
            f'{base}/api/v1{path}', data=data, method=method,
            headers={'X-N8N-API-KEY': key, 'Content-Type': 'application/json; charset=utf-8'})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            print('HTTP', e.code, e.read().decode('utf-8')[:400])
            sys.exit(1)

    def put(wid, wf):
        # the public API rejects newer settings keys (availableInMCP, binaryMode)
        wf['settings'] = {k: v for k, v in wf['settings'].items()
                          if k not in ('availableInMCP', 'binaryMode')}
        return call('PUT', f'/workflows/{wid}',
                    {k: wf[k] for k in ('name', 'nodes', 'connections', 'settings')})

    def node(wf, name):
        return next(n for n in wf['nodes'] if n['name'] == name)

    wfs = {wid: call('GET', f'/workflows/{wid}') for wid in (ESC, BOT, WA)}
    for wid, wf in wfs.items():
        with open(os.path.join(sp, f'backup_name_required_{wid}.json'), 'w', encoding='utf-8') as f:
            json.dump(wf, f, ensure_ascii=False)
    print('backups written')

    sender = node(wfs[BOT], 'Sender name')
    sender.update(retryOnFail=True, maxTries=3, waitBetweenTries=1000)

    wa_prep = node(wfs[WA], 'Prepare Handoff Input1')
    wa_prep['parameters']['jsCode'] = replace_once(
        wa_prep['parameters']['jsCode'], WA_NAME_OLD, WA_NAME_NEW, 'WhatsApp name read')

    esc = wfs[ESC]
    det = node(esc, 'Detect')
    code = replace_once(det['parameters']['jsCode'], DETECT_OLD, DETECT_NEW, 'detect displayName')
    det['parameters']['jsCode'] = replace_once(code, DETECT_OUT_OLD, DETECT_OUT_NEW, 'detect output')
    fcm = node(esc, 'FCM Push')
    fcm['parameters']['jsonBody'] = replace_once(fcm['parameters']['jsonBody'], PUSH_OLD, PUSH_NEW, 'push title')
    wa_alert = node(esc, 'WA CM Alert')
    wa_alert['parameters']['textBody'] = replace_once(wa_alert['parameters']['textBody'], WA_OLD, WA_NEW, 'WA alert name')

    for wid in (ESC, BOT, WA):
        put(wid, wfs[wid])
        print('updated', wid)

    for wid in (ESC, BOT, WA):
        w = call('GET', f'/workflows/{wid}')
        print(wid, 'active =', w['active'])
    e2 = call('GET', f'/workflows/{ESC}')
    print('displayName in detect:', 'displayName' in node(e2, 'Detect')['parameters']['jsCode'])
    b2 = call('GET', f'/workflows/{BOT}')
    print('sender retry:', node(b2, 'Sender name').get('retryOnFail'))


if __name__ == '__main__':
    main()
