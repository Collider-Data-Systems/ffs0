import * as fs from "fs";
import * as path from "path";
import * as vscode from "vscode";
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";

let client: LanguageClient | undefined;

export function activate(context: vscode.ExtensionContext): void {
  const config = vscode.workspace.getConfiguration("moos");
  const serverPath = resolveServerPath(config.get<string>("serverPath", "moos-lsp"));
  const baseUrl = config.get<string>("baseUrl", "");

  const args: string[] = [];
  if (baseUrl) {
    args.push("--base-url", baseUrl);
  }

  const serverOptions: ServerOptions = {
    command: serverPath,
    args,
    transport: TransportKind.stdio,
  };

  // Apply to JSON envelope/program files and .moos files. Narrow the JSON scope in
  // your own settings if it is too broad for your repo.
  const clientOptions: LanguageClientOptions = {
    documentSelector: [
      { scheme: "file", language: "json", pattern: "**/*.{program,envelope,moos}.json" },
      { scheme: "file", language: "moos" },
    ],
  };

  client = new LanguageClient("moos", "mo:os LSP", serverOptions, clientOptions);
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}

function resolveWorkspaceVariables(value: string): string {
  return value.replace(/\$\{workspaceFolder(?::([^}]+))?\}/g, (_match, folderName: string | undefined) => {
    const folders = vscode.workspace.workspaceFolders ?? [];
    const folder = folderName
      ? folders.find((candidate) => candidate.name === folderName)
      : folders[0];
    return folder?.uri.fsPath ?? _match;
  });
}

function resolveServerPath(value: string): string {
  const resolved = resolveWorkspaceVariables(value);
  if (resolved === "moos-lsp") {
    return findWorkspaceServerBinary() ?? resolved;
  }
  if (!looksLikeFilePath(resolved) || fs.existsSync(resolved)) {
    return resolved;
  }

  const workspaceServerPath = findWorkspaceServerBinary();
  if (workspaceServerPath) {
    void vscode.window.showWarningMessage(
      `mo:os LSP: configured moos.serverPath does not exist (${resolved}) — likely a stale synced user setting; clear or fix it. Using workspace server: ${workspaceServerPath}`,
    );
    return workspaceServerPath;
  }

  void vscode.window.showWarningMessage(
    `mo:os LSP: configured moos.serverPath does not exist (${resolved}) and no workspace server binary was found — clear or fix the setting. Falling back to moos-lsp on PATH.`,
  );
  return "moos-lsp";
}

function looksLikeFilePath(value: string): boolean {
  return path.isAbsolute(value) || value.includes("/") || value.includes("\\") || value.startsWith(".");
}

function findWorkspaceServerBinary(): string | undefined {
  const executableName = process.platform === "win32" ? "moos-lsp.exe" : "moos-lsp";
  const folders = vscode.workspace.workspaceFolders ?? [];
  for (const folder of folders) {
    const roots = [folder.uri.fsPath, path.join(folder.uri.fsPath, "ffs0")];
    for (const root of roots) {
      const candidatePath = path.join(root, "dev", "tools", "moos-lsp", executableName);
      if (fs.existsSync(candidatePath)) {
        return candidatePath;
      }
    }
  }
  return undefined;
}
