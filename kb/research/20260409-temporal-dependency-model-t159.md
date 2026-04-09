# Temporal Dependency Model

Date: 2026-04-09 | T=159
Status: Implemented in ontology v3.3 (program node type + WF18). Theoretical model agreed.
Related: `20260408-presheaf-classification-temporal-t158.md` sections 8-9, `20260408-foundation-t158.md` section 10

---

## 1. Time as a Forward-Looking Property

Time in mo:os is not just a log timestamp. It is a **meaningful, mutable property** on nodes
that bridges the graph runtime and IRL (in real life).

### The distinction

| Type | Source | Mutability | Purpose |
|------|--------|------------|---------|
| `created_at` | Log timestamp | Immutable | When the node was ADDed |
| `applied_at` | Log timestamp | Immutable | When each rewrite touched the node |
| `target_t` | Author | **Mutable** | When the work aims to complete |
| `starts_t` | Author | **Mutable** | When work begins or is expected to begin |
| `deadline_t` | Author | **Mutable** | Hard deadline (distinct from soft target) |
| `completed_t` | Author | **Mutable** | When status became completed |

Log timestamps are backward-looking: they record what happened.
Temporal properties are forward-looking: they declare intent about what WILL happen.

Plans shift. Deadlines move. Completion dates are discovered, not predetermined.
All temporal properties are mutable because they model a world in motion.

### Moos-time

T=0 = November 1, 2025 00:00 CEST. Each T-day is one calendar day.
All temporal properties use integer T-day values, not ISO timestamps.
This makes temporal arithmetic trivial: `deadline_t - target_t` = slack in days.

---

## 2. Two Dependency Modes

### Mode 1: Known-Node Dependency (LINK)

A direct LINK relation to a specific URN.

```
program:sam.hackathon-mvp --depends-on--> program:sam.t159-ignition
```

You know the node. The wire is a pointer. One path to satisfaction.
When `t159-ignition.status` becomes `completed`, the dependency is met.

This is a standard graph relation via WF18 (Program composition) or WF07 (Workflow lifecycle).

### Mode 2: Property-Pattern Dependency (WATCHER)

No specific URN. The dependency is a **predicate over the graph**.

```json
{
  "type_id": "watcher",
  "properties": {
    "watch_filter": {
      "type_id": "program",
      "properties": {
        "status": "completed",
        "owner_urn": "urn:moos:user:sam"
      }
    }
  }
}
```

Any node matching the filter satisfies the condition.
The watcher doesn't know or care which specific node it will be.
Multiple paths can satisfy the same condition.

### When to use which

| Situation | Mode | Why |
|-----------|------|-----|
| "T=162 depends on T=159 finishing" | Known-node (LINK) | Both nodes exist, specific dependency |
| "Can't start until all infra programs complete" | Property-pattern (WATCHER) | Don't enumerate them, describe the condition |
| "Blocked until someone validates the jaarrekening" | Property-pattern (WATCHER) | Don't know who will do it |
| "T=180 spec depends on T=169 hackathon" | Known-node (LINK) | Direct temporal chain |

---

## 3. Multiway Interpretation

In Wolfram's multiway system, a rule applies wherever its pattern matches.
The system branches because the same pattern can match at multiple sites.
The key property: **the rule doesn't name a specific token — it describes a shape**.

Property-pattern dependencies ARE multiway dependencies.

```
dependency: "needs a completed program with scope containing 'infrastructure'"

  branch A: sam completes prg:infra-audit         -> satisfies
  branch B: z440-agent builds prg:infra-bootstrap  -> satisfies
  branch C: external federated kernel delivers one  -> satisfies
```

All three branches converge at the same watcher. This is confluence: CI-1 over the
dependency subgraph. The system doesn't care which branch fires first.

### Connection to existing WF17 mechanism

The watcher node already supports this:

| Watcher field | Known-node mode | Property-pattern mode |
|---|---|---|
| `match_type_id` | specific type | specific type |
| `match_urn_prefix` | specific URN prefix | broad prefix or absent |
| property filters | optional refinement | **the actual dependency** |

A watcher with `match_type_id: "program"` and no `match_urn_prefix` fires when ANY
program node is MUTATEd. Combined with a guard checking `status == "completed"`,
this is a property-pattern temporal dependency.

### The clock

The human in the loop IS the clock.

External events enter through leaf portals. Sam walks in, MUTATEs a node to
`status: completed`, and that MUTATE cascades through watchers that were waiting
on that property pattern. The graph doesn't have a clock — it has a human who
decides when things are done.

