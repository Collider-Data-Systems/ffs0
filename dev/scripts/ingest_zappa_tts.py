import json
import urllib.request
import urllib.error
import datetime

now = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

files = [
    {
        "slug": "audio.zappa-audy-letter-nl",
        "file": "zappa_audy_letter_nl_full.mp3",
        "title": "Zappa explains the situation to Audy (NL audio)",
        "lang": "nl"
    },
    {
        "slug": "audio.zappa-lola-letter-en",
        "file": "zappa_lola_letter_en_full.mp3",
        "title": "Zappa explains the situation to Lola (EN audio)",
        "lang": "en"
    },
    {
        "slug": "audio.zappa-narrator-cut-en",
        "file": "zappa_narrator_cut_en.mp3",
        "title": "The Narrator's Cut (EN audio)",
        "lang": "en"
    }
]

envelopes = []

for item in files:
    node_urn = f"urn:moos:ki:{item['slug']}"
    # ADD envelope
    envelopes.append({
        "rewrite_type": "ADD",
        "actor": "urn:moos:agent:antigravity.hp-z440",
        "session_urn": "urn:moos:session:sam.moos-diary",
        "node_urn": node_urn,
        "type_id": "knowledge_item",
        "properties": {
            "title":        {"value": item["title"], "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "source_url":   {"value": f"file:///D:/HPZ440/ffs0/tmp/tts-probe/{item['file']}", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "source_type":  {"value": "audio", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "language":     {"value": item["lang"], "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "created_at":   {"value": now, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "retrieved_at": {"value": now, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "status":       {"value": "raw", "mutability": "mutable", "authority_scope": "kernel", "stratum_origin": 2},
            "ingest_actor": {"value": "urn:moos:agent:antigravity.hp-z440", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "media_kind":   {"value": "audio", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "media_meta":   {"value": "{}", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "substrate":    {"value": "external-channel", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "substrate_anchor_urn": {"value": "urn:moos:channel:local.moos-footage", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
        }
    })
    # LINK envelope (WF12 provides-kb)
    envelopes.append({
        "rewrite_type": "LINK",
        "actor": "urn:moos:agent:antigravity.hp-z440",
        "session_urn": "urn:moos:session:sam.moos-diary",
        "relation_urn": f"urn:moos:rel:{item['slug']}.provides-kb",
        "src_urn": "urn:moos:channel:local.moos-footage",
        "src_port": "provides-kb",
        "tgt_urn": node_urn,
        "tgt_port": "kb-source",
        "rewrite_category": "WF12"
    })

req = urllib.request.Request("http://localhost:8000/programs", data=json.dumps(envelopes).encode('utf-8'), headers={'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(req) as response:
        print("Success:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code} - {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
