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
  const serverPath = config.get<string>("serverPath", "moos-lsp");
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
