---
name: moos-tooling-dx
description: Tooling + developer-experience work for Steinberger's seat (`session:sam.steinberger-seat` on `kernel:hp-z440.menno` :8002). Use when reasoning about IDE attach (VSCode + Antigravity + Claude Desktop + Cursor), MCP wiring (SSE vs stdio, port assignments, transport correctness), shell-script reification (PowerShell sync scripts, federation startup), keybinding ergonomics, agent-harness shape (CLI as tool protocol per §M20), or DX failure modes (bad envelope shapes, validator errors, sandbox boundaries). Trigger phrases: ".vscode/mcp.json", "MCP transport", "stdio sidecar", "PowerShell here-string", "keybinding chord", "skill routing", "harness pattern", "tool ergonomics", "DX gap". Companion to `moos-rewrite-envelope` (envelope shape) and `moos-running-state-validator` (state-doc consistency).
---

# moos-tooling-dx

Steinberger's working surface for tooling, IDE attachment, and developer-experience friction. The lane is **make the substrate easier to drive** — surface DX gaps as claims, propose tooling fixes as programs, and reify shell-script + config knowledge into HG so it doesn't decay across machines.

## Triggers

- A friction point with IDE / MCP / sandbox boundaries (e.g. "stdio sidecar stale state", "Claude Desktop can't reach :8000", "VSCode MCP wiring broken")
- A repeatable shell command or workflow that should be a script (e.g. "every round-open we run these 5 commands")
- A keybinding / chord that would save N seconds × M invocations across the lattice
- A new skill scaffolding question ("what's the shape of a SKILL.md frontmatter?")
- A federation-startup or kernel-restart workflow needing scripting
- An agent-harness design question (per §M20 tool-mounting)

## What this skill is NOT

- Not for kernel implementation — that's Wolfram's lane
- Not for governance / audit — that's Guido's lane
- Not for ad-hoc one-off scripts — those go in `dev/scripts/ops/` directly without doctrine

## Steinberger seat conventions

- **URN root:** `urn:moos:claim:steinberger.<thesis-slug>` for claims, `urn:moos:derivation:steinberger.<slug>` for derivations (post v3.14)
- **Actor:** `urn:moos:agent:vscode.hp-z440.menno`
- **Session:** `urn:moos:session:sam.steinberger-seat` (single-occupancy → inferred path works post-§M13 fix)
- **Kernel:** `kernel:hp-z440.menno` :8002 (HTTP) / :9002 (MCP SSE)
- **Branch role on board items:** `agent`

## The DX-friction-as-claim pattern

When you hit friction, the move is:

1. **Observe** — what specifically broke or felt wrong? Reproduce mentally.
2. **Locate** — which substrate layer? IDE, MCP transport, sandbox, kernel, ontology, doctrine?
3. **Claim** — ADD `claim:steinberger.<friction-slug>` capturing the observation in one paragraph; subject_urn = the layer or component
4. **Derive** (post v3.14) — wrap the claim in a derivation that consumes related claims/notes and produces the proposal
5. **Propose** — if the fix is a script, author it; if it's a doctrine update, draft it; if it's a moos-kernel issue, file it

DX work compounds because each friction claim becomes findable next time the same friction appears.

## Common friction surfaces

