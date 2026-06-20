package handlers

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/Collider-Data-Systems/moos-lsp/internal/ontology"
	protocol "github.com/tliron/glsp/protocol_3_16"
)

const source = "moos-lsp"

// noisyForbidden are forbidden tokens too generic to lint in free text without
// false positives; they remain available for hover, just not for diagnostics.
var noisyForbidden = map[string]bool{"object": true, "kind": true, "transition": true}

// Analyze returns diagnostics for one document's full text. It validates mo:os
// rewrite envelopes (single, array, or {envelopes:[...]} program) against the
// generated operad tables, and lints forbidden vocabulary.
func Analyze(text string) []protocol.Diagnostic {
	var diags []protocol.Diagnostic
	if envs, ok := extractEnvelopes(text); ok {
		for _, e := range envs {
			diags = append(diags, validateEnvelope(text, e)...)
		}
	}
	diags = append(diags, forbiddenVocab(text)...)
	return diags
}

// extractEnvelopes pulls envelope objects out of an array, a single envelope, or a
// program wrapper carrying an "envelopes" array (e.g. the ops *.program.json files).
func extractEnvelopes(text string) ([]map[string]any, bool) {
	trimmed := strings.TrimSpace(text)
	if trimmed == "" {
		return nil, false
	}
	switch trimmed[0] {
	case '[':
		var arr []map[string]any
		if json.Unmarshal([]byte(trimmed), &arr) == nil {
			return arr, true
		}
	case '{':
		var obj map[string]any
		if json.Unmarshal([]byte(trimmed), &obj) != nil {
			return nil, false
		}
		if raw, ok := obj["envelopes"]; ok {
			if arr, ok := toMapSlice(raw); ok {
				return arr, true
			}
		}
		if _, ok := obj["rewrite_type"]; ok {
			return []map[string]any{obj}, true
		}
	}
	return nil, false
}

func toMapSlice(v any) ([]map[string]any, bool) {
	arr, ok := v.([]any)
	if !ok {
		return nil, false
	}
	out := make([]map[string]any, 0, len(arr))
	for _, item := range arr {
		if m, ok := item.(map[string]any); ok {
			out = append(out, m)
		}
	}
	return out, true
}

func validateEnvelope(text string, e map[string]any) []protocol.Diagnostic {
	var d []protocol.Diagnostic
	rt := str(e["rewrite_type"])
	if rt == "" {
		d = append(d, diag(protocol.DiagnosticSeverityError, locate(text, "rewrite_type"), "envelope is missing rewrite_type"))
		return d
	}
	if !contains(ontology.RewriteTypes, rt) {
		d = append(d, diag(protocol.DiagnosticSeverityError, locate(text, q(rt)),
			fmt.Sprintf("unknown rewrite_type %q; expected one of ADD, LINK, MUTATE, UNLINK", rt)))
		return d
	}

	switch rt {
	case "ADD":
		typeID := str(e["type_id"])
		if typeID == "" {
			d = append(d, diag(protocol.DiagnosticSeverityError, locate(text, "type_id"), "ADD envelope is missing type_id"))
		} else if _, ok := ontology.NodeTypes[typeID]; !ok {
			d = append(d, diag(protocol.DiagnosticSeverityError, locate(text, q(typeID)),
				fmt.Sprintf("unknown node type %q (not in the operad)", typeID)))
		}
		d = append(d, checkURN(text, "node_urn", str(e["node_urn"]), true)...)

	case "LINK":
		wf := str(e["rewrite_category"])
		d = append(d, checkWF(text, wf, "LINK")...)
		d = append(d, checkPortsAndTypes(text, e, wf)...)
		d = append(d, checkURN(text, "src_urn", str(e["src_urn"]), true)...)
		d = append(d, checkURN(text, "tgt_urn", str(e["tgt_urn"]), true)...)
		d = append(d, checkURN(text, "relation_urn", str(e["relation_urn"]), true)...)

	case "MUTATE":
		if wf := str(e["rewrite_category"]); wf != "" {
			d = append(d, checkWF(text, wf, "MUTATE")...)
		}
		d = append(d, checkURN(text, "target_urn", str(e["target_urn"]), true)...)

	case "UNLINK":
		if wf := str(e["rewrite_category"]); wf != "" {
			d = append(d, checkWF(text, wf, "UNLINK")...)
		}
		d = append(d, checkURN(text, "relation_urn", str(e["relation_urn"]), true)...)
	}
	return d
}

// checkWF verifies the WF exists and permits the given rewrite type.
func checkWF(text, wf, rt string) []protocol.Diagnostic {
	if wf == "" {
		return []protocol.Diagnostic{diag(protocol.DiagnosticSeverityError, locate(text, "rewrite_category"),
			fmt.Sprintf("%s envelope is missing rewrite_category", rt))}
	}
	w, ok := ontology.WFs[wf]
	if !ok {
		return []protocol.Diagnostic{diag(protocol.DiagnosticSeverityError, locate(text, q(wf)),
			fmt.Sprintf("unknown rewrite_category %q (expected WF01..WF21)", wf))}
	}
	if !contains(w.AllowedRewrites, rt) {
		return []protocol.Diagnostic{diag(protocol.DiagnosticSeverityError, locate(text, q(wf)),
			fmt.Sprintf("%s (%s) does not allow %s; allowed: %s", wf, w.Name, rt, strings.Join(w.AllowedRewrites, ", ")))}
	}
	return nil
}

