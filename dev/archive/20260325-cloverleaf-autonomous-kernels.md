# PRG036 — Autonomous Kernel Federation (Dynamic Fibers)

## Architecture Decision: Model 2

Rejected hub/leaf hierarchy. Each kernel is an autonomous runtime process bound to a compute resource.

### Core Definitions

**Kernel** = functor K: Ontology -> InstanceSpace, bound to compute.
- K_cpu: strata S0-S2 (authoring, validation, materialization)
- K_gpu: stratum S3 (HDC vector ops, curvature, similarity)
- K_disk: strata S0-S1 (persistent log, KB artifacts)
- K_github: stratum S4 (ProjectV2 projection, external process)

**Dynamic Fiber** = causal cone of a demand query. The minimal wire-set needed for an operation, crossing PTP families, discovered at runtime.

**Bridge** = natural transformation eta: K_A => K_B. Bidirectional (adjunction). Carries rate metadata.

**Pipeline Metric** = rate-mismatch between fiber producers and consumers. Ricci curvature on branchial graph identifies bottlenecks.

### Theoretical Foundations

1. **Sheaves on process topology**: each kernel holds a local section. Gluing condition = fiber overlap consistency.
2. **Cooperad decomposition**: C(n) -> C(k) x C(n1) x ... x C(nk). Dynamic fiber = cooperad evaluation at runtime.
3. **Grothendieck construction**: integral F = fibered category where objects are (K, w) pairs. Sections = synchronized state.
4. **Causal invariance (Wolfram)**: independent fibers can be processed concurrently. Fiber boundary = independence boundary.
5. **Virtual memory analogy**: demand-paged fibers. Fiber fault = missing wire triggers priority sync.

### Real Topology (as of 2026-03-25)

```
user:sam (admin)
  |-- owns --> workstation:hplaptop
  |              kernel:hplaptop-primary (active, S0-S2)
  |                compute:hplaptop-cpu (AMD Ryzen 5)
  |                compute:hplaptop-igpu (AMD Radeon Vega, limited S3)
  |                memory:hplaptop-ram (16GB)
  |                memory:hplaptop-disk (512GB SSD)
  |
  |-- owns --> workstation:local_dev
  |              kernel:localdev-primary (planned, S0-S3)
  |                compute:localdev-cpu (Xeon E5-1650)
  |                compute:localdev-gpu (RTX 3060 12GB, real S3)
  |                memory:localdev-ram (64GB)
  |                memory:localdev-disk (2TB SSD)
  |
  |-- owns --> workstation:gcp-cloud (planned)
  |              kernel:gcp-cloud (planned, S0-S3)
  |
  |-- owns --> kernel:github-projection (active, S4 only)
                 bridge: project-sync.yml (one-way, kernel->GitHub)
```

### Phase Plan

| Phase | What | Owner | Validation |
|-------|------|-------|------------|
| 036.1 | Port definitions for identity types + kernel_instance | vscode | LINK kernel.out->compute.in accepted |
| 036.2 | Cooperad fiber decomposition algorithm | claude-code | Compute fiber for 2-hop neighborhood query |
| 036.3 | Bridge protocol (natural transformation) | vscode | Sync fiber between hplaptop and localdev |
| 036.4 | Pipeline metrics + Ricci on branchial graph | claude-code | Detect bottleneck, compute curvature |
| 036.5 | Bidirectional bridge PoC | vscode | Round-trip: GitHub field -> kernel MUTATE -> re-project |

### Blocked Wiring (awaiting 036.1 port definitions)

The following LINKs failed because infra_service, workstation_config, compute_resource, memory_store have no ports defined:
- kernel:hplaptop-primary.out -> compute:hplaptop-cpu.in (and all kernel->resource wires)
- kernel:hplaptop-primary.bridge -> kernel:localdev-primary.bridge

VS Code delegation_task:036-1-port-definitions covers this.
