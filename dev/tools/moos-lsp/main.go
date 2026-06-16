// Command moos-lsp is a Language Server for mo:os rewrite envelopes / programs.
//
// It gives any LSP editor (VS Code, Neovim, Zed, Emacs) live ontology intelligence:
//   - diagnostics: operad violations (unknown type, WF that doesn't allow the
//     rewrite, undeclared port pair, src/tgt type mismatch, malformed URN) plus
//     forbidden-vocabulary lint;
//   - completion: rewrite types, node types, WF ids, port names, envelope keys;
//   - hover: WF/type/port/URN docs from the generated ontology tables, with
//     optional live folded state when --base-url is set.
//
// Symbol tables are generated from kb/superset/ontology.json:
//
//	go run ./internal/ontology/gen -ontology ../../../kb/superset/ontology.json -out internal/ontology/symbols.go
package main

import (
	"flag"
	"os"

	"github.com/Collider-Data-Systems/moos-lsp/internal/handlers"
	"github.com/tliron/commonlog"
	_ "github.com/tliron/commonlog/simple"
	"github.com/tliron/glsp"
	protocol "github.com/tliron/glsp/protocol_3_16"
	glspserver "github.com/tliron/glsp/server"
)

const lsName = "moos-lsp"

var (
	version = "0.1.0"
	handler protocol.Handler
)

func main() {
	flag.StringVar(&handlers.KernelBaseURL, "base-url", os.Getenv("MOOS_BASE_URL"),
		"Optional kernel base URL for live URN hover (or MOOS_BASE_URL).")
	flag.Parse()

	commonlog.Configure(1, nil)

	handler = protocol.Handler{
		Initialize:             initialize,
		Initialized:            initialized,
		Shutdown:               shutdown,
		SetTrace:               setTrace,
		TextDocumentDidOpen:    didOpen,
		TextDocumentDidChange:  didChange,
		TextDocumentDidClose:   didClose,
		TextDocumentCompletion: completion,
		TextDocumentHover:      hover,
	}

	server := glspserver.NewServer(&handler, lsName, false)
	_ = server.RunStdio()
}

func initialize(_ *glsp.Context, _ *protocol.InitializeParams) (any, error) {
	caps := handler.CreateServerCapabilities()
	caps.TextDocumentSync = protocol.TextDocumentSyncKindFull
	caps.CompletionProvider = &protocol.CompletionOptions{TriggerCharacters: []string{"\"", ":", " "}}
	caps.HoverProvider = true
	return protocol.InitializeResult{
		Capabilities: caps,
		ServerInfo:   &protocol.InitializeResultServerInfo{Name: lsName, Version: &version},
	}, nil
}

func initialized(_ *glsp.Context, _ *protocol.InitializedParams) error { return nil }

func shutdown(_ *glsp.Context) error {
	protocol.SetTraceValue(protocol.TraceValueOff)
	return nil
}

func setTrace(_ *glsp.Context, params *protocol.SetTraceParams) error {
	protocol.SetTraceValue(params.Value)
	return nil
}

func didOpen(ctx *glsp.Context, params *protocol.DidOpenTextDocumentParams) error {
	handlers.Docs.Set(params.TextDocument.URI, params.TextDocument.Text)
	publish(ctx, params.TextDocument.URI)
	return nil
}

func didChange(ctx *glsp.Context, params *protocol.DidChangeTextDocumentParams) error {
	uri := params.TextDocument.URI
	for _, ch := range params.ContentChanges {
		switch c := ch.(type) {
		case protocol.TextDocumentContentChangeEventWhole:
			handlers.Docs.Set(uri, c.Text)
		case protocol.TextDocumentContentChangeEvent:
			handlers.Docs.Set(uri, c.Text)
		}
	}
	publish(ctx, uri)
	return nil
}

func didClose(_ *glsp.Context, params *protocol.DidCloseTextDocumentParams) error {
	handlers.Docs.Delete(params.TextDocument.URI)
	return nil
}

func completion(_ *glsp.Context, params *protocol.CompletionParams) (any, error) {
	text, ok := handlers.Docs.Get(params.TextDocument.URI)
	if !ok {
		return nil, nil
	}
	return handlers.Complete(text, params.Position), nil
}

func hover(_ *glsp.Context, params *protocol.HoverParams) (*protocol.Hover, error) {
	text, ok := handlers.Docs.Get(params.TextDocument.URI)
	if !ok {
		return nil, nil
	}
	return handlers.Hover(text, params.Position), nil
}

func publish(ctx *glsp.Context, uri protocol.DocumentUri) {
	text, _ := handlers.Docs.Get(uri)
	ctx.Notify(string(protocol.ServerTextDocumentPublishDiagnostics), protocol.PublishDiagnosticsParams{
		URI:         uri,
		Diagnostics: handlers.Analyze(text),
	})
}
