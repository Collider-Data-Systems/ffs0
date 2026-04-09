# ANTIGRAVITY.md

This is the primary directive file for Google Antigravity IDE when operating in the `ffs0` repository.

## 1. Repository Purpose: `ffs0` (The Factory)
This is a **Personal portable private workspace**. It acts as the intellectual and configurational base across multiple workstations (e.g. Z440, HP Laptop).
- **This is NOT the kernel code repository.** The main application runtime (`mo:os`) resides elsewhere (typically ignored under the `moos/` subdirectory). 
- Do not make kernel-code assumptions. This repo contains ideas, knowledge (KB), design notes (`dev/design`), environment setups, and secrets.

## 2. Core Operational Rules
1. **Lightweight Filesystem Modding:** Keep `ffs0` lightweight. We write docs, specifications, and configurations here. Heavy compute logic or binary builds belong in `moos/`.
2. **Domain Expertise is Mandatory:** `mo:os` utilizes a highly strict mathematical nomenclature (Wolfram Hypergraphs, Spivak Operads, HDC). The canonical reference is `kb/research/20260408-foundation-t158.md`. For domain reasoning, consult the moos-domain-expert SKILL.md on the active workstation's Claude Desktop config.
3. **Rewrite-First Semantics:** The architecture operates via an append-only causal graph: `state(t) = fold(log[0..t])`. Four operations only: ADD, LINK, MUTATE, UNLINK. Do not default to typical "bag-of-fields" JSON modeling. Look for `node`, `relation`, `port`, and `operad` types. Use only sanctioned nomenclature from foundation §2. Rewrite categories: WF01-WF18.
4. **Secret Binding Surface:** The `secrets/` directory (`api_keys.env`, `gmail_credentials.json`, etc.) manages authoritative secrets and config-drifts.

## 3. Recommended Workflows
If you must interact with the runtime `mo:os`, always check if `./moos` exists. Workflows to fetch, sync, or validate state should respect this boundary.
