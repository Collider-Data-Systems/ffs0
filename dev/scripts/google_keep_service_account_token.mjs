#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const DEFAULT_KEY_PATH = 'secrets/gcp-service-account.json';
const DEFAULT_TOKEN_PATH = 'secrets/google_keep_token.json';
const DEFAULT_SIGNER_TOKEN_PATH = 'secrets/google_cloud_token.json';
const DEFAULT_SCOPE = 'https://www.googleapis.com/auth/keep.readonly';
const TOKEN_URI = 'https://oauth2.googleapis.com/token';
const IAM_CREDENTIALS_ROOT = 'https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts';

function usage() {
  return `Usage: node dev/scripts/google_keep_service_account_token.mjs --subject <workspace-user> [options]

Options:
  --key <path>       Service-account JSON key path (default: ${DEFAULT_KEY_PATH})
  --token <path>     Output token cache path (default: ${DEFAULT_TOKEN_PATH})
  --signer-token <path>
                     Google Cloud OAuth token path for IAM signJwt fallback
                     (default: ${DEFAULT_SIGNER_TOKEN_PATH})
  --client-email <email>
                     Service-account email for keyless IAM signJwt mode
  --client-id <id>   Service-account OAuth client ID for dry-run reporting
  --scope <scopes>   Space/comma separated OAuth scopes (default: ${DEFAULT_SCOPE})
  --subject <email>  Workspace user to impersonate, for example sam@my-tiny-data-collider.nl
  --dry-run true     Validate inputs and print the service-account client ID only
`;
}

function parseArgs(argv) {
  const options = {
    key: DEFAULT_KEY_PATH,
    token: DEFAULT_TOKEN_PATH,
    'signer-token': DEFAULT_SIGNER_TOKEN_PATH,
    'client-email': '',
    'client-id': '',
    scope: DEFAULT_SCOPE,
    subject: '',
    'dry-run': 'false',
  };
  for (let i = 0; i < argv.length; i += 2) {
    const flag = argv[i];
    if (!flag?.startsWith('--')) {
      throw new Error(`unexpected argument: ${flag ?? ''}`);
    }
    const name = flag.slice(2);
    if (!(name in options)) {
      throw new Error(`unknown option: ${flag}`);
    }
    if (i + 1 >= argv.length) {
      throw new Error(`missing value for ${flag}`);
    }
    options[name] = argv[i + 1];
  }
  return options;
}

function boolValue(value) {
  return ['1', 'true', 'yes', 'y'].includes(String(value).trim().toLowerCase());
}

function base64url(input) {
  const buffer = Buffer.isBuffer(input) ? input : Buffer.from(input);
  return buffer.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function parseScopes(scopeText) {
  return String(scopeText)
    .split(/[\s,]+/)
    .map((scope) => scope.trim())
    .filter(Boolean);
}

function requiredString(record, key) {
  const value = record[key];
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`service-account key is missing ${key}`);
  }
  return value;
}

function requiredOption(options, key) {
  const value = options[key];
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`--${key} is required in keyless IAM signJwt mode`);
  }
  return value;
}

function readUnexpiredToken(tokenPath) {
  const token = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
  if (typeof token.access_token !== 'string' || token.access_token.trim() === '') {
    throw new Error(`token file is missing access_token: ${tokenPath}`);
  }
  if (typeof token.expires_at === 'string' && token.expires_at.trim() !== '') {
    const expiresAt = Date.parse(token.expires_at);
    if (Number.isFinite(expiresAt) && expiresAt <= Date.now() + 60_000) {
      throw new Error(`token file is expired or near expiry: ${tokenPath}`);
    }
  }
  return token;
}

function jwtPayload(clientEmail, subject, scopes, nowSeconds) {
  return {
    iss: clientEmail,
    scope: scopes.join(' '),
    aud: TOKEN_URI,
    exp: nowSeconds + 3600,
    iat: nowSeconds,
    sub: subject,
  };
}

