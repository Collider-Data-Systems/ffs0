# Factory Secrets

This directory contains sensitive credentials. **Never commit actual secrets.**

## Resolved architecture (T=239, #64) — keyless + Secret Manager

The per-machine `api_keys.env` is **retired as the source of truth** (offline fallback only).
Each secret type now has one home, and per device the *only* setup is two OAuth logins — nothing copied:

| Secret type | Home | How a device gets it |
|---|---|---|
| GitHub / git | **OS keyring** | `gh auth login` once per machine (per-device, revocable) |
| GCP — Vertex models, Secret Manager, Calendar/Keep DWD | **ADC** (no key) | `gcloud auth login` + `gcloud auth application-default login` once per machine |
| Provider API keys (Gemini AI-Studio / OpenAI / Anthropic) | **Google Secret Manager** (`mailmind-ai-djbuw`) | `dev/scripts/ops/Get-Secrets.ps1` fetches them into env at session start (via ADC — no file) |
| Calendar / Keep | **keyless DWD SA** (`moos-keep-ingest`) | delegated token via IAM `signJwt` (see "Keyless Google" below) |

**Gemini Flash via Vertex needs no key at all** (ADC) — so the AI-Studio Gemini key is *optional*.
Store a provider key once and you never touch a file again:

```powershell
printf '%s' '<NEW_KEY>' | gcloud secrets create gemini-api-key --data-file=- --project=mailmind-ai-djbuw
. dev\scripts\ops\Get-Secrets.ps1   # dot-source: loads Secret Manager keys into THIS shell's env
```

The chat-pip / so:om-surface model is **provider-swappable** in `dev/config/model-providers.json`
(`gemini-flash` → `gemini-flash-vertex` → `ollama-local`). IDE agents (Antigravity = Google-AI plan,
Claude Code = its plan) bring **their own** auth — not these keys. Sections below are the detailed
reference for the keyring / DWD / legacy-key-file paths.

## Canonical role

- `secrets/` is the Secret bindings surface for this workspace.
- `api_keys.env` is the canonical local secret env file.
- `api_providers.yaml` is a local provider/model registry for this workstation.
- Root `.env` files are not authoritative here. If some downstream tool requires `.env`, generate it from `secrets/` as a compatibility projection.

## Secret-surface policy (T=226, ffs0#64)

The fleet keeps `api_keys.env`'s secret surface **near-zero**. A machine that
moves between locations (e.g. HP ProDesk) must not accumulate long-lived secrets
on disk. Two patterns carry almost everything:

### GitHub auth

No GitHub token belongs in `api_keys.env`. Run `gh auth login` once per machine
(device/web flow); the token is stored in the **OS credential store (keyring)**,
is per-machine, and is independently revocable at `github.com/settings/tokens`.
`git`/`gh` operations use it automatically (`gh auth status` to confirm; `GH_TOKEN`
/ `GITHUB_TOKEN` should be unset). A leaked `ghp_` PAT that ever lands in a file
is treated as compromised — drop it from the file and **rotate** it on GitHub;
nothing on a keyring-authenticated box reads it.

### Keyless Google (DWD)

Calendar writes and Keep ingest run on a **keyless domain-wide-delegation**
service account, not on per-user OAuth token files or a downloaded
`gcp-service-account.json` key:

1. `gcloud auth application-default login` provides ADC (authorized_user).
2. The ADC principal is granted `roles/iam.serviceAccountTokenCreator` on the
   DWD service account.
3. IAM `signJwt` mints a short-lived **delegated** token for
   `sam@my-tiny-data-collider.nl` on demand — nothing long-lived on disk.

The DWD SA OAuth client-ID must be allow-listed for the needed scopes in
`admin.google.com` → Security → API controls → Domain-wide delegation
(`…/auth/calendar.events`, `…/auth/keep.readonly`). Do **not** land
`gcp-service-account.json` or `google_cloud_token.json` on a roaming machine.

What legitimately remains a file secret: provider API keys you use locally
(Gemini/OpenAI/Anthropic) and any Cloudflare Access service-token creds.

## Files (create locally)

### `api_keys.env`

```env
# mo:os local development
MOOS_DB_PASSWORD=your-local-postgres-password

# Google AI Studio
GEMINI_API_KEY=your-key-here

# OpenAI (optional)
OPENAI_API_KEY=sk-...

# Anthropic (optional)
ANTHROPIC_API_KEY=sk-ant-...
```

### `gmail_credentials.json`

