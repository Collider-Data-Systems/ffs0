# Family-Layer Multimodal KI Batch [STAGED]

> **GATE:** This is a staged batch of `knowledge_item` objects for the family layer. **NO HG APPLIES HAVE BEEN EXECUTED.** This requires Sam's review and explicit `moos-workspace-ingest` application.

## Staged KIs (moos-diary media)

### KI: The Diary Entries
```json
{
  "type": "knowledge_item",
  "urn": "urn:moos:knowledge_item:moos_diary_entries_batch_01",
  "purpose_slug": "mtdc",
  "source": {
    "channel_urn": "urn:moos:channel:hp-z440.primary",
    "files": [
      "kb/moos-diary/Moos_diary_entry_202604210945.mp4",
      "kb/moos-diary/Moos_diary_entry_202604210945_2.mp4",
      "kb/moos-diary/Moos_diary_entry_202604210945_3.mp4",
      "kb/moos-diary/Moos_diary_entry_202604210945_4.mp4"
    ]
  },
  "content_summary": "Core diary narrative videos from Moos. The sovereign dog establishes the log.",
  "status": "STAGED"
}
```

### KI: Moos Remarks & Talks
```json
{
  "type": "knowledge_item",
  "urn": "urn:moos:knowledge_item:moos_remarks_batch_01",
  "purpose_slug": "mtdc",
  "source": {
    "channel_urn": "urn:moos:channel:hp-z440.primary",
    "files": [
      "kb/moos-diary/Dachshund_Moos_diary_202604210945.mp4",
      "kb/moos-diary/Dachshund_Moos_remarks_202604210945.mp4",
      "kb/moos-diary/Dachshund_Moos_remarks_202604210945_2.mp4",
      "kb/moos-diary/Dachshund_Moos_talks_202604210945.mp4"
    ]
  },
  "content_summary": "Supplemental video remarks and physical evidence of Moos navigating the workspace.",
  "status": "STAGED"
}
```

### KI: The Family Seeds (WhatsApp Media)
```json
{
  "type": "knowledge_item",
  "urn": "urn:moos:knowledge_item:moos_family_seeds_media",
  "purpose_slug": "mtdc",
  "source": {
    "channel_urn": "urn:moos:channel:hp-z440.primary",
    "files": [
      "kb/moos-diary/WhatsApp Video 2026-04-21 at 09.45.32.mp4",
      "kb/moos-diary/WhatsApp_Image_2026-03-20_202604210945.jpeg",
      "kb/moos-diary/WhatsApp_Image_2026-03-25_202604210945.jpeg"
    ]
  },
  "content_summary": "Raw visual artifacts from the family layer (Menno, Lola, Moos) ingested from the phone.",
  "status": "STAGED"
}
```

*Pending Relations:*
- `WF12 provides-kb` from these KIs to the `session:sam.moos-diary` workspace.
- `WF01 owns` from `user:moos` to these KIs.