// checkPortsAndTypes checks a LINK's (src_port,tgt_port) against the WF's declared
// pairs, and the src/tgt URN types against the WF's src_types/tgt_types.
func checkPortsAndTypes(text string, e map[string]any, wf string) []protocol.Diagnostic {
	w, ok := ontology.WFs[wf]
	if !ok {
		return nil
	}
	var d []protocol.Diagnostic
	sp, tp := str(e["src_port"]), str(e["tgt_port"])
	if len(w.PortPairs) > 0 && (sp != "" || tp != "") && !pairDeclared(w, sp, tp) {
		d = append(d, diag(protocol.DiagnosticSeverityWarning, locate(text, q(sp)),
			fmt.Sprintf("(%s → %s) is not a declared port pair of %s; expected one of %s", sp, tp, wf, pairsString(w))))
	}
	if st := urnType(str(e["src_urn"])); st != "" && !typeAllowed(w.SrcTypes, st) {
		d = append(d, diag(protocol.DiagnosticSeverityWarning, locate(text, q(str(e["src_urn"]))),
			fmt.Sprintf("src type %q not allowed by %s (src_types: %s)", st, wf, strings.Join(w.SrcTypes, ", "))))
	}
	if tt := urnType(str(e["tgt_urn"])); tt != "" && !typeAllowed(w.TgtTypes, tt) {
		d = append(d, diag(protocol.DiagnosticSeverityWarning, locate(text, q(str(e["tgt_urn"]))),
			fmt.Sprintf("tgt type %q not allowed by %s (tgt_types: %s)", tt, wf, strings.Join(w.TgtTypes, ", "))))
	}
	return d
}

// checkURN validates a urn:moos:<type>:... string's shape and type segment.
func checkURN(text, field, urn string, required bool) []protocol.Diagnostic {
	if urn == "" {
		if required {
			return []protocol.Diagnostic{diag(protocol.DiagnosticSeverityError, locate(text, field),
				fmt.Sprintf("missing %s", field))}
		}
		return nil
	}
	parts := strings.SplitN(urn, ":", 4)
	if len(parts) < 4 || parts[0] != "urn" || parts[1] != "moos" || parts[3] == "" {
		return []protocol.Diagnostic{diag(protocol.DiagnosticSeverityWarning, locate(text, q(urn)),
			fmt.Sprintf("malformed URN %q; expected urn:moos:<type>:<short>", urn))}
	}
	seg := parts[2]
	if _, ok := ontology.NodeTypes[seg]; !ok && seg != "rel" {
		return []protocol.Diagnostic{diag(protocol.DiagnosticSeverityHint, locate(text, q(urn)),
			fmt.Sprintf("URN type segment %q is not a known node type", seg))}
	}
	return nil
}

// forbiddenVocab lints curated forbidden tokens as whole words (Hint severity).
func forbiddenVocab(text string) []protocol.Diagnostic {
	var d []protocol.Diagnostic
	for tok, note := range ontology.ForbiddenVocab {
		if noisyForbidden[tok] {
			continue
		}
		for _, off := range wholeWordOffsets(text, tok) {
			d = append(d, diag(protocol.DiagnosticSeverityHint,
				protocol.Range{Start: posAt(text, off), End: posAt(text, off+len(tok))},
				fmt.Sprintf("forbidden vocabulary %q — use the canonical term instead (%s)", tok, note)))
			if len(d) > 100 {
				return d
			}
		}
	}
	return d
}

func wholeWordOffsets(text, tok string) []int {
	var offs []int
	idChar := func(b byte) bool {
		return b == '_' || (b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z') || (b >= '0' && b <= '9')
	}
	from := 0
	for {
		i := strings.Index(text[from:], tok)
		if i < 0 {
			return offs
		}
		abs := from + i
		leftOK := abs == 0 || !idChar(text[abs-1])
		rightIdx := abs + len(tok)
		rightOK := rightIdx >= len(text) || !idChar(text[rightIdx])
		if leftOK && rightOK {
			offs = append(offs, abs)
		}
		from = abs + len(tok)
	}
}

func pairDeclared(w ontology.WF, sp, tp string) bool {
	for _, p := range w.PortPairs {
		if p[0] == sp && p[1] == tp {
			return true
		}
	}
	return false
}

func typeAllowed(allowed []string, t string) bool {
	if len(allowed) == 0 || contains(allowed, "*") {
		return true
	}
	return contains(allowed, t)
}

func pairsString(w ontology.WF) string {
	var parts []string
	for _, p := range w.PortPairs {
		parts = append(parts, fmt.Sprintf("%s→%s", p[0], p[1]))
	}
	return strings.Join(parts, ", ")
}

func diag(sev protocol.DiagnosticSeverity, rng protocol.Range, msg string) protocol.Diagnostic {
	s := source
	return protocol.Diagnostic{Range: rng, Severity: &sev, Source: &s, Message: msg}
}

func q(s string) string { return `"` + s + `"` }