Google OAuth2 client credentials for Gmail API access.
Download from Google Cloud Console → APIs & Services → Credentials → OAuth 2.0
Client IDs.

### `gmail_token.json`

Auto-generated OAuth2 token from the Gmail authentication flow.
Refreshed automatically when expired.

### `google_calendar_oauth_client.json`

Google OAuth2 installed-app client credentials for the Calendar write boundary.
The same Google login/project can be used as the Gmail login if the Calendar API
is enabled and the requested scope is granted. Use
`google_calendar_oauth_client.json.example` as the shape reference.

### `google_calendar_token.json`

Auto-generated OAuth2 token cache for `dev/scripts/google_calendar_writer.jl`.
It carries Calendar event-write scope only:
`https://www.googleapis.com/auth/calendar.events`.

### `gcp-service-account.json`

> **Prefer the keyless DWD path** (see "Keyless Google (DWD)" above) — do not
> download a JSON key onto a roaming machine. The steps below are the legacy
> key-file fallback, kept only for boxes where keyless ADC is not available.

Download from Google Cloud Console → IAM → Service Accounts → Keys

Then set:

```env
GOOGLE_APPLICATION_CREDENTIALS=D:/FFS0_Factory/moos/secrets/gcp-service-account.json
```

For Google Keep API ingest, use a Workspace domain-wide delegated service account. In Google Admin Console > Security > API controls > Domain-wide delegation, authorize the service account OAuth client ID for:

```text
https://www.googleapis.com/auth/keep.readonly
```

Then mint the local short-lived token and fetch real Keep API notes with `dev/scripts/ops/Invoke-KeepIngestHarness.ps1 -Mode ApiDelegatedFetch`.

If service-account key creation is blocked by organization policy, use the keyless
IAM Credentials path instead:

1. Authorize the service account OAuth client ID in Workspace domain-wide
   delegation for `https://www.googleapis.com/auth/keep.readonly`.
2. Grant the Google Cloud operator `roles/iam.serviceAccountTokenCreator` on the
   Keep ingest service account, or at the project level if needed.
3. Mint a Cloud signer token, then mint/fetch the delegated Keep token:

```powershell
dev/scripts/ops/Invoke-KeepIngestHarness.ps1 -Mode ApiCloudToken -UseCalendarOAuthClient -OpenBrowser -CloudLoginHint maassenhochrath@gmail.com
dev/scripts/ops/Invoke-KeepIngestHarness.ps1 -Mode ApiDelegatedKeylessFetch -UseCalendarOAuthClient
```

For a different Workspace subject, keep token and export lanes separate:

```powershell
dev/scripts/ops/Invoke-KeepIngestHarness.ps1 -Mode ApiDelegatedKeylessFetch -UseCalendarOAuthClient -DelegatedSubject lola@my-tiny-data-collider.nl -TokenPath secrets\google_keep_token_lola.json -OutDir tmp\projections\session_pipeline\keep_t206_lola -ApiOutDir scratch\keep\t195-t206\api-lola
```

`secrets/google_cloud_token.json` and `secrets/google_keep_token.json` are local
token caches. Do not commit them.

## Usage in Code

Load secret values from `secrets/api_keys.env` (or environment variables exported from it). Do not treat root `.env` as the source of truth.

For the Windows local-development kernel preset, `MOOS_DB_PASSWORD` is only required if `MOOS_KERNEL_STORE=postgres` and `platform/presets/windows-local-dev.json` needs to resolve `MOOS_DATABASE_URL` without committing a literal password.

For Gmail credentials:

```python
FACTORY_ROOT = Path(os.environ.get("FACTORY_ROOT", "D:/FFS0_Factory/moos"))
SECRETS_DIR = FACTORY_ROOT / "secrets"
credentials_path = SECRETS_DIR / "gmail_credentials.json"
token_path = SECRETS_DIR / "gmail_token.json"
```

For the Google Calendar writer:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode check
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode auth-listen
```

If the loopback listener cannot be used, fall back to `--mode auth-url` and then
`--mode exchange-code --code '<redirect-url-or-code>'`.

The real `google_calendar_oauth_client.json` and `google_calendar_token.json`
files stay local and ignored. HG may store file-reference URNs for these paths,
but never stores their contents.

## Security Notes

- This entire directory is gitignored (except README and .example files)
- Keep `api_providers.yaml` local unless you intentionally decide to version it elsewhere
- Keep `.env` generated-only if needed for compatibility; do not hand-author it as workspace truth
- In production, use GCP Secret Manager instead
- Rotate keys regularly
- Never log or print secrets
