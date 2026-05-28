#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { spawn } from 'node:child_process';

const DEFAULT_CREDENTIALS_PATH = 'secrets/google_calendar_oauth_client.json';
const DEFAULT_TOKEN_PATH = 'secrets/google_cloud_token.json';
const DEFAULT_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';
const AUTH_URI = 'https://accounts.google.com/o/oauth2/v2/auth';
const TOKEN_URI = 'https://oauth2.googleapis.com/token';

function usage() {
  return `Usage: node dev/scripts/google_oauth_loopback_token.mjs [options]\n\nOptions:\n  --credentials <path>  OAuth client JSON path (default: ${DEFAULT_CREDENTIALS_PATH})\n  --token <path>        Output token cache path (default: ${DEFAULT_TOKEN_PATH})\n  --scope <scopes>      Space/comma separated OAuth scopes (default: ${DEFAULT_SCOPE})\n  --login-hint <email>  Preferred Google account for consent\n  --open-browser true   Open the consent URL in the default browser\n`;
}

function parseArgs(argv) {
  const options = {
    credentials: DEFAULT_CREDENTIALS_PATH,
    token: DEFAULT_TOKEN_PATH,
    scope: DEFAULT_SCOPE,
    'login-hint': '',
    'open-browser': 'false',
  };
  for (let i = 0; i < argv.length; i += 2) {
    const flag = argv[i];
    if (!flag?.startsWith('--')) throw new Error(`unexpected argument: ${flag ?? ''}`);
    const name = flag.slice(2);
    if (!(name in options)) throw new Error(`unknown option: ${flag}`);
    if (i + 1 >= argv.length) throw new Error(`missing value for ${flag}`);
    options[name] = argv[i + 1];
  }
  return options;
}

function boolValue(value) {
  return ['1', 'true', 'yes', 'y'].includes(String(value).trim().toLowerCase());
}

function parseScopes(scopeText) {
  return String(scopeText).split(/[\s,]+/).map((scope) => scope.trim()).filter(Boolean);
}

function loadClient(credentialsPath) {
  const raw = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
  const client = raw.installed || raw.web || raw;
  for (const key of ['client_id', 'client_secret']) {
    if (typeof client[key] !== 'string' || client[key].trim() === '') {
      throw new Error(`OAuth client is missing ${key}`);
    }
  }
  return client;
}

function formatUtc(seconds) {
  return new Date(seconds * 1000).toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function openBrowser(url) {
  const command = process.platform === 'win32' ? 'cmd' : process.platform === 'darwin' ? 'open' : 'xdg-open';
  const args = process.platform === 'win32' ? ['/c', 'start', '', url] : [url];
  const child = spawn(command, args, { detached: true, stdio: 'ignore' });
  child.unref();
}

function waitForCode(server) {
  return new Promise((resolve, reject) => {
    server.on('request', (request, response) => {
      try {
        const url = new URL(request.url, 'http://127.0.0.1');
        const code = url.searchParams.get('code');
        const error = url.searchParams.get('error');
        if (error) {
          response.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
          response.end(`OAuth error: ${error}`);
          reject(new Error(`OAuth error: ${error}`));
          return;
        }
        if (!code) {
          response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
          response.end('Missing OAuth code.');
          return;
        }
        response.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
        response.end('Google OAuth completed. You can close this tab.');
        resolve(code);
      } catch (error) {
        reject(error);
      }
    });
  });
}

async function exchangeCode(client, redirectUri, code) {
  const body = new URLSearchParams({
    client_id: client.client_id,
    client_secret: client.client_secret,
    code,
    grant_type: 'authorization_code',
    redirect_uri: redirectUri,
  });
  const response = await fetch(TOKEN_URI, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const text = await response.text();
  const parsed = text.trim() === '' ? {} : JSON.parse(text);
  if (!response.ok) {
    const message = parsed.error_description || parsed.error || response.statusText;
    throw new Error(`HTTP ${response.status} from ${TOKEN_URI}: ${message}`);
  }
  return parsed;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const client = loadClient(options.credentials);
  const scopes = parseScopes(options.scope);
  if (scopes.length === 0) throw new Error('--scope must include at least one scope');

  const server = http.createServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  const redirectUri = `http://127.0.0.1:${port}/`;
  const state = crypto.randomBytes(18).toString('base64url');
  const authUrl = new URL(AUTH_URI);
  authUrl.searchParams.set('client_id', client.client_id);
  authUrl.searchParams.set('redirect_uri', redirectUri);
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('scope', scopes.join(' '));
  authUrl.searchParams.set('access_type', 'offline');
  authUrl.searchParams.set('prompt', 'consent');
  authUrl.searchParams.set('include_granted_scopes', 'true');
  authUrl.searchParams.set('state', state);
  if (String(options['login-hint']).trim() !== '') {
    authUrl.searchParams.set('login_hint', String(options['login-hint']).trim());
  }

  console.log(`Listening for Google OAuth redirect on ${redirectUri}`);
  console.log('Open this URL to approve access:');
  console.log(authUrl.toString());
  if (boolValue(options['open-browser'])) openBrowser(authUrl.toString());

  try {
    const code = await waitForCode(server);
    const nowSeconds = Math.floor(Date.now() / 1000);
    const token = await exchangeCode(client, redirectUri, code);
    const expiresIn = Number(token.expires_in || 3600);
    const out = {
      access_token: token.access_token,
      refresh_token: token.refresh_token,
      scope: token.scope || scopes.join(' '),
      token_type: token.token_type || 'Bearer',
      expires_at: formatUtc(nowSeconds + expiresIn),
      obtained_at: formatUtc(nowSeconds),
      client_id: client.client_id,
    };
    fs.mkdirSync(path.dirname(options.token), { recursive: true });
    fs.writeFileSync(options.token, `${JSON.stringify(out, null, 2)}\n`);
    console.log(`Wrote Google OAuth token: ${options.token}`);
    console.log(`Expires at: ${out.expires_at}`);
  } finally {
    server.close();
  }
}

main().catch((error) => {
  console.error(error.message);
  console.error(usage());
  process.exit(1);
});
