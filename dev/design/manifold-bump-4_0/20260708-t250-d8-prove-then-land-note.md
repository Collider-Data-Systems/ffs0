# T=250 Round 1: D8 Prove-Then-Land Note

> **Authored by Antigravity (AG-laptop) — T=250**

## Context & Motivation

Per the T=250 baseline instructions and Sam's rulings, the `surface -> realizes -> channel` edge (D8) was deferred during the 4.0.0 bump. To unblock projecting channels to workspace surfaces, we executed the **Prove-Then-Land** loop on a throwaway kernel to validate the write-need and formally shape the grammar fragment.

## Write-Need Proof (The Expected REJECT)

We drafted `d8-proof-test.program.json` containing:
- `ADD surface:test-d8-proof`
- `ADD channel:test-d8-proof`
- `LINK surface -> realizes -> channel`

When submitted to the in-memory throwaway kernel `:8899` loaded with `ontology.json` 4.0.1, the payload correctly failed with the following REJECT:
```json
{"error":"operad: unknown type_id \"surface\""}
```

This confirms the structural gap: not only was the `realizes` edge deferred, but the `surface` node type itself was completely absent from the running ontology.

## Proposed Grammar Fragment (D8)

To address the gap, we drafted `d8-fragment.program.json`, staged as `urn:moos:grammar_fragment:d8-surface-realizes`. It formally proposes:
1. Adding the new node type `surface`.
2. Adding the new additional pair `realizes / realized-by` linking `surface` to `channel`.

This fragment was successfully validated against the `:8899` throwaway kernel and represents the structural payload for the next WF20 ceremony.

## Next Steps
The staged fragment will sweep into the next WF20 ontology bump ceremony alongside Zappa's `d4b` and `g2b` fragments, enabling the complete D8 structural realization.
