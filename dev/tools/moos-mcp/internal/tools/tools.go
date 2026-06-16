// Package tools registers the mo:os MCP tools and resources on an MCP server.
//
// Reads (moos_healthz, moos_get_node, ...) map to the kernel's GET endpoints;
// writes (moos_apply and the moos_add/link/mutate/unlink convenience builders)
// map to the atomic POST /programs. The supplied actor is stamped onto write
// envelopes that omit one — but §M11 still requires that actor to match the
// session's seated has-occupant, or the kernel rejects the program.
package tools

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"

	"github.com/Collider-Data-Systems/moos-mcp/internal/kernel"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

// Register wires every tool and resource onto s. defaultActor (may be "") is the
// fallback actor URN for write envelopes that don't carry their own.
func Register(s *server.MCPServer, kc *kernel.Client, defaultActor string) {
	registerReads(s, kc)
	registerWrites(s, kc, defaultActor)
	registerResources(s, kc)
}

// --- reads -------------------------------------------------------------------

func registerReads(s *server.MCPServer, kc *kernel.Client) {
	s.AddTool(mcp.NewTool("moos_healthz",
		mcp.WithDescription("GET /healthz — kernel liveness: status, ontology_version, t_day, log_len."),
	), func(ctx context.Context, _ mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		return passthrough(kc.Healthz(ctx))
	})

	s.AddTool(mcp.NewTool("moos_get_node",
		mcp.WithDescription("GET /state/nodes/{urn} — folded state of one node by URN."),
		mcp.WithString("urn", mcp.Required(), mcp.Description("Node URN, e.g. urn:moos:session:sam.governance")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		urn := argStr(req, "urn")
		if urn == "" {
			return mcp.NewToolResultError("urn is required"), nil
		}
		return passthrough(kc.GetNode(ctx, urn))
	})

	s.AddTool(mcp.NewTool("moos_list_nodes",
		mcp.WithDescription("GET /state/nodes — all nodes; optionally filter by type_id (client-side)."),
		mcp.WithString("type_id", mcp.Description("Optional node type to keep, e.g. session, agent, purpose.")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		raw, err := kc.ListNodes(ctx)
		if err != nil {
			return mcp.NewToolResultError(err.Error()), nil
		}
		if t := argStr(req, "type_id"); t != "" {
			raw = filterByTypeID(raw, t)
		}
		return mcp.NewToolResultText(pretty(raw)), nil
	})

	s.AddTool(mcp.NewTool("moos_query_relations",
		mcp.WithDescription("GET /state/relations (all) or /state/relations/src/{urn} (outbound from a node)."),
		mcp.WithString("src_urn", mcp.Description("Optional source node URN to scope the query.")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		if src := argStr(req, "src_urn"); src != "" {
			return passthrough(kc.RelationsBySrc(ctx, src))
		}
		return passthrough(kc.Relations(ctx))
	})

	s.AddTool(mcp.NewTool("moos_node_types",
		mcp.WithDescription("GET /operad/node-types — the node type registry (operad)."),
	), func(ctx context.Context, _ mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		return passthrough(kc.NodeTypes(ctx))
	})

	s.AddTool(mcp.NewTool("moos_rewrite_categories",
		mcp.WithDescription("GET /operad/rewrite-categories — the WF01..WF21 registry (operad)."),
	), func(ctx context.Context, _ mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		return passthrough(kc.RewriteCategories(ctx))
	})
}

// --- writes ------------------------------------------------------------------

const applySchema = `{
  "type": "object",
  "properties": {
    "envelopes": {
      "type": "array",
      "items": { "type": "object" },
      "description": "Rewrite envelopes (ADD/LINK/MUTATE/UNLINK), applied atomically."
    },
    "actor": { "type": "string", "description": "Default actor URN for envelopes missing one." },
    "session_urn": { "type": "string", "description": "Optional session context for ambiguous-session actors." }
  },
  "required": ["envelopes"]
}`

func registerWrites(s *server.MCPServer, kc *kernel.Client, defaultActor string) {
	s.AddTool(mcp.NewToolWithRawSchema("moos_apply",
		"POST /programs — apply a batch of rewrite envelopes atomically (all-or-nothing). Returns {applied, log_seq, applied_count, error}.",
		json.RawMessage(applySchema),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := req.GetArguments()
		rawEnv, ok := args["envelopes"].([]any)
		if !ok || len(rawEnv) == 0 {
			return mcp.NewToolResultError("envelopes must be a non-empty array of envelope objects"), nil
		}
		actor := firstNonEmpty(asString(args["actor"]), defaultActor)
		session := asString(args["session_urn"])
		envs := make([]kernel.Envelope, 0, len(rawEnv))
		for i, item := range rawEnv {
			m, ok := item.(map[string]any)
			if !ok {
				return mcp.NewToolResultError(fmt.Sprintf("envelopes[%d] is not an object", i)), nil
			}
			e := kernel.Envelope(m)
			if asString(e["actor"]) == "" && actor != "" {
				e["actor"] = actor
			}
			if session != "" && asString(e["session_urn"]) == "" {
				e["session_urn"] = session
			}
			envs = append(envs, e)
		}
		return passthrough(kc.ApplyProgram(ctx, envs))
	})

	s.AddTool(mcp.NewTool("moos_add",
		mcp.WithDescription("Convenience: emit one ADD envelope (create a node) via POST /programs."),
		mcp.WithString("node_urn", mcp.Required(), mcp.Description("URN of the new node.")),
		mcp.WithString("type_id", mcp.Required(), mcp.Description("Node type, e.g. session, purpose, channel.")),
		mcp.WithObject("properties", mcp.Description("Properties map {name:{value,mutability,authority_scope,stratum_origin}}.")),
		mcp.WithString("actor", mcp.Description("Actor URN (defaults to the server's --actor).")),
		mcp.WithString("session_urn", mcp.Description("Optional session context.")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := req.GetArguments()
		env := kernel.Envelope{
			"rewrite_type": "ADD",
			"actor":        firstNonEmpty(asString(args["actor"]), defaultActor),
			"node_urn":     asString(args["node_urn"]),
			"type_id":      asString(args["type_id"]),
		}
		if p, ok := args["properties"]; ok && p != nil {
			env["properties"] = p
		}
		if sess := asString(args["session_urn"]); sess != "" {
			env["session_urn"] = sess
		}
		return passthrough(kc.ApplyProgram(ctx, []kernel.Envelope{env}))
	})

	s.AddTool(mcp.NewTool("moos_link",
		mcp.WithDescription("Convenience: emit one LINK envelope (create a relation) via POST /programs."),
		mcp.WithString("relation_urn", mcp.Required()),
		mcp.WithString("src_urn", mcp.Required()),
		mcp.WithString("src_port", mcp.Required()),
		mcp.WithString("tgt_urn", mcp.Required()),
		mcp.WithString("tgt_port", mcp.Required()),
		mcp.WithString("rewrite_category", mcp.Required(), mcp.Description("WF id, e.g. WF19.")),
		mcp.WithString("actor"),
		mcp.WithString("session_urn"),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		a := req.GetArguments()
		env := kernel.NewLink(
			firstNonEmpty(asString(a["actor"]), defaultActor),
			asString(a["relation_urn"]), asString(a["src_urn"]), asString(a["src_port"]),
			asString(a["tgt_urn"]), asString(a["tgt_port"]), asString(a["rewrite_category"]),
			asString(a["session_urn"]),
		)
		return passthrough(kc.ApplyProgram(ctx, []kernel.Envelope{env}))
	})

	s.AddTool(mcp.NewTool("moos_mutate",
		mcp.WithDescription("Convenience: emit one MUTATE envelope (change one field) via POST /programs."),
		mcp.WithString("target_urn", mcp.Required()),
		mcp.WithString("field", mcp.Required()),
		mcp.WithString("new_value", mcp.Required(), mcp.Description("New value (string; numbers/bools accepted as strings).")),
		mcp.WithString("rewrite_category", mcp.Description("WF id; omit for an additive MUTATE.")),
		mcp.WithString("actor"),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		a := req.GetArguments()
		env := kernel.NewMutate(
			firstNonEmpty(asString(a["actor"]), defaultActor),
			asString(a["target_urn"]), asString(a["field"]), a["new_value"], asString(a["rewrite_category"]),
		)
		return passthrough(kc.ApplyProgram(ctx, []kernel.Envelope{env}))
	})

	s.AddTool(mcp.NewTool("moos_unlink",
		mcp.WithDescription("Convenience: emit one UNLINK envelope (remove a relation) via POST /programs."),
		mcp.WithString("relation_urn", mcp.Required()),
		mcp.WithString("rewrite_category", mcp.Description("Optional; inferred from the existing relation if omitted.")),
		mcp.WithString("actor"),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		a := req.GetArguments()
		env := kernel.NewUnlink(
			firstNonEmpty(asString(a["actor"]), defaultActor),
			asString(a["relation_urn"]), asString(a["rewrite_category"]),
		)
		return passthrough(kc.ApplyProgram(ctx, []kernel.Envelope{env}))
	})
}

// --- resources ---------------------------------------------------------------

func registerResources(s *server.MCPServer, kc *kernel.Client) {
	s.AddResource(mcp.NewResource("moos://healthz", "kernel-healthz",
		mcp.WithResourceDescription("Kernel liveness JSON (GET /healthz)."),
		mcp.WithMIMEType("application/json"),
	), func(ctx context.Context, _ mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {
		raw, err := kc.Healthz(ctx)
		if err != nil {
			return nil, err
		}
		return jsonResource("moos://healthz", raw), nil
	})

	s.AddResource(mcp.NewResource("moos://state/nodes", "kernel-nodes",
		mcp.WithResourceDescription("All folded nodes (GET /state/nodes)."),
		mcp.WithMIMEType("application/json"),
	), func(ctx context.Context, _ mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {
		raw, err := kc.ListNodes(ctx)
		if err != nil {
			return nil, err
		}
		return jsonResource("moos://state/nodes", raw), nil
	})

	s.AddResourceTemplate(mcp.NewResourceTemplate("moos://node/{urn}", "kernel-node",
		mcp.WithTemplateDescription("One folded node by URN (GET /state/nodes/{urn})."),
		mcp.WithTemplateMIMEType("application/json"),
	), func(ctx context.Context, req mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {
		urn := trimPrefix(req.Params.URI, "moos://node/")
		raw, err := kc.GetNode(ctx, urn)
		if err != nil {
			return nil, err
		}
		return jsonResource(req.Params.URI, raw), nil
	})
}

// --- helpers -----------------------------------------------------------------

func passthrough(raw json.RawMessage, err error) (*mcp.CallToolResult, error) {
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	return mcp.NewToolResultText(pretty(raw)), nil
}

func jsonResource(uri string, raw json.RawMessage) []mcp.ResourceContents {
	return []mcp.ResourceContents{mcp.TextResourceContents{
		URI:      uri,
		MIMEType: "application/json",
		Text:     pretty(raw),
	}}
}

func pretty(raw json.RawMessage) string {
	var buf bytes.Buffer
	if err := json.Indent(&buf, raw, "", "  "); err != nil {
		return string(raw)
	}
	return buf.String()
}

func argStr(req mcp.CallToolRequest, key string) string {
	return asString(req.GetArguments()[key])
}

func asString(v any) string {
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}

func trimPrefix(s, prefix string) string {
	if len(s) >= len(prefix) && s[:len(prefix)] == prefix {
		return s[len(prefix):]
	}
	return s
}

// filterByTypeID keeps only nodes whose "type_id" equals t. On any parse issue it
// returns the input unchanged (the filter is a convenience, not a guarantee).
func filterByTypeID(raw json.RawMessage, t string) json.RawMessage {
	var nodes []map[string]any
	if err := json.Unmarshal(raw, &nodes); err != nil {
		return raw
	}
	kept := make([]map[string]any, 0, len(nodes))
	for _, n := range nodes {
		if asString(n["type_id"]) == t {
			kept = append(kept, n)
		}
	}
	out, err := json.Marshal(kept)
	if err != nil {
		return raw
	}
	return out
}
