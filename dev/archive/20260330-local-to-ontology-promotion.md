# Local-to-Ontology Promotion

## Summary

Local kernels and worktrees are allowed to discover contingent patterns first. They do not canonize those patterns directly. They emit graph-native signals that preserve provenance, then governance decides whether that local pattern becomes ontology, admitted kernel topology, or canonical repo structure.

This file defines the minimal promotion loop now represented in the ontology:

- `kernel_instance` for executable kernel sections
- `git_repo` for repository identity
- `git_branch` for branch lineage
- `git_worktree` for local checkout embodiment
- `governance_proposal` for upward promotion requests
- `SPECIALIZES_KERNEL` for kernel split lineage
- `TRACKS_BRANCH` and `CHECKED_OUT_AT` for repo-to-worktree identity
- `PROPOSES_PROMOTION` for local contingent change requesting canonical promotion

## Problem

The old model had two gaps:

1. Local code changes and local graph discoveries had no first-class way to signal upward to ontology other than chat or ad hoc docs.
2. Repo identity, branch identity, and worktree embodiment were conflated, so a local branch change could not be reasoned about cleanly as a contingent local fact versus a governed canonical fact.

## Objects

### Kernel Instance

`kernel_instance` is the executable kernel as a local section of the shared HG.

- It can bridge to peers with `CAN_FEDERATE`.
- It can declare lineage with `SPECIALIZES_KERNEL`.
- It is the promoted target when a one-kernel system later splits into governed child kernels.

### Repo / Branch / Worktree

`git_repo` is the stable repository identity.

`git_branch` is the mutable lineage inside that repo.

`git_worktree` is the concrete local embodiment of a branch on a workstation or kernel-local filesystem slice.

The intended chain is:

```text
git_repo --TRACKS_BRANCH--> git_branch --CHECKED_OUT_AT--> git_worktree
```

This keeps identity and embodiment separate:

- remote URL is a locator, not the repo identity
- branch name is lineage, not a folder
- local folder is embodiment, not canonical truth

## Promotion Loop

### 1. Local discovery

A local kernel or local worktree observes a recurring pattern:

- a graph motif appears repeatedly
- a local branch stabilizes a kernel behavior
- a kernel split becomes persistent rather than experimental

At this stage the fact is contingent and local.

### 2. Record proposal

The kernel or user records a `governance_proposal` node at `S0-S2` with payload such as:

```json
{
  "title": "Promote kernel split to ontology",
  "status": "pending",
  "origin_kernel": "urn:moos:kernel:hplaptop-primary",
  "origin_worktree": "urn:moos:worktree:hplaptop:agent-vscode-ai",
  "origin_branch": "urn:moos:branch:agent/vscode-ai",
  "proposed_artifact": "ontology",
  "reason": "Repeated local specialization now stable across sessions",
  "evidence": [
    "urn:moos:prg:036-cloverleaf",
    "urn:moos:prg:037-inspect-run"
  ]
}
```

The proposal may also use `LINK_NODES` to attach evidence PRGs, sessions, notes, or benchmark artifacts.

### 3. Target canonical object

Use `PROPOSES_PROMOTION` when the request is specifically upward into:

- an `ontology_term`
- a `kernel_instance`

Examples:

```text
governance_proposal --PROPOSES_PROMOTION--> ontology_term
governance_proposal --PROPOSES_PROMOTION--> kernel_instance
```

This marks the requested canonical target without pretending the promotion is already approved.

### 4. Governance decision

Approval remains external governance by user, group, and admin roles.

The graph records:

- what was proposed
- where it came from
- which repo / branch / worktree produced it
- which kernel observed it

The graph does not autonomously decide canonical promotion.

### 5. Canonicalization

Once approved, the proposal must land in repo truth:

- ontology changes go to `kb/superset/ontology.json`
- design semantics go to `dev/design/*.md`
- instance defaults go to `kb/superset/instances/*.json`
- kernel behavior hardening goes to Go code in `moos/platform/kernel`

Hydration and replay then make the promoted structure available as ordinary graph truth.

## Kernel Split Rule

The system starts as one kernel. Stable local specialization can later become explicit kernel lineage.

Use:

```text
parent kernel_instance --SPECIALIZES_KERNEL--> child kernel_instance
```

Interpretation:

- `SPECIALIZES_KERNEL` means lineage and specialization
- `CAN_FEDERATE` means transport and synchronization

These must not be conflated. A child kernel can specialize a parent without active transport. Two kernels can federate without one being a specialization of the other.

## Operational Rule

No local branch, worktree, or kernel may directly claim ontology truth.

The required sequence is:

```text
local contingent fact
-> governance_proposal
-> governed approval
-> repo change
-> hydration / replay
-> canonical graph truth
```

That is the upward signaling path.
