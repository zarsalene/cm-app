"""Real customer name + readable escalation message (app, push, WhatsApp alert).

Changes, on the n8n server:
  BotGenius / Prepare Handoff Input1 : customerName from the Facebook "Sender name" node,
                                       customerMessage = the customer's last message.
  CM App Escalate / Detect           : reason = customer message + cause (no AI jargon).
  CM App Escalate / FCM Push         : push title = customer, body = message + cause.
  CM App Escalate / WA CM Alert      : short alert text (the long AI text broke the send).

Needs N8N_API_URL and N8N_API_KEY. Backups go to n8n/backups/. Safe to run twice.
"""
import json
import os
import sys
import urllib.error
import urllib.request

ESC = '5EALg4K0DcjgjYCo'
BOT = 'f32N0iDTz5FEz38t'

# ---- JavaScript pieces (raw strings: backslashes go to n8n untouched) ----
PREP_NAME_OLD = "return {\n"
PREP_NAME_NEW = r"""// Real name from the Facebook profile ("Sender name" node); empty if unavailable.
let customerName = '';
try {
  const s = $('Sender name').first().json;
  customerName = [s.first_name, s.last_name].filter(Boolean).join(' ').trim();
} catch (e) {}

return {
"""
PREP_FIELD_OLD = "customerName: 'Facebook User',"
PREP_FIELD_NEW = "customerName: customerName,\n    customerMessage: String(ask.text || '').slice(0, 300),"

DETECT_NAME_OLD = "const customerName = input.customerName || '';"
DETECT_NAME_NEW = r"""const rawName = String(input.customerName || '').trim();
const customerName = /^facebook user$/i.test(rawName) ? '' : rawName;
const customerMessage = String(input.customerMessage || '').replace(/\s+/g, ' ').trim().slice(0, 160);"""

DETECT_REASON_OLD = """const reason = hasEscalateToken
  ? 'AI decided to escalate (valid end token detected)'
  : tooManyErrors
  ? `${errorCount} consecutive errors`
  : null;"""
DETECT_REASON_NEW = r"""// Cause: the AI's own French summary line when it wrote one, else a short rule-based label.
const summary = (aiOutput.match(/^\s*Le client[^\n{]{5,220}/m) || [''])[0].trim();
const cause = summary
  || (/^\s*📸/.test(aiOutput) ? 'Demande de photo ou vidéo réelle (à filmer par l’équipe)'
  : hasEscalateToken ? 'Le bot demande l’aide d’un conseiller'
  : tooManyErrors ? `Le bot a échoué ${errorCount} fois de suite`
  : '');
const reason = !cause ? null
  : customerMessage ? `Message : « ${customerMessage} »\nCause : ${cause}`
  : `Cause : ${cause}`;
const pushBody = (customerMessage ? `« ${customerMessage} » — ` : '') + cause;"""

DETECT_OUT_OLD = "customerName, cleanOutput } }];"
DETECT_OUT_NEW = "customerName, cleanOutput, cause, customerMessage, pushBody } }];"

PUSH_OLD = ("title: 'Escalade client', body: 'Un client ' + ($('Detect').first().json.platform === 'whatsapp' "
            "? 'WhatsApp' : 'Facebook') + ' attend un CM'")
PUSH_NEW = ("title: ($('Detect').first().json.customerName || 'Client') + ' (' + "
            "($('Detect').first().json.platform === 'whatsapp' ? 'WhatsApp' : 'Facebook') + ')', "
            "body: String($('Detect').first().json.pushBody || '').slice(0, 200)")

WA_TEXT = r"""={{ `🔔 Escalade client (${$('Detect').first().json.platform})
👤 ${$('Detect').first().json.customerName || ('Client ' + $('Detect').first().json.userId)}
💬 « ${$('Detect').first().json.customerMessage} »
❓ ${$('Detect').first().json.cause}

Le bot est désactivé pour ce client. Ouvrez l'app Z-Smart-CM.` }}"""


def replace_once(text, old, new, what):
    if new in text:
        print(f'  already done: {what}')
        return text
    assert old in text, f'not found: {what}'
    return text.replace(old, new, 1)


def patch_detect(code):
    code = replace_once(code, DETECT_NAME_OLD, DETECT_NAME_NEW, 'detect name/message')
    code = replace_once(code, DETECT_REASON_OLD, DETECT_REASON_NEW, 'detect reason')
    return replace_once(code, DETECT_OUT_OLD, DETECT_OUT_NEW, 'detect output')


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
        return call('PUT', f'/workflows/{wid}',
                    {k: wf[k] for k in ('name', 'nodes', 'connections', 'settings')})

    def node(wf, name):
        return next(n for n in wf['nodes'] if n['name'] == name)

    esc = call('GET', f'/workflows/{ESC}')
    bot = call('GET', f'/workflows/{BOT}')
    for name, wf in (('escalate2', esc), ('botgenius2', bot)):
        with open(os.path.join(sp, f'backup_{name}_{wf["id"]}.json'), 'w', encoding='utf-8') as f:
            json.dump(wf, f, ensure_ascii=False)
    print('backups written')

    prep = node(bot, 'Prepare Handoff Input1')
    code = replace_once(prep['parameters']['jsCode'], PREP_NAME_OLD, PREP_NAME_NEW, 'name lookup')
    prep['parameters']['jsCode'] = replace_once(code, PREP_FIELD_OLD, PREP_FIELD_NEW, 'customerName field')

    det = node(esc, 'Detect')
    det['parameters']['jsCode'] = patch_detect(det['parameters']['jsCode'])
    fcm = node(esc, 'FCM Push')
    fcm['parameters']['jsonBody'] = replace_once(fcm['parameters']['jsonBody'], PUSH_OLD, PUSH_NEW, 'push title/body')
    node(esc, 'WA CM Alert')['parameters']['textBody'] = WA_TEXT

    put(ESC, esc)
    print('escalate updated')
    put(BOT, bot)
    print('botgenius updated')

    b2 = call('GET', f'/workflows/{BOT}')
    e2 = call('GET', f'/workflows/{ESC}')
    print('bot active=', b2['active'], 'escalate active=', e2['active'])
    print('name lookup in bot:', 'Sender name' in node(b2, 'Prepare Handoff Input1')['parameters']['jsCode'])
    print('new reason in detect:', 'pushBody' in node(e2, 'Detect')['parameters']['jsCode'])


if __name__ == '__main__':
    main()
