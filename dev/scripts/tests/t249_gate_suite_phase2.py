"""t249 gate suite phase-2 — H1 + D4/G2 shapes on a throwaway 4.0.1 kernel (:8899, in-memory).

Run BEFORE any sovereign write (plan: t249 H1+D4/G2). Companion to t249_gate_suite.py (phase-1).
Documents two expected grammar gaps: WF21 purpose-as-src, WF01 manifold-as-tgt.
"""
import json, sys, urllib.request
sys.stdout.reconfigure(encoding='utf-8')
BASE = 'http://localhost:8899'
K = 'urn:moos:kernel:hp-z440.primary'
TS = '2026-07-08T19:30:00Z'

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

def link(rel, src, sp, tgt, tp, wf):
    return {'rewrite_type': 'LINK', 'actor': K, 'relation_urn': rel,
            'src_urn': src, 'src_port': sp, 'tgt_urn': tgt, 'tgt_port': tp, 'rewrite_category': wf}

def unlink(rel):
    return {'rewrite_type': 'UNLINK', 'actor': K, 'relation_urn': rel}

def mut(tgt, field, val, wf=None):
    e = {'rewrite_type': 'MUTATE', 'actor': K, 'target_urn': tgt, 'field': field, 'new_value': val}
    if wf: e['rewrite_category'] = wf
    return e

FIX = [
 add('urn:moos:user:p2', 'user', {'name': prop('p2'), 'created_at': prop(TS)}),
 add('urn:moos:kernel:p2.k', 'kernel', {'version': prop('test'), 'created_at': prop(TS),
   'status': prop('active', 'mutable', 'kernel')}),
 add('urn:moos:ws:p2-legacy', 'workstation', {'hostname': prop('p2'), 'os': prop('windows'),
   'arch': prop('amd64'), 'created_at': prop(TS)}),
 add('urn:moos:agent:p2.a', 'agent', {'name': prop('p2 agent'), 'delegate_type': prop('process'),
   'owner_urn': prop('urn:moos:user:p2'), 'created_at': prop(TS)}),
 add('urn:moos:session:20260403.p2-relic', 'agent_session', {
   'agent_urn': prop('urn:moos:agent:p2.a'), 't_day': prop(154), 'created_at': prop(TS),
   'role': prop('lead', 'mutable', 'owner'), 'status': prop('open', 'mutable', 'kernel')}),
 add('urn:moos:purpose:p2.purpose', 'purpose', {'subject_urn': prop('urn:moos:user:p2'),
   'target_state': prop('tested'), 'started_at': prop(TS), 'created_at': prop(TS),
   'status': prop('open', 'mutable', 'owner')}),
 add('urn:moos:channel:p2.chan', 'channel', {'kind': prop('fs'), 'owner_urn': prop('urn:moos:user:p2'),
   'created_at': prop(TS), 'source_uri': prop('file:///p2'),
   'substrate': prop('external-channel', scope='kernel'),
   'substrate_anchor_urn': prop('urn:moos:workstation:p2-canonical')}),
 add('urn:moos:group:p2.g', 'group', {'name': prop('p2 group'), 'created_at': prop(TS),
   'owner_urn': prop('urn:moos:user:p2')}),
 # legacy owns LINK to re-point (H1-laptop shape)
 link('urn:moos:rel:p2.owns.legacy', 'urn:moos:user:p2', 'owns', 'urn:moos:ws:p2-legacy', 'child', 'WF01'),
]
ok, msg = post('/programs', FIX)
print('FIXTURES', 'ok' if ok else 'FAILED: ' + msg)
if not ok: sys.exit(1)

GATES = [
 # --- H1 shapes ---
 ('H01 ADD canonical workstation (infra-ADD, kernel actor) ACCEPT', True,
  add('urn:moos:workstation:p2-canonical', 'workstation', {'hostname': prop('p2'),
    'os': prop('windows'), 'arch': prop('amd64'), 'created_at': prop(TS)})),
 ('H02 LINK workstation hosts kernel (WF03) ACCEPT', True,
  link('urn:moos:rel:p2.hosts', 'urn:moos:workstation:p2-canonical', 'hosts', 'urn:moos:kernel:p2.k', 'hosted-on', 'WF03')),
 ('H03 re-LINK user owns canonical workstation (WF01) ACCEPT', True,
  link('urn:moos:rel:p2.owns.canonical', 'urn:moos:user:p2', 'owns', 'urn:moos:workstation:p2-canonical', 'child', 'WF01')),
 ('H04 UNLINK legacy owns relation ACCEPT', True,
  unlink('urn:moos:rel:p2.owns.legacy')),
 ('H05 relic close: MUTATE agent_session.status->closed via WF07 ACCEPT', True,
  mut('urn:moos:session:20260403.p2-relic', 'status', 'closed', 'WF07')),
 # --- D4 shapes ---
 ('D01 ADD derivation:persona.* ACCEPT', True,
  add('urn:moos:derivation:persona.p2-test', 'derivation', {'name': prop('persona p2-test'),
    'owner_urn': prop('urn:moos:user:p2'), 'created_at': prop(TS),
    'inference_kind': prop('deterministic_rule', 'mutable', 'owner')})),
 ('D02 presents-as agent->persona-derivation (WF19) ACCEPT', True,
  link('urn:moos:rel:p2.presents-as', 'urn:moos:agent:p2.a', 'presents-as',
       'urn:moos:derivation:persona.p2-test', 'presented-by', 'WF19')),
 ('D03 purpose -WF21 causes-> derivation EXPECTED REJECT (gap d4b: WF21 lacks purpose src)', False,
  link('urn:moos:rel:p2.causes', 'urn:moos:purpose:p2.purpose', 'causes',
       'urn:moos:derivation:persona.p2-test', 'caused-by', 'WF21')),
 # --- G2 shapes ---
 ('G01 ADD manifold ACCEPT', True,
  add('urn:moos:manifold:p2-test', 'manifold', {'name': prop('p2 manifold'),
    'owner_urn': prop('urn:moos:user:p2'), 'created_at': prop(TS)})),
 ('G02 spans manifold->channel (WF18) ACCEPT', True,
  link('urn:moos:rel:p2.spans.chan', 'urn:moos:manifold:p2-test', 'spans',
       'urn:moos:channel:p2.chan', 'spanned-by', 'WF18')),
 ('G03 spans manifold->group (WF18) ACCEPT', True,
  link('urn:moos:rel:p2.spans.group', 'urn:moos:manifold:p2-test', 'spans',
       'urn:moos:group:p2.g', 'spanned-by', 'WF18')),
 ('G04 group -WF01 owns-> manifold EXPECTED REJECT (gap g2b: WF01 lacks manifold tgt)', False,
  link('urn:moos:rel:p2.owns.manifold', 'urn:moos:group:p2.g', 'owns',
       'urn:moos:manifold:p2-test', 'child', 'WF01')),
]

passed = failed = 0
for name, expect_ok, env in GATES:
    ok, msg = post('/rewrites', env)
    verdict = 'PASS' if ok == expect_ok else 'FAIL'
    passed += verdict == 'PASS'; failed += verdict == 'FAIL'
    tail = '' if ok else ' | ' + msg.replace('\n', ' ')[:110]
    print(f'{verdict}  {name}{tail}')
print(f'\n== phase-2: {passed} pass / {failed} fail of {len(GATES)}')
sys.exit(1 if failed else 0)