This is the bridge between runtime and IRL: temporal properties encode INTENT,
the human encodes REALITY by MUTATEing status when conditions are met IRL.

---

## 4. Temporal Dependency DAG (T=159 State)

```
program:sam.full-spec (draft, T=180)
  |-- depends-on --> program:sam.hackathon-mvp (active, T=169, deadline=169)
  |                    |-- depends-on --> program:sam.t159-ignition (active, T=159)
  |                    |-- depends-on --> program:sam.t162-presentation (draft, T=162)
  |                    |-- composes   --> prg:hackathon-2026 (legacy, active)
  |-- composes   --> prg:kernel-federation (legacy, active)

program:sam.t162-presentation (draft, T=162)
  |-- depends-on --> program:sam.t159-ignition (active, T=159)

program:sam.t159-ignition (active, T=159)
  |-- composes   --> prg:moos-diary (legacy, active)
```

### Temporal ordering

```
T=159: ignition (wire nodes, ontology v3.3, temporal model)
  -> T=162: presentation (Google Flow for Menno)
    -> T=169: hackathon MVP (live demo, DataHacks)
      -> T=180: full application spec (my-tiny-data-collider)
```

### Completion cascade

When `t159-ignition.status` is MUTATEd to `completed`:
1. Known-node watchers on `t162-presentation.depends-on` are satisfied
2. `t162-presentation` can transition from `draft` to `active`
3. Property-pattern watchers ("any program with target_t <= 159 completed") also fire
4. The temporal DAG advances forward

This is the reactive layer + temporal properties working together.
No scheduler. No cron. Just rewrites and watchers.

---

## 5. Implementation in Ontology v3.3

### New node type: `program`

```
Properties:
  title        (immutable) — what this program is
  owner_urn    (immutable) — provenance stamp
  status       (mutable)   — draft | active | completed | archived | blocked
  scope        (mutable)   — what it delivers (evolves)
  target_t     (mutable)   — soft target T-day
  starts_t     (mutable)   — when work begins
  deadline_t   (mutable)   — hard deadline T-day
  completed_t  (mutable)   — when status became completed
  created_at   (immutable) — ADD timestamp
```

### New rewrite category: WF18 (Program composition)

```
src_types:  [program]
tgt_types:  [prg_task, knowledge_item, agent_session, program]
allowed:    LINK, UNLINK, MUTATE
mutate_scope: status, scope, target_t, starts_t, deadline_t, completed_t
ports:      composes/composed-by, depends-on/depended-by,
            blocks/blocked-by, produces/produced-by,
            scheduled-after/scheduled-before
authority:  owner
sync_mode:  eventual
```

### Relationship to legacy prg_task

Legacy prg_task nodes have immutable temporal properties (t_start, t_target).
They are frozen temporal snapshots — completed/archived work items.
New work items use the `program` type with mutable temporal properties.
Program nodes compose legacy prg_tasks via WF18, bridging old and new.

---

## 6. Open Questions

### Property-pattern watch filter syntax

Current watcher properties are flat fields: `match_rewrite_type`, `match_type_id`,
`match_urn_prefix`. For richer property-pattern dependencies, we need:

- Nested property filters: `match_properties: { "status": "completed", "target_t": { "$lte": 162 } }`
- Comparison operators: `$eq`, `$lte`, `$gte`, `$contains`
- Boolean combinators: `$and`, `$or`, `$not`

This is a query language over node properties. Design decision deferred — current
flat matchers are sufficient for known-node dependencies and simple type-based patterns.

### Guard node integration

Guards gate reactors with state predicates. A temporal dependency could be modeled as:

```
watcher (fires on any program MUTATE)
  -> guard (checks: all programs with target_t <= X have status completed)
    -> reactor (MUTATE dependent program status to active)
```

The guard node IS the property-pattern filter. This three-stage pipeline
(watch -> guard -> react) is the full temporal dependency mechanism.

### Spectral implications

Adding temporal dependency watchers to the graph changes the cascade matrix C.
Each new watcher-reactor pair adds entries to T and P.
The spectral radius rho(C) must remain < 1 — checked at WF17 configuration time.

Temporal dependencies are inherently DAG-structured (no cycles in time),
so they contribute nilpotent submatrices to C. Nilpotent matrices have rho = 0.
Temporal watchers cannot cause divergent cascades by construction.
