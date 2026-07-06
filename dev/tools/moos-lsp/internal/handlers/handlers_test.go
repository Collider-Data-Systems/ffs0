package handlers

import (
	"strings"
	"testing"

	protocol "github.com/tliron/glsp/protocol_3_16"
)

func msgs(diags []protocol.Diagnostic) string {
	var b strings.Builder
	for _, d := range diags {
		b.WriteString(d.Message)
		b.WriteByte('\n')
	}
	return b.String()
}

func TestAnalyzeUnknownTypeAndWF(t *testing.T) {
	doc := `[
  {"rewrite_type":"ADD","actor":"urn:moos:agent:x","node_urn":"urn:moos:session:sam.x","type_id":"sessionn"},
  {"rewrite_type":"LINK","actor":"urn:moos:agent:x","relation_urn":"urn:moos:rel:a","src_urn":"urn:moos:group:sam","src_port":"owns","tgt_urn":"urn:moos:workstation:y","tgt_port":"child","rewrite_category":"WF99"}
]`
	got := msgs(Analyze(doc))
	if !strings.Contains(got, "unknown node type") {
		t.Errorf("expected unknown node type diagnostic, got:\n%s", got)
	}
	if !strings.Contains(got, "unknown rewrite_category") {
		t.Errorf("expected unknown rewrite_category diagnostic, got:\n%s", got)
	}
}

func TestAnalyzeValidLinkHasNoErrors(t *testing.T) {
	doc := `[{"rewrite_type":"LINK","actor":"urn:moos:agent:x","relation_urn":"urn:moos:rel:a","src_urn":"urn:moos:group:sam","src_port":"owns","tgt_urn":"urn:moos:workstation:y","tgt_port":"child","rewrite_category":"WF01"}]`
	for _, d := range Analyze(doc) {
		if d.Severity != nil && *d.Severity == protocol.DiagnosticSeverityError {
			t.Errorf("unexpected error on valid WF01 LINK: %s", d.Message)
		}
	}
}

func TestAnalyzeWF19AdditionalPortPairTypes(t *testing.T) {
	doc := `[
  {"rewrite_type":"LINK","actor":"urn:moos:agent:vscode.hp-z440.lola","relation_urn":"urn:moos:rel:has-purpose","src_urn":"urn:moos:session:sam.karpathy-seat","src_port":"has-purpose","tgt_urn":"urn:moos:purpose:sam.compiler-lowering","tgt_port":"purpose-of-session","rewrite_category":"WF19"},
  {"rewrite_type":"LINK","actor":"urn:moos:agent:vscode.hp-z440.lola","relation_urn":"urn:moos:rel:pins-purpose","src_urn":"urn:moos:session:sam.karpathy-seat","src_port":"pins-urn","tgt_urn":"urn:moos:purpose:sam.compiler-lowering","tgt_port":"pinned-by-session","rewrite_category":"WF19"},
  {"rewrite_type":"LINK","actor":"urn:moos:agent:vscode.hp-z440.lola","relation_urn":"urn:moos:rel:pins-ki","src_urn":"urn:moos:session:sam.karpathy-seat","src_port":"pins-urn","tgt_urn":"urn:moos:knowledge_item:demo","tgt_port":"pinned-by-session","rewrite_category":"WF19"}
]`
	for _, diagnostic := range Analyze(doc) {
		if diagnostic.Severity != nil && *diagnostic.Severity <= protocol.DiagnosticSeverityWarning {
			t.Errorf("unexpected diagnostic on valid WF19 additional port pair: %s", diagnostic.Message)
		}
	}
}

func TestAnalyzeWF19AdditionalPortPairRejectsWrongTargetType(t *testing.T) {
	doc := `[{"rewrite_type":"LINK","actor":"urn:moos:agent:vscode.hp-z440.lola","relation_urn":"urn:moos:rel:bad-purpose","src_urn":"urn:moos:session:sam.karpathy-seat","src_port":"has-purpose","tgt_urn":"urn:moos:agent:vscode.hp-z440.lola","tgt_port":"purpose-of-session","rewrite_category":"WF19"}]`
	got := msgs(Analyze(doc))
	if !strings.Contains(got, `tgt type "agent" not allowed by WF19 port pair has-purpose→purpose-of-session`) {
		t.Errorf("expected pair-specific target type diagnostic, got:\n%s", got)
	}
}

func TestForbiddenVocab(t *testing.T) {
	got := msgs(Analyze(`{"note":"this edge is a payload"}`))
	if !strings.Contains(got, "edge") || !strings.Contains(got, "payload") {
		t.Errorf("expected forbidden vocab for edge/payload, got:\n%s", got)
	}
}

func TestCompleteWFContext(t *testing.T) {
	doc := "{\n  \"rewrite_category\": \"\"\n}"
	items := Complete(doc, protocol.Position{Line: 1, Character: 22})
	for _, it := range items {
		if it.Label == "WF19" {
			return
		}
	}
	t.Errorf("expected WF19 in rewrite_category completion (%d items)", len(items))
}

func TestHoverWF(t *testing.T) {
	h := Hover("WF19", protocol.Position{Line: 0, Character: 1})
	if h == nil {
		t.Fatal("expected a hover for WF19")
	}
	mc, ok := h.Contents.(protocol.MarkupContent)
	if !ok || !strings.Contains(mc.Value, "Session governance") {
		t.Errorf("expected WF19 'Session governance' doc, got %#v", h.Contents)
	}
	if !strings.Contains(mc.Value, "`has-purpose→purpose-of-session` (session → purpose)") {
		t.Errorf("expected WF19 hover to include pair-specific has-purpose types, got %#v", h.Contents)
	}
}
