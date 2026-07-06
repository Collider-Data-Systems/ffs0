# mo:os LSP — VS Code client

Thin VS Code extension that launches `moos-lsp` over stdio. Not published to the
Marketplace — built and run locally.

## Setup

```sh
# 1. build the server
cd dev/tools/moos-lsp && go build -o moos-lsp .

# 2. build the client
cd client && npm install && npm run compile

# 3. run the extension
#    open this folder in VS Code and press F5 (Extension Development Host),
#    or package with `vsce package` and install the .vsix.
```

## Settings

| Setting | Default | Meaning |
| --- | --- | --- |
| `moos.serverPath` | `moos-lsp` | Path to the built server binary. When left at the default, the client first looks for `dev/tools/moos-lsp/moos-lsp(.exe)` in the open workspace before falling back to PATH. If a configured filesystem path is stale or missing, the client warns and falls back through the same workspace/PATH lookup instead of spawning the missing path. |
| `moos.baseUrl` | `""` | Optional kernel base URL for live URN hover, e.g. `http://localhost:8000`. |

## Scope

Activates on `.moos` files and `**/*.{program,envelope,moos}.json`. Adjust the
`documentSelector` in `src/extension.ts` if you want it on more/fewer JSON files.
