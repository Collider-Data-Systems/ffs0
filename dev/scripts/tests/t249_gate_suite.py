import json, sys, urllib.request
sys.stdout.reconfigure(encoding='utf-8')
BASE = 'http://localhost:8899'
K = 'urn:moos:kernel:hp-z440.primary'
TS = '2026-07-08T18:00:00Z'

def post(path, payload):
    req = urllib.request.Request(BASE + path, data=json.dumps(payload).encode(),
                                 headers={'Content-Type': 'application/json'}, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return True, r.read().decode()[:200]
    except urllib.error.HTTPError as e:
        return False, e.read().decode()[:200]

def prop(v, mut='immutable', scope=''):
    return {'value': v, 'mutability': mut, 'authority_scope': scope, 'stratum_origin': 2}

def add(urn, tid, props):
    return {'rewrite_type': 'ADD', 'actor': K, 'node_urn': urn, 'type_id': tid, 'properties': props}

# ---- fixtures (atomic) ----
FIX = [
 add('urn:moos:agent:test.gate', 'agent', {
   'name': prop('gate-test agent'), 'delegate_type': prop('process'),
   'owner_urn': prop('urn:moos:user:sam'), 'created_at': prop(TS),
   'board_id': prop('AGENT-TEST-GATE', 'mutable', 'owner')}),
 add('urn:moos:derivation:persona.gate-test', 'derivation', {
   'name': prop('persona gate-test'), 'created_at': prop(TS),
   'owner_urn': prop('urn:moos:user:sam'),
   'inference_kind': prop('deterministic_rule', 'mutable', 'owner')}),
 add('urn:moos:manifold:gate-test', 'manifold', {
   'name': prop('gate-test manifold'), 'owner_urn': prop('urn:moos:group:sam'), 'created_at': prop(TS)}),
 add('urn:moos:purpose:test.gate', 'purpose', {
   'subject_urn': prop('urn:moos:user:sam'), 'target_state': prop('gates tested'),
   'started_at': prop(TS), 'created_at': prop(TS), 'status': prop('open', 'mutable', 'owner')}),
 add('urn:moos:session:test.gate', 'session', {
   'started_at': prop(TS), 'created_at': prop(TS), 'local_t': prop(0, 'mutable', 'kernel')}),
 add('urn:moos:cal:test.gate', 'calendar_event', {
   'summary': prop('gate test'), 'date': prop('2026-07-08'), 't_day': prop(249),
   'gcal_id': prop('gate-test'), 'color_label': prop('purple'),
   'status': prop('confirmed', 'mutable', 'kernel'), 'created_at': prop(TS)}),
 add('urn:moos:session:20260708.gate-agent-session', 'agent_session', {
   'agent_urn': prop('urn:moos:agent:test.gate'), 't_day': prop(249), 'created_at': prop(TS),
   'role': prop('active', 'mutable', 'owner'), 'status': prop('open', 'mutable', 'kernel')}),
 add('urn:moos:capability:test.gate', 'capability', {
   'scope': prop(['WF19']), 'created_at': prop(TS), 'granted_by_urn': prop('urn:moos:user:sam'),
   'max_rewrites': prop(10, 'mutable', 'owner')}),
]
ok, msg = post('/programs', FIX)
print(('FIXTURES ok' if ok else 'FIXTURES FAILED: ' + msg))
if not ok: sys.exit(1)

def link(rel, src, sp, tgt, tp, wf):
    return {'rewrite_type': 'LINK', 'actor': K, 'relation_urn': rel,
            'src_urn': src, 'src_port': sp, 'tgt_urn': tgt, 'tgt_port': tp, 'rewrite_category': wf}
def mut(tgt, field, val, wf=None):
    e = {'rewrite_type': 'MUTATE', 'actor': K, 'target_urn': tgt, 'field': field, 'new_value': val}
    if wf: e['rewrite_category'] = wf
    return e

GATES = [
 ('G01 presents-as agent->derivation ACCEPT', True,
  link('urn:moos:rel:g01', 'urn:moos:agent:test.gate', 'presents-as', 'urn:moos:derivation:persona.gate-test', 'presented-by', 'WF19')),
 ('G02 presents-as agent->purpose REJECT (tgt type)', False,
  link('urn:moos:rel:g02', 'urn:moos:agent:test.gate', 'presents-as', 'urn:moos:purpose:test.gate', 'presented-by', 'WF19')),
 ('G03 presents-as session->derivation REJECT (src type)', False,
  link('urn:moos:rel:g03', 'urn:moos:session:test.gate', 'presents-as', 'urn:moos:derivation:persona.gate-test', 'presented-by', 'WF19')),
 ('G04 spans manifold->purpose ACCEPT', True,
  link('urn:moos:rel:g04', 'urn:moos:manifold:gate-test', 'spans', 'urn:moos:purpose:test.gate', 'spanned-by', 'WF18')),
 ('G05 spans manifold->agent REJECT (tgt type)', False,
  link('urn:moos:rel:g05', 'urn:moos:manifold:gate-test', 'spans', 'urn:moos:agent:test.gate', 'spanned-by', 'WF18')),
 ('G06 spans purpose->purpose REJECT (src type)', False,
  link('urn:moos:rel:g06', 'urn:moos:purpose:test.gate', 'spans', 'urn:moos:purpose:test.gate', 'spanned-by', 'WF18')),
 ('G07 MUTATE session.status via WF19 REJECT (g6a pruned)', False,
  mut('urn:moos:session:test.gate', 'status', 'closed', 'WF19')),
 ('G08 MUTATE session.local_t via WF19 ACCEPT (kept)', True,
  mut('urn:moos:session:test.gate', 'local_t', 1, 'WF19')),
 ('G09 MUTATE calendar_event.status via WF07 ACCEPT (Copilot save)', True,
  mut('urn:moos:cal:test.gate', 'status', 'cancelled', 'WF07')),
 ('G10 MUTATE agent_session.role via WF07 ACCEPT (Lydon save)', True,
  mut('urn:moos:session:20260708.gate-agent-session', 'role', 'listening', 'WF07')),
 ('G11 MUTATE agent.board_id via WF02 ACCEPT (g6b adopted)', True,
  mut('urn:moos:agent:test.gate', 'board_id', 'AGENT-TEST-GATE-2', 'WF02')),
 ('G12 MUTATE capability.max_rewrites via WF02 ACCEPT (g6b adopted)', True,
  mut('urn:moos:capability:test.gate', 'max_rewrites', 20, 'WF02')),
 ('G13 MUTATE session.seat_role via WF19 REJECT (g6a pruned)', False,
  mut('urn:moos:session:test.gate', 'seat_role', 'occupier', 'WF19')),
 ('G14 ADD ki source_type=diary ACCEPT (f1 trued)', True,
  add('urn:moos:ki:diary.gate-test', 'knowledge_item', {
    'title': prop('gate'), 'source_url': prop('file:///gate'), 'source_type': prop('diary'),
    'language': prop('en'), 'retrieved_at': prop(TS), 'created_at': prop(TS),
    'substrate': prop('external-channel', scope='kernel'),
    'substrate_anchor_urn': prop('urn:moos:channel:local.moos-footage'),
    'summary': prop('gate', 'mutable'), 'status': prop('raw', 'mutable', 'kernel')})),
 ('G15 second presents-as same agent REJECT/ACCEPT? (at-most-one is doctrine, not validator — expect ACCEPT, records gap)', True,
  link('urn:moos:rel:g15', 'urn:moos:agent:test.gate', 'presents-as', 'urn:moos:derivation:persona.gate-test', 'presented-by', 'WF19')),
]

passed = failed = 0
for name, expect_ok, env in GATES:
    ok, msg = post('/rewrites', env)
    verdict = 'PASS' if ok == expect_ok else 'FAIL'
    if verdict == 'PASS': passed += 1
    else: failed += 1
    tail = '' if ok else ' | ' + msg.replace('\n', ' ')[:110]
    print(f'{verdict}  {name}{tail}')
print(f'\n== {passed} pass / {failed} fail of {len(GATES)}')
