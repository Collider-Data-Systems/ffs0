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
}
