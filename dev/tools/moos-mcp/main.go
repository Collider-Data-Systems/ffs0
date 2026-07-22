// Command moos-mcp is a Model Context Protocol server that exposes one mo:os
// kernel to any MCP-capable IDE/agent (Claude Code, VS Code, Antigravity).
//
// Reads map to the kernel's GET endpoints; writes map to the atomic POST /programs.
// It speaks MCP over stdio.
//
// Usage:
//
//	moos-mcp [--base-url http://localhost:8000] [--actor urn:moos:agent:...] [--auth-token-file path]
//
// Env fallbacks: MOOS_BASE_URL, MOOS_ACTOR, MOOS_AUTH_TOKEN.
package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/Collider-Data-Systems/moos-mcp/internal/kernel"
	"github.com/Collider-Data-Systems/moos-mcp/internal/tools"
	"github.com/mark3labs/mcp-go/server"
)

const version = "0.1.0"

func main() {
	baseURL := flag.String("base-url", envOr("MOOS_BASE_URL", "http://localhost:8000"),
		"Kernel base URL (or MOOS_BASE_URL).")
	actor := flag.String("actor", os.Getenv("MOOS_ACTOR"),
		"Default actor URN stamped onto write envelopes (or MOOS_ACTOR).")
	authTokenFile := flag.String("auth-token-file", "",
		"File holding the kernel bearer token for write routes (moos-kernel #60). "+
			"MOOS_AUTH_TOKEN env is the fallback; empty = no Authorization header (pre-#60 kernels).")
	flag.Parse()

	authToken := strings.TrimSpace(os.Getenv("MOOS_AUTH_TOKEN"))
	if *authTokenFile != "" {
		raw, err := os.ReadFile(*authTokenFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "moos-mcp: auth-token-file: %v\n", err)
			os.Exit(1)
		}
		authToken = strings.TrimSpace(string(raw))
	}

	kc := kernel.New(*baseURL)
	kc.AuthToken = authToken

	s := server.NewMCPServer("moos-mcp", version,
		server.WithToolCapabilities(true),
		server.WithResourceCapabilities(true, true),
		server.WithInstructions(
			"mo:os kernel bridge. Reads: moos_healthz, moos_get_node, moos_list_nodes, "+
				"moos_query_relations, moos_node_types, moos_rewrite_categories. Writes "+
				"(atomic POST /programs): moos_apply, moos_add, moos_link, moos_mutate, "+
				"moos_unlink. The four rewrites ADD/LINK/MUTATE/UNLINK are the only mutations; "+
				"log is truth, state is derived. Writes require an actor that matches the "+
				"session's seated has-occupant (§M11).",
		),
	)

	tools.Register(s, kc, *actor)

	if err := server.ServeStdio(s); err != nil {
		fmt.Fprintf(os.Stderr, "moos-mcp: %v\n", err)
		os.Exit(1)
	}
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
