# Section 11 - Hardware and Network

> Round-14 working draft for the Steinberger lane.
> Scope: physical hosts, kernel topology, transport paths, and operational reliability boundaries.

## 11.1 Host Topology and Sovereignty

mo:os currently runs on two sovereign host domains:

- Z440 domain: four kernels (`hp-z440.primary`, `hp-z440.menno`, `hp-z440.lola`, `hp-z440.moos`) plus federation router.
- hp-laptop domain: one kernel (`hp-laptop.primary`) with its own sovereign log.

Each kernel log is authoritative for that kernel. Federation read paths do not imply write replication.

## 11.2 Port Mapping and Emit Semantics

The canonical mapping is maintained in `kb/superset/running-state.md` and reflected in `dev/config/moos-federation.topology.json`.

Current rule until section M9 twin sync ships:

- Emit target for Z440 VS Code personas is `hp-z440.primary` (`:8000` HTTP, `:8080` MCP).
- `opens-on` for `menno`/`lola` is topology intent metadata, not current write destination.

This keeps section M11 checks aligned with receiving-kernel state.

## 11.3 Transport Surfaces

Active transport stack:

- Kernel HTTP APIs (`/healthz`, `/state/*`, `/programs`, `/operad/*`)
- MCP SSE endpoints (`:8080`, `:9001`, `:9002`, `:9003`)
- WF16 router fanout (`:9000`) for cross-kernel read routing

Planned transport evolution:

- Section M10 HTTP/3 QUIC path for federation-grade streaming and future paired M9 synchronization.

## 11.4 Operational Cockpit

`ffs0.code-workspace` is the operator cockpit. `Test-MoosFederation.ps1` is the runtime bring-up and verification harness.

Core workflow:

1. `Doctor` validates health, ontology, and MCP wiring.
2. `VerifyPersona` validates receiving-kernel occupancy and emit readiness.
3. `PostProgram` emits with preflight gating.

This reduces port-memory mistakes and makes emit routing mechanically verifiable.

## 11.5 Failure Modes and Controls

Primary failure modes and current controls:

- Port-to-kernel drift: controlled by topology manifest plus doctor checks.
- Emit-target confusion (`opens-on` vs receiving kernel): controlled by persona verification and explicit emit mapping.
- Payload shape drift (`/programs` array requirement): controlled by harness normalization of single envelopes and wrapped payloads.
- Session/occupancy mismatch at emit time: controlled by preflight checks and M11 gate enforcement.

## 11.6 Round-14 to Round-15 Bridge

Round-14 target in this section:

- Stabilize current host/network operational doctrine and tooling.

Round-15+ targets:

- Pair M9 twin-kernel sync with M10 QUIC transport work.
- Promote cross-kernel state and causation links once WF21 and companion fragments are in place.
