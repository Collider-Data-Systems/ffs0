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
|---|---|---|
| `moos.serverPath` | `moos-lsp` | Path to the built server binary (put it on PATH or set an absolute path). |
| `moos.baseUrl` | `""` | Optional kernel base URL for live URN hover, e.g. `http://localhost:8000`. |

## Scope

Activates on `.moos` files and `**/*.{program,envelope,moos}.json`. Adjust the
`documentSelector` in `src/extension.ts` if you want it on more/fewer JSON files.
