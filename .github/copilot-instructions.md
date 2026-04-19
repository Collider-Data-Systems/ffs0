# ffs0 Repository Instructions

## Scope

Personal portable private workspace (`ffs0`).
Runtime code lives in sibling repos (`moos-kernel`, `moos-router`). `moos-config` is legacy.

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, key URNs.

Round-level handoffs (per agent × machine) live under `kb/research/` as `t<N>plan_<agent>_<machine>.md` and `t<N>_conv_sum_<agent>_<machine>.md`. Skim the latest when picking up fresh context.

## Working style

Small, safe, focused edits. Preserve folder structure unless change is requested.
Avoid process-heavy documents unless explicitly requested.

## Domain knowledge

Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.

## Safety

Never commit secret values. `secrets/` is local-first. Destructive actions are explicit.
