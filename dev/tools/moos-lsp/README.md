# moos-lsp

A [Language Server](https://microsoft.github.io/language-server-protocol/) for mo:os
rewrite envelopes and programs. Gives any LSP editor (VS Code, Neovim, Zed, Emacs,
JetBrains) live ontology intelligence, driven by symbol tables **generated from
`kb/superset/ontology.json`**.

## Features

- **Diagnostics** on envelope / program JSON (`[...]`, a single envelope, or
  `{envelopes:[...]}`):
  - unknown `type_id` (not in the operad)
  - unknown `rewrite_category`, or a WF that doesn't allow the `rewrite_type`
  - LINK `(src_port → tgt_port)` not a declared pair of the WF
  - src/tgt URN type outside the WF's `src_types` / `tgt_types`
  - malformed URN / unknown type segment
  - forbidden-vocabulary lint (`edge`, `wire`, `morphism`, `payload`, `_ref`, …)
- **Completion** for `rewrite_type`, `type_id`, `rewrite_category` (WF ids),
  `src_port`/`tgt_port`, and envelope keys.
- **Hover** on a WF id, node type, port, forbidden token, or URN — with optional
  **live folded state** (`GET /state/nodes/{urn}`) when `--base-url` is set.

## Build

```sh
cd dev/tools/moos-lsp
go build -o moos-lsp .
```

## Regenerate the ontology tables

`internal/ontology/symbols.go` is generated; regenerate it after an ontology bump:

```sh
go run ./internal/ontology/gen \
  -ontology ../../../kb/superset/ontology.json \
  -out internal/ontology/symbols.go
```

## Run

```sh
./moos-lsp                                   # static (no kernel)
./moos-lsp --base-url http://localhost:8000  # enable live URN hover
```

Speaks LSP over **stdio**. Point any LSP client at the binary; the bundled VS Code
client stub lives in `client/`.

## Test

```sh
go test ./internal/handlers/
```

## Follow-ups

- Go-to-definition on a URN → its ADD log entry.
- True port-color diagnostics (needs a port→color map exported from the ontology).
- A tree-sitter grammar + semantic tokens for `.moos` files.
