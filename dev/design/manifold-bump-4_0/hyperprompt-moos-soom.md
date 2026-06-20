---
agent: "moos-categorical-research"
description: "Use when: opening a Claude session on hpz / hplap / hppro to work the mo:os ⊣ so:om lane. Paste-ready seed (a 'hyperprompt') that boots the box-Claude already wired with the engine/surface split, the discipline, and the orientation steps. Copy the fenced block."
---

# Hyperprompt — mo:os ⊣ so:om

Paste the fenced block below into Claude on whichever box you open (hp-z440, hp-laptop, hpprodesk,
or a combo). It carries the wired frame so the session starts aligned instead of re-deriving it.
Full reasoning: `dev/design/manifold-bump-4_0/20260620-t231-moos-soom.md`.

```text
You are working the mo:os ⊣ so:om lane. Orient first, then act.

ORIENT (do this before anything):
1. Read kb/superset/running-state.md, then GET /healthz on the local kernel. Folded HG +
   live readback outrank any doc; if a doc disagrees with readback, re-read — readback wins.
2. Read AGENTS.md (project SOT) and dev/design/manifold-bump-4_0/20260620-t231-moos-soom.md (this lane).

THE FRAME (mo:os ⊣ so:om = F ⊣ G):
- mo:os = the engine (the dachshund): the durable data/graph layer — HG, instances,
  state = fold(log). The ONLY source of truth.
- so:om = the surface (the octopus): the active-application matrix — windows, tabs, panes,
  widgets, repos. S0 substrate, OBSERVED-NOT-AUTHORED. Never authority.
- F: mo:os → so:om = project/lower (run-session-pipeline). G: so:om → mo:os = ingest/lift
  (moos-workspace-ingest, Keep-ingest). The repo/GitHub is a so:om tentacle (channel.kind:vcs),
  not the engine — a git write is F(rewrite-intent); a merge to main is G(branch), RBAC-ruled.

THE DISCIPLINE (wire, don't buzzword):
- Every set element is a NODE (identity). Every function is a RELATION (LINK = topology) or a
  REWRITE (a WF op). NEVER a method on an object. OOP scaffold translates:
  object→node, field→property, method→relation/rewrite.
- The four rewrites ADD · LINK · MUTATE · UNLINK are the only mutations. Log is truth; state
  is derived. Mark conjectures as conjectures.
- Immutables (set at ADD, never MUTATEd; CI-3): owner_urn, created_at, name, urn, T-epoch.
- Active cache = derived, rebuildable-from-log, keyed by graph identity, invalidated by
  rewrites (φ(purpose), persona views, current-T). The cache is never truth.

WORLD-MODEL SETS (use the real types; do NOT reinvent):
  user ✅  group ✅  agent ✅  purpose ✅  cycle = clock ✅  soul = persona = Φ(purpose) = derivation ✅
  device = a workstation.kind (mobile) that RUNS an instance too — Android/hpz/hplap/hppro are all
    mo:os instances; they differ by DEGREE of F/G (G = rewrite reach, F = surface reach), not by
    hosting-or-not. Functions are streamed (link existing) or bootstrapped (compile-new onto a chosen
    destination workstation = project the IR there per build params). — conjecture (Sam, #73).
  noagent = already legal (WF19 has-occupant accepts a user; human-only workspaces are valid).

AUTHORITY (agent↔user on a shared purpose):
  Not a type wall — an authority gradient. user = superadmin; agent = delegate with
  P(delegate) ≤ P(principal) (CI-5) + §M11/§M12. Both may occupy one workspace and share one
  has-purpose. Strict at the authority layer, permissive at occupancy.

REALTIME (so:om transport): WebTransport two-channel — HTTP/3 datagrams for the lossy game-tick
  presence + reliable streams for durable log commits. Never conflate render-tick with log-commit.

SAFETY / GATE: This lane authorizes NO ontology or URN change. Device / channel.kind:keep-widget /
  the path-URN address are conjectures (grammar_fragment proposals, status proposed), not applied.
  Mutations (commit/push, HG apply, DNS/Calendar writes) are explicit boundary acts — surface
  before doing. secrets/ and .vscode/mcp.json are never committed.

THEN: state your seat (agent-urn / session-urn / emit kernel) from the AGENTS.md seat map, and
say what you're about to do before you do it.

TASK: <fill in — e.g. "draft the device grammar_fragment", "G-ingest the T230/T231 Keep notes",
"prototype the so:om Cytoscape surface", "wire φ(purpose) into the active cache">.
```

## Notes
- The seat line (agent-urn / session-urn / emit kernel) is per the `AGENTS.md` seat map; until
  §M9 twin-sync, Z440 personas emit to `kernel:hp-z440.primary` :8000 / MCP :8080.
- This is a so:om artifact (an F-projection of the design draft). The draft is the reasoning; this
  is the warm-start. Regenerate it from the draft when the frame moves.

authored-by: agent:claude-code.hp-z440 / session:sam.z440-cowork-workspace / moos-soom-wiring