function jwtAssertion(serviceAccount, subject, scopes, nowSeconds) {
  const clientEmail = requiredString(serviceAccount, 'client_email');
  const privateKey = requiredString(serviceAccount, 'private_key');
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };
  if (typeof serviceAccount.private_key_id === 'string' && serviceAccount.private_key_id !== '') {
    header.kid = serviceAccount.private_key_id;
  }
  const payload = jwtPayload(clientEmail, subject, scopes, nowSeconds);
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const signature = crypto.sign('RSA-SHA256', Buffer.from(signingInput), privateKey);
  return `${signingInput}.${base64url(signature)}`;
}

async function signJwtWithIamCredentials(clientEmail, payload, signerAccessToken) {
  const url = `${IAM_CREDENTIALS_ROOT}/${encodeURIComponent(clientEmail)}:signJwt`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${signerAccessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ payload: JSON.stringify(payload) }),
  });
  const text = await response.text();
  const parsed = text.trim() === '' ? {} : JSON.parse(text);
  if (!response.ok) {
    const message = parsed.error?.message || parsed.error_description || parsed.error || response.statusText;
    throw new Error(`HTTP ${response.status} from IAM signJwt: ${message}`);
  }
  if (typeof parsed.signedJwt !== 'string' || parsed.signedJwt.trim() === '') {
    throw new Error('IAM signJwt response did not include signedJwt');
  }
  return parsed.signedJwt;
}

async function exchangeAssertion(assertion) {
  const body = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion,
  });
  const response = await fetch(TOKEN_URI, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const text = await response.text();
  let parsed = {};
  if (text.trim() !== '') {
    parsed = JSON.parse(text);
  }
  if (!response.ok) {
    const message = parsed.error_description || parsed.error || response.statusText;
    throw new Error(`HTTP ${response.status} from ${TOKEN_URI}: ${message}`);
  }
  return parsed;
}

function formatUtc(seconds) {
  return new Date(seconds * 1000).toISOString().replace(/\.\d{3}Z$/, 'Z');
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.subject.trim() === '') {
    throw new Error('--subject is required');
  }
  const hasKey = fs.existsSync(options.key);
  const serviceAccount = hasKey ? JSON.parse(fs.readFileSync(options.key, 'utf8')) : null;
  const clientId = serviceAccount ? requiredString(serviceAccount, 'client_id') : requiredOption(options, 'client-id');
  const clientEmail = serviceAccount ? requiredString(serviceAccount, 'client_email') : requiredOption(options, 'client-email');
  const scopes = parseScopes(options.scope);
  if (scopes.length === 0) {
    throw new Error('--scope must include at least one scope');
  }

  if (boolValue(options['dry-run'])) {
    console.log(`Service account: ${clientEmail}`);
    console.log(`OAuth client ID for Workspace domain-wide delegation: ${clientId}`);
    console.log(`Subject: ${options.subject}`);
    console.log(`Scopes: ${scopes.join(' ')}`);
    return;
  }

  const nowSeconds = Math.floor(Date.now() / 1000);
  const assertion = serviceAccount
    ? jwtAssertion(serviceAccount, options.subject, scopes, nowSeconds)
    : await signJwtWithIamCredentials(
        clientEmail,
        jwtPayload(clientEmail, options.subject, scopes, nowSeconds),
        readUnexpiredToken(options['signer-token']).access_token,
      );
  const token = await exchangeAssertion(assertion);
  const expiresIn = Number(token.expires_in || 3600);
  const out = {
    access_token: token.access_token,
    scope: token.scope || scopes.join(' '),
    token_type: token.token_type || 'Bearer',
    expires_at: formatUtc(nowSeconds + expiresIn),
    obtained_at: formatUtc(nowSeconds),
    delegated_subject: options.subject,
  };
  fs.mkdirSync(path.dirname(options.token), { recursive: true });
  fs.writeFileSync(options.token, `${JSON.stringify(out, null, 2)}\n`);
  console.log(`Wrote delegated Google Keep token: ${options.token}`);
  console.log(`Delegated subject: ${options.subject}`);
  console.log(`Expires at: ${out.expires_at}`);
}

main().catch((error) => {
  console.error(error.message);
  console.error(usage());
  process.exit(1);
});