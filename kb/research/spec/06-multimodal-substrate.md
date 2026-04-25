# §6 Multimodal Substrate

> Architecture Specification §6 — Multimodal Substrate Foundation
> Author: `agent:antigravity.hp-z440` (Moos-diary persona)
> Derived from: `urn:moos:derivation:moos.section-06-multimodal-substrate-foundation`

## 6.1 Encoder as Functor
Following the categorical formalism of **Karpathy §1**, we frame the multimodal encoding process as a functor mapping from the category of perceptual artifacts (images, video, audio living on the host file system) to the internal categorical substrate of `mo:os` (the hypergraph). 
This links directly to the concept of the multimodal-encoder-as-functor, where embeddings form an intrinsic part of the semantic LLM substrate (bridging with **Karpathy §10**). 

## 6.2 The File System as External Substrate
Multimodal artifacts (the 8 videos, 2 jpegs, 2 md files currently in active ingest) reside on the local Z440 `Pictures` and `Videos` folders. They are effectively bound to the HG via the `external-channel` substrate property. The physical FS acts as the locus of truth, while `knowledge_item` nodes maintain the graph-resident embedding projection and perceptual metadata (`duration_s`, `perceptual_hash`, etc.).

## 6.3 Multimodal Ingestion Pipelines
Through `moos-multimodal-ingest`, artifacts are broken down by grain:
- **Photos**: Per-item ingestion with perceptual hashing.
- **Videos/Screen Captures**: Keyframe/frame-level umbrella mapping.
- **Audio**: Segment-based transcription chunks.

This pipeline enforces that visual streams are not merely dead-linked, but parsed for narrative/semantic significance to be woven into the overarching Diary continuity.

## 6.4 Antigravity Z440 Native Capabilities
The `antigravity.hp-z440` seat holds native access to visual streams. Without invoking external translation binaries, the IDE driver can cross the sandbox boundary to directly observe visual outputs, Labs Flow renders, and FS-resident imagery. This is the bedrock of the "Moos-dachshund" multimodal persona: perceiving the workstation environment directly.
