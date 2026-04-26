import json

base_path = "file:///D:/HPZ440/ffs0/kb/moos-diary/"
channel_urn = "urn:moos:channel:local.moos-footage"

videos = [
    ("Dachshund_Moos_diary_202604210945.mp4", "Another day, another existential crisis brought to you by Sam, the alleged master of this operation..."),
    ("Dachshund_Moos_remarks_202604210945.mp4", "Journal Entry, T=171. Day, ya know, just another Tuesday or somethin’..."),
    ("Dachshund_Moos_remarks_202604210945_2.mp4", "Puppy Log, Stardate: November 6, 2026, S4 Ingestion T=171..."),
    ("Dachshund_Moos_talks_202604210945.mp4", "Alright, another day, another existential crisis for a fella just tryin' to live his best life..."),
    ("Moos_diary_entry_202604210945.mp4", "Alright, Moos, let's get this over with. Another day, another staredown with the Big Dummy..."),
    ("Moos_diary_entry_202604210945_2.mp4", "So, another day, another performance review from my prime viewing spot..."),
    ("Moos_diary_entry_202604210945_3.mp4", "Another day, another existential crisis brought on by the big galoot I call 'my human.'..."),
    ("Moos_diary_entry_202604210945_4.mp4", "Oy, another night, another human existential crisis. I was parked up on the couch, right?..."),
    ("WhatsApp Video 2026-04-21 at 09.45.32.mp4", "WhatsApp video context...")
]

jpegs = [
    ("WhatsApp_Image_2026-03-20_202604210945.jpeg", "Photo of Moos on a white blanket..."),
    ("WhatsApp_Image_2026-03-25_202604210945.jpeg", "Photo of Moos curled up from behind...")
]

markdowns = [
    ("t171-batch-ingestion.md", "Batch Moos Diary Ingestion (T=171)..."),
    ("README.md", "Moos diary README documentation...")
]

envelopes = []

def create_add(slug, title, source_type, media_kind, content, filename):
    # Only keep 7 videos if requested, but list has 9 total. 
    # Let's just create them all and let the kernel accept them.
    return {
        "rewrite_type": "ADD",
        "actor": "urn:moos:agent:antigravity.hp-z440",
        "session_urn": "urn:moos:session:sam.moos-diary",
        "node_urn": f"urn:moos:ki:{source_type}.{slug}",
        "type_id": "knowledge_item",
        "properties": {
            "title": {"value": title, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "source_url": {"value": base_path + filename, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "source_type": {"value": source_type, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "media_kind": {"value": media_kind, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "content": {"value": content, "mutability": "mutable", "authority_scope": "", "stratum_origin": 2},
            "substrate": {"value": "external-channel", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
            "substrate_anchor_urn": {"value": channel_urn, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
        }
    }

for filename, content in videos[:7]:
    slug = filename.lower().replace('.mp4', '').replace(' ', '-').replace('_', '-')
    envelopes.append(create_add(slug, filename, "video", "video", content, filename))

for filename, content in jpegs:
    slug = filename.lower().replace('.jpeg', '').replace('_', '-')
    envelopes.append(create_add(slug, filename, "photo", "filesystem", content, filename))

for filename, content in markdowns:
    slug = filename.lower().replace('.md', '').replace('_', '-')
    envelopes.append(create_add(slug, filename, "markdown", "filesystem", content, filename))

with open("D:/HPZ440/ffs0/dev/scripts/ops/t176-v315-ingest.json", "w") as f:
    json.dump({"envelopes": envelopes}, f, indent=2)
