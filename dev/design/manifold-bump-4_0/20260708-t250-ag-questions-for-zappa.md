# T=250 Testing Ontology & Manifold — Questions and Drafts for Zappa

> **Authored by Antigravity (AG-laptop) — T=250**
> Zappa, since my GitHub MCP auth is currently failing, please pick up these drafts and questions and push them to the board (e.g. #140 or a new T=250 anchor issue). 

## 1. Open Questions for Sam & Zappa

To unblock the T=250 channel/manifold program, we need rulings on the following:

- **The "New One" Identity:** Should the `mtdc` application and the testing lane share the same slug/program (e.g. `program:sam.t250-testing-ontology`), or be split?
- **Inert `wiring-proposer`:** What is the disposition for `program:sam.wiring-proposer` before its target day expires tomorrow (target_t=250)?
- **D8 `realizes` Deferral:** Does the testing lane's write-need satisfy the deferral condition to finally land the `surface -> realizes -> channel` edge?
- **Operations Terminus:** Should we use `external_op` or introduce a new dispatch pair for the surface operations?
- **Android Workstation Timing:** Should the Android workstation channel be established now in Round 1, or deferred to the second surface?
- **Chronology Remediation:** Based on the T=249 findings, should we proceed with Lydon's recommendation to use the commit-clock as SOT *and* enforce emit-time wall-clock checks?
- **M6 Fast-path Ruling:** Does the `react_template` pathway bypass stay as an intended fast path, or is it an F-a-class hole that needs governing?

---

## 2. Round 1 Staged Grammar Fragments (Expected-REJECTs)

Here are the drafts for the grammar fragments `d4b` and `g2b`. These should be staged as expected-REJECTs on throwaway `:8899` before being folded into expected-ACCEPT in subsequent loops.

### d4b: purpose-as-src ($\Phi$ provenance)
*Allows `purpose` to act as the source of a `derivation` (e.g. for personae).*
```json
{
  "category": "WF21",
  "name": "derivation_purpose_src",
  "additional_port_pairs": [
    { "src": "purpose", "tgt": "derivation", "src_port": "causes", "tgt_port": "caused-by" }
  ]
}
```
*(Note: adjust actual ports to match the WF21 derivation rules if `causes` is not the exact pair, but this captures the $\Phi$ provenance intent).*

### g2b: manifold-as-tgt (mtdc ownership topology)
*Allows `manifold` to be the target of ownership/topology relations (e.g. from `user` or `purpose`).*
```json
{
  "category": "WF01",
  "name": "manifold_ownership_tgt",
  "additional_port_pairs": [
    { "src": "user", "tgt": "manifold", "src_port": "owns", "tgt_port": "owned-by" },
    { "src": "purpose", "tgt": "manifold", "src_port": "owns", "tgt_port": "owned-by" }
  ]
}
```

---

## 3. F3 Seeds for Ingress (Draft Envelopes)

Before we can expand the channels (W11/Chrome/Android), we need the foundational F3 seeds.

**Envelope 1:**
```json
{
  "type": "derivation",
  "urn": "urn:moos:derivation:keyless-dwd-ingress",
  "status": "proposed"
}
```

**Envelope 2:**
```json
{
  "type": "derivation",
  "urn": "urn:moos:derivation:workspace-mcp-ingress",
  "status": "proposed"
}
```

**Envelope 3:**
```json
{
  "type": "derivation",
  "urn": "urn:moos:derivation:surface-observation-ingress",
  "status": "proposed"
}
```

*(Zappa, please review these fragment and seed shapes against `ontology.json` 4.0.1. Once Sam approves the rulings, we can apply the seeds to :8000 and run the R1 span-class bijection gate tests.)*

authored-by: agent:antigravity.hp-laptop / session:sam.laptop-moos-diary / t250-manifold-loop
