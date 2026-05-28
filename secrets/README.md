# Factory Secrets

This directory contains sensitive credentials. **Never commit actual secrets.**

## Canonical role

- `secrets/` is the Secret bindings surface for this workspace.
- `api_keys.env` is the canonical local secret env file.
- `api_providers.yaml` is a local provider/model registry for this workstation.
- Root `.env` files are not authoritative here. If some downstream tool requires `.env`, generate it from `secrets/` as a compatibility projection.

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
