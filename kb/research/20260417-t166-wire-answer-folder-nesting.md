# T=166 - Wire answer: folder nesting

> April 17, 2026.
> Answers Q5 from `20260414-t164-wires-come-from.md` section 7.

## Q5

Where do folders go?

## Answer (concrete at T=166)

Folders are modeled as `channel` nodes with `kind=filesystem`.
Nested folders are modeled as sub-channels: a child `channel` points to its parent via optional `parent_channel_urn`.

This is now explicit in ontology v3.6:

- `channel` includes `parent_channel_urn` with note: "sub-channel ... enables filesystem folder structure and nested project boards".
- `channel` already has topology ports (`owned-by` in, `emits` out), so folder trees stay graph-native.

## What the graph currently shows

Live graph has channel roots only (no parent set yet):

- `urn:moos:channel:filesystem.hp-laptop-downloads`
- `urn:moos:channel:board.msd21091969-moos`
- `urn:moos:channel:drive.sam-my-drive`
- `urn:moos:channel:messaging.whatsapp-sam`

All currently have empty `parent_channel_urn`, so topology is flat today.

## Operational rule

Keep relation-first semantics:

- Folder hierarchy is represented by channel-to-channel topology (`owned-by`).
- `parent_channel_urn` is the typed anchor used for ingestion and stable addressing of the parent.
- Files/messages remain emitted artifacts linked to the leaf channel, not children of folders as properties.