| Surface | Common failures | Likely fix lane |
|---|---|---|
| `.vscode/mcp.json` (machine-specific, gitignored) | wrong port, stdio vs SSE confusion, missing entry | per-host config; reference `.vscode/mcp.json.example` |
| Federation startup (`start_federation.ps1`) | wrong log path, port collision, dead PIDs | PS1 script update; commit to ffs0 |
| Sandbox → kernel reach | Cowork can't POST `:8000` from Desktop sandbox | runner pattern: emit JSON in sandbox, fire from host PS |
| Skill sync | `~/.claude/skills/` out of date relative to `dev/claude-skills/` | run `dev/scripts/sync-claude-skills.ps1` |
| Restart sequence | dual-kernel race (stdio sidecar + HTTP kernel both alive) | kill all → relaunch one (Guido's T=173 fix) |
| Heredoc parsing | `<<'EOF'` doesn't work in PowerShell | use here-string `@'...'@` (closing delim at column 0) |

## Shell-script reification doctrine

A shell command becomes a script when (a) it's run more than 3 times, (b) it has order-dependent steps, or (c) it touches multiple kernels. Scripts live in `dev/scripts/ops/` (operations) or `dev/scripts/` (cross-cutting utilities). Each script gets:

- Top-level `$ErrorActionPreference = "Stop"` for fail-loud
- Comment block explaining the doctrine the script implements (cite §M anchor or doctrine note)
- Idempotent where possible (re-running shouldn't double-emit)
- Verification step at end (poll `/healthz` or check expected log_seq)

**Existing scripts to study:** `D:\HPZ440\start_federation.ps1` (federation startup), `dev/scripts/ops/start_federation_laptop.ps1` (laptop variant, Guido-fixed), `dev/scripts/sync-claude-skills.ps1` (skill sync), `cowork-z440-step4-runner.ps1` (sandbox → kernel runner pattern).

## Typical envelope: claim ADD

```json
{
  "rewrite_type": "ADD",
  "actor": "urn:moos:agent:vscode.hp-z440.menno",
  "session_urn": "urn:moos:session:sam.steinberger-seat",
  "node_urn": "urn:moos:claim:steinberger.<friction-or-thesis-slug>",
  "type_id": "claim",
  "properties": {
    "text":        {"value": "<one-paragraph claim text>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "confidence":  {"value": 0.7, "mutability": "mutable", "authority_scope": "owner", "stratum_origin": 2},
    "owner_urn":   {"value": "urn:moos:user:sam", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "subject_urn": {"value": "<urn of the surface or component the claim is about>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "created_at":  {"value": "<ISO-8601>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
  }
}
```

## Worked example: VSCode MCP wiring claim

**Friction.** Steinberger's seat boots on `kernel:hp-z440.menno` :8002 + MCP :9002. The `.vscode/mcp.json` (gitignored, machine-specific) needs the right SSE URL. If it's wrong, the seat can't emit envelopes through MCP at all — bypassed via curl POST instead, but loses the rich tool surface.

**Locate.** IDE attach + MCP transport layer.

**Claim.** ADD `claim:steinberger.vscode-mcp-sse-port-9002`:
> "VSCode on hp-z440 attached to Steinberger seat requires `.vscode/mcp.json` to declare an SSE entry pointing at `http://localhost:9002/sse` (the menno kernel's MCP listener). The startup script binds :9002 to menno; if VSCode points at :8080 (primary kernel's MCP) instead, envelopes go to the wrong kernel and §M11 rejects them as wrong-session-context. Fix: per-host `.vscode/mcp.json.example` should document all 4 kernel SSE ports + which seat uses which."

**Derive** (post v3.14): wrap claim in `derivation:steinberger.vscode-mcp-port-mapping-derivation`, consumes the federation startup script + .vscode/mcp.json.example, produces this claim + a proposed `program:sam.t176-arch.08-vscode-mcp-doc` (if comprehensive-architecture spec gets going).

**Propose.** Update `.vscode/mcp.json.example` with all 4 port entries; commit on ffs0; running-state.md gets a one-line note about per-seat MCP port mapping.

## Cross-references

- `moos-rewrite-envelope` — envelope shapes, gates
- `moos-state-readback` — round-open
- `moos-running-state-validator` — state-doc consistency (Guido's lane; co-validation)
- `kb/research/session/20260422-t172-wolframs-court-social-topology.md` — Steinberger seat origin doctrine
- `kb/research/session/20260424-t175-program-authoring-fabric.md` §5 — leaves as the fluid-execution boundary; relevant for tool_call / external_op design
- `D:\HPZ440\start_federation.ps1` — Z440 startup script
- `dev/scripts/ops/start_federation_laptop.ps1` — hp-laptop variant
- `dev/scripts/sync-claude-skills.ps1` — skill sync
- moos-kernel `internal/mcp/` — MCP transport implementation

## Status

**Round-13 deliverable** (T=176). First skill authored to serve the Steinberger seat post-Phase B launch. Will iterate as Steinberger's actual emit patterns reveal which DX work is highest-leverage.
