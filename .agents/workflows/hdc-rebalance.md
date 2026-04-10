---
description: HDC Rebalance and Inverse Functor Evaluation
---

# HDC Rebalance and Inverse Functor Evaluation

**Description:** Evaluates the state of the 4-kernel HDC federation on the HP-Z440 workstation, performs targeted shard node rebalancing to optimize the discrete fiber bundle architecture, and mathematically verifies inverse functor distances (`ι₄₃` reconstruction error).

## Execution Steps

1. **Verify Federation Topology**
   - Execute fiber analysis using the endpoint `GET /hdc/fiber-assignment`
   - Identify nodes with disparate `current_kernel` versus `optimal_kernel`

2. **Execute Targeted Link Re-Writing**
   - Nodes are implicitly bound to kernels dynamically. To force an HDC boundary assignment, issue a `POST /programs` request that creates a targeted `shard_rule` configuration.
   - Execute an `ADD` node envelope for the `shard_rule` explicitly denoting `urn_prefix` mappings.
   - Execute a `LINK` (`routes-to`) envelope connecting the `shard_rule` node to the mathematically preferred target kernel URN.
3. **Execute Inverse Functor Validation (JSD & Recon)**
   - Extract Federation Distribution `GET /hdc/federation` (`φ₄`) and Kernel Vectors `GET /hdc/fiber?kernel=<URN>` (`φ₃`).
   - Validate reconstruction error defined by `1.0 - Cosine(φ₄, φ₃)` where standard compliance is `< 0.15` (Primary hub kernels are exempt from this threshold limit).
   - Validate geometric dispersion measuring Kernel Type Histogram Divergence to Federation Base (`GET /hdc/fiber-distribution`). JSD margin must eclipse `> 0.3`.

## Helper Scripts

Reference `rebalance_hdc.ps1` and `inverse_functors.ps1` in the system workspace root (`d:\HPZ440`) if programmatic execution of the HDC evaluations is required.
