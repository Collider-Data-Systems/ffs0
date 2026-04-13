# ffs0 Repository Instructions

## Scope

- This repository is a personal portable private workspace (`ffs0`).
- Runtime kernel code lives in sibling repos (`moos-kernel`, `moos-router`) — not inside ffs0.
- `moos-config` is legacy — do not reference it.
- Keep instructions repository-local and avoid assuming kernel source is present in this repo.

## Working Style

- Prefer small, safe, focused edits.
- Preserve existing folder structure and naming unless a change is requested.
- Avoid process-heavy documents unless explicitly requested.

## Safety

- Never commit secret values.
- Treat `secrets/` as sensitive and local-first.
- Keep destructive actions explicit and intentional.

## Instruction Routing

- Keep broad defaults in this file.
- Keep topic-specific guidance in `.github/instructions/` and `.github/prompts/`.

## Domain Knowledge

- For mo:os categorical/mathematical reasoning, invoke the `category-master` skill.
- `design-research.instructions.md` fires automatically for `dev/design/**/*.md` files.
- Canonical domain reference: `kb/research/20260408-foundation-t158.md`.
