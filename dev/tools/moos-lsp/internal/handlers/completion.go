package handlers

import (
	"strings"

	"github.com/Collider-Data-Systems/moos-lsp/internal/ontology"
	protocol "github.com/tliron/glsp/protocol_3_16"
)

// envelopeKeys are the fields offered when not inside a known value position.
var envelopeKeys = []string{
	"rewrite_type", "actor", "session_urn", "node_urn", "type_id", "properties",
	"relation_urn", "src_urn", "src_port", "tgt_urn", "tgt_port", "rewrite_category",
	"target_urn", "field", "new_value",
}

// Complete returns context-aware completion items based on which envelope field
// the cursor's line is editing.
func Complete(text string, pos protocol.Position) []protocol.CompletionItem {
	line := lineAt(text, pos.Line)

	switch {
	case lineHasKey(line, "rewrite_type"):
		return items(ontology.RewriteTypes, protocol.CompletionItemKindEnumMember, "rewrite opcode")
	case lineHasKey(line, "type_id"):
		return nodeTypeItems()
	case lineHasKey(line, "rewrite_category"):
		return wfItems()
	case lineHasKey(line, "src_port"), lineHasKey(line, "tgt_port"):
		return portItems()
	default:
		return items(envelopeKeys, protocol.CompletionItemKindProperty, "envelope field")
	}
}

// lineHasKey reports whether the line is editing the value of "key" (the key
// appears before the cursor, followed by a colon).
func lineHasKey(line, key string) bool {
	i := strings.Index(line, `"`+key+`"`)
	if i < 0 {
		return false
	}
	return strings.Contains(line[i+len(key)+2:], ":")
}

func nodeTypeItems() []protocol.CompletionItem {
	out := make([]protocol.CompletionItem, 0, len(ontology.NodeTypeIDs))
	for _, id := range ontology.NodeTypeIDs {
		nt := ontology.NodeTypes[id]
		out = append(out, item(id, protocol.CompletionItemKindClass, nt.Stratum+" · "+nt.URNPattern))
	}
	return out
}

func wfItems() []protocol.CompletionItem {
	out := make([]protocol.CompletionItem, 0, len(ontology.WFOrder))
	for _, id := range ontology.WFOrder {
		w := ontology.WFs[id]
		out = append(out, item(id, protocol.CompletionItemKindEnum,
			w.Name+" · allows "+strings.Join(w.AllowedRewrites, "/")))
	}
	return out
}

func portItems() []protocol.CompletionItem {
	out := make([]protocol.CompletionItem, 0, len(ontology.KnownPorts))
	for port := range ontology.KnownPorts {
		detail := "port"
		if wf, ok := ontology.SrcPortToWF[port]; ok {
			detail = "port · " + wf
		}
		out = append(out, item(port, protocol.CompletionItemKindValue, detail))
	}
	return out
}

func items(labels []string, kind protocol.CompletionItemKind, detail string) []protocol.CompletionItem {
	out := make([]protocol.CompletionItem, 0, len(labels))
	for _, l := range labels {
		out = append(out, item(l, kind, detail))
	}
	return out
}

func item(label string, kind protocol.CompletionItemKind, detail string) protocol.CompletionItem {
	k := kind
	d := detail
	return protocol.CompletionItem{Label: label, Kind: &k, Detail: &d}
}
