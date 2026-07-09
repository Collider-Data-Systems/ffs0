"""t250 Wolfram re-seat gate — throwaway 4.0.1 kernel (:8899, in-memory).

Fixture replicates the live :8000 substrate around session:sam.kernel-proper,
then applies dev/scripts/ops/t250-round1/wolfram-reseat.program.json (the SAME
file the live apply uses) and verifies the fold both directions. Also probes
the g6a expectation: session.text MUTATE under WF19 must REJECT (scope is
[local_t, context_urn] post-4.0.1).

Companion pattern: t249_gate_suite_phase2.py.
"""
import json, sys, urllib.request, pathlib
sys.stdout.reconfigure(encoding='utf-8')
BASE = 'http://localhost:8899'
K = 'urn:moos:kernel:hp-z440.primary'
TS = '2026-07-09T08:10:00Z'
ROOT = pathlib.Path(__file__).resolve().parents[2]  # ffs0/dev
PROGRAM = ROOT / 'scripts' / 'ops' / 't250-round1' / 'wolfram-reseat.program.json'


def post(path, payload):
    req = urllib.request.Request(BASE + path, data=json.dumps(payload).encode(),
                                 headers={'Content-Type': 'application/json'}, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return True, r.read().decode()[:300]
    except urllib.error.HTTPError as e:
        return False, e.read().decode()[:300]


def get(path):
    try:
        with urllib.request.urlopen(BASE + path, timeout=10) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError:
        return None


def prop(v, mut='immutable', scope=''):
    return {'value': v, 'mutability': mut, 'authority_scope': scope, 'stratum_origin': 2}


def add(urn, tid, props):
    return {'rewrite_type': 'ADD', 'actor': K, 'node_urn': urn, 'type_id': tid, 'properties': props}


def link(rel, src, sp, tgt, tp, wf):
    return {'rewrite_type': 'LINK', 'actor': K, 'relation_urn': rel,
            'src_urn': src, 'src_port': sp, 'tgt_urn': tgt, 'tgt_port': tp, 'rewrite_category': wf}


# --- Fixture: live-:8000 substrate around the Wolfram seat ---
FIX = [
 add('urn:moos:user:sam', 'user', {'name': prop('sam'), 'created_at': prop(TS)}),
 add('urn:moos:agent:claude-code.hp-z440', 'agent', {
   'name': prop('claude-code.hp-z440'), 'delegate_type': prop('ide'),
   'owner_urn': prop('urn:moos:user:sam'), 'created_at': prop(TS),
   'status': prop('idle', 'mutable', '')}),
 add('urn:moos:session:sam.kernel-proper', 'session', {
   'owner_urn': prop('urn:moos:user:sam'), 'started_at': prop(TS),
   'text': prop('fixture text (stale, replicates live)', 'mutable', 'owner'),
   'local_t': prop(10, 'mutable', 'kernel'),
   'context_urn': prop('urn:moos:system_instruction:persona.stephen-wolfram', 'mutable', 'kernel')}),
 add('urn:moos:derivation:persona.wolfram', 'derivation', {
   'name': prop('wolfram = Phi(sam.kernel-implementation-z440) — fixture'),
   'owner_urn': prop('urn:moos:user:sam'), 'created_at': prop(TS),
   'inference_kind': prop('deterministic_rule', 'mutable', 'owner')}),
 link('urn:moos:rel:sam.governs.claude-code-hp-z440',
      'urn:moos:user:sam', 'governs', 'urn:moos:agent:claude-code.hp-z440', 'governed-by', 'WF02'),
 link('urn:moos:rel:session.sam.kernel-proper.has-occupant.agent.claude-code-hp-z440',
      'urn:moos:session:sam.kernel-proper', 'has-occupant',
      'urn:moos:agent:claude-code.hp-z440', 'is-occupant-of', 'WF19'),
 link('urn:moos:rel:t249.wolfram.presents-as',
      'urn:moos:agent:claude-code.hp-z440', 'presents-as',
      'urn:moos:derivation:persona.wolfram', 'presented-by', 'WF19'),
]
ok, msg = post('/programs', FIX)
print('FIXTURES', 'ok' if ok else 'FAILED: ' + msg)
if not ok:
    sys.exit(1)

# --- Gate 1: the actual re-seat program (same JSON as live apply), atomic ---
envelopes = json.loads(PROGRAM.read_text(encoding='utf-8'))['envelopes']
ok, msg = post('/programs', envelopes)
print('RESEAT-BATCH', 'ACCEPT ok' if ok else 'REJECTED: ' + msg)
if not ok:
    sys.exit(1)

fails = []

# --- Verify fold both directions ---
sess_rels = get('/state/relations/src/urn:moos:session:sam.kernel-proper') or []
occ = [r for r in sess_rels if r['src_port'] == 'has-occupant']
if len(occ) == 1 and occ[0]['tgt_urn'] == 'urn:moos:agent:vscode.hp-laptop.wolfram':
    print('V1 has-occupant → vscode.hp-laptop.wolfram (exactly one) ok')
else:
    fails.append(f'V1 has-occupant wrong: {occ}')

pers = get('/state/relations/tgt/urn:moos:derivation:persona.wolfram') or []
pres = [r for r in pers if r['tgt_port'] == 'presented-by']
if len(pres) == 1 and pres[0]['src_urn'] == 'urn:moos:agent:vscode.hp-laptop.wolfram':
    print('V2 presents-as → from vscode.hp-laptop.wolfram (exactly one) ok')
else:
    fails.append(f'V2 presents-as wrong: {pres}')

old_tgt = get('/state/relations/tgt/urn:moos:agent:claude-code.hp-z440') or []
old_occ = [r for r in old_tgt if r['tgt_port'] == 'is-occupant-of']
old_gov = [r for r in old_tgt if r['tgt_port'] == 'governed-by']
old_src = get('/state/relations/src/urn:moos:agent:claude-code.hp-z440') or []
old_pres = [r for r in old_src if r['src_port'] == 'presents-as']
if not old_occ and not old_pres and len(old_gov) == 1:
    print('V3 old principal: zero occupancy, zero presents-as, still governed ok')
else:
    fails.append(f'V3 old principal residue: occ={old_occ} pres={old_pres} gov={len(old_gov)}')

new_tgt = get('/state/relations/tgt/urn:moos:agent:vscode.hp-laptop.wolfram') or []
new_gov = [r for r in new_tgt if r['tgt_port'] == 'governed-by' and r['src_urn'] == 'urn:moos:user:sam']
if len(new_gov) == 1:
    print('V4 new principal governed by user:sam ok')
else:
    fails.append(f'V4 governs wrong: {new_gov}')

node = get('/state/nodes/urn:moos:agent:vscode.hp-laptop.wolfram')
model = node['properties'].get('model', {}).get('value') if node else None
if model == 'Kimi K2.7 Code':
    print('V5 model property = Kimi K2.7 Code ok')
else:
    fails.append(f'V5 model wrong: {model}')

# --- Gate 2 (probe, expected REJECT): session.text MUTATE under WF19 (g6a) ---
mut = {'rewrite_type': 'MUTATE', 'actor': K,
       'target_urn': 'urn:moos:session:sam.kernel-proper',
       'field': 'text', 'new_value': 'trued-up text', 'rewrite_category': 'WF19'}
ok, msg = post('/rewrites', mut)
if ok:
    print('G2 text-MUTATE unexpectedly ACCEPTED — g6a expectation wrong; live batch may include true-up')
else:
    print('G2 text-MUTATE REJECTED as expected (g6a):', msg[:120])

if fails:
    print('\nFAILURES:')
    for f in fails:
        print(' -', f)
    sys.exit(1)
print('\nALL GATES GREEN — re-seat program safe for live :8000')
