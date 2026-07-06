package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/Collider-Data-Systems/moos-lsp/internal/ontology"
	protocol "github.com/tliron/glsp/protocol_3_16"
)

// Hover returns markdown documentation for the token under the cursor: a WF id, a
// node type, a forbidden token, a port name, or a URN (with live folded state when
// KernelBaseURL is set).
func Hover(text string, pos protocol.Position) *protocol.Hover {
	tok := wordAt(text, pos)
	if tok == "" {
		return nil
	}

	if w, ok := ontology.WFs[tok]; ok {
		return md(wfDoc(w))
	}
	if nt, ok := ontology.NodeTypes[tok]; ok {
		return md(typeDoc(nt))
	}
	if note, ok := ontology.ForbiddenVocab[tok]; ok {
		return md(fmt.Sprintf("⚠ **forbidden vocabulary** `%s`\n\n%s\n\nUse a canonical term (node · relation · rewrite · property · port · operad).", tok, note))
	}
	if strings.HasPrefix(tok, "urn:moos:") {
		return md(urnDoc(tok))
	}
	if wf, ok := ontology.SrcPortToWF[tok]; ok {
		w := ontology.WFs[wf]
		return md(fmt.Sprintf("**port** `%s` — declared by **%s** (%s)", tok, wf, w.Name))
	}
	return nil
}

func wfDoc(w ontology.WF) string {
	var b strings.Builder
	fmt.Fprintf(&b, "**%s — %s**\n\n%s\n\n", w.ID, w.Name, w.Description)
	fmt.Fprintf(&b, "- allowed rewrites: `%s`\n", strings.Join(w.AllowedRewrites, "`, `"))
	if len(w.SrcTypes) > 0 {
		fmt.Fprintf(&b, "- src types: %s\n", strings.Join(w.SrcTypes, ", "))
	}
	if len(w.TgtTypes) > 0 {
		fmt.Fprintf(&b, "- tgt types: %s\n", strings.Join(w.TgtTypes, ", "))
	}
	if len(w.PortPairs) > 0 {
		var pairs []string
		for _, p := range w.PortPairs {
			detail := fmt.Sprintf("`%s→%s`", p.SrcPort, p.TgtPort)
			if len(p.SrcTypes) > 0 || len(p.TgtTypes) > 0 {
				detail += fmt.Sprintf(" (%s → %s)", strings.Join(p.SrcTypes, ", "), strings.Join(p.TgtTypes, ", "))
			}
			pairs = append(pairs, detail)
		}
		fmt.Fprintf(&b, "- port pairs: %s\n", strings.Join(pairs, ", "))
	}
	return b.String()
}

func typeDoc(nt ontology.NodeType) string {
	s := fmt.Sprintf("**node type** `%s` (%s)\n\n- URN: `%s`\n", nt.ID, nt.Stratum, nt.URNPattern)
	if nt.URNExample != "" {
		s += fmt.Sprintf("- example: `%s`\n", nt.URNExample)
	}
	if len(nt.OutPorts) > 0 {
		s += fmt.Sprintf("- out ports: %s\n", strings.Join(nt.OutPorts, ", "))
	}
	if len(nt.InPorts) > 0 {
		s += fmt.Sprintf("- in ports: %s\n", strings.Join(nt.InPorts, ", "))
	}
	return s
}

func urnDoc(urn string) string {
	seg := urnType(urn)
	s := fmt.Sprintf("**URN** `%s`\n\n", urn)
	if nt, ok := ontology.NodeTypes[seg]; ok {
		s += fmt.Sprintf("- type: `%s` (%s)\n- pattern: `%s`\n", seg, nt.Stratum, nt.URNPattern)
	} else if seg == "rel" {
		s += "- a relation URN\n"
	} else {
		s += fmt.Sprintf("- type segment `%s` is not a known node type\n", seg)
	}
	if KernelBaseURL != "" {
		if live := fetchNode(urn); live != "" {
			s += "\n**folded state**\n\n```json\n" + live + "\n```\n"
		}
	}
	return s
}

// fetchNode does a short-timeout GET {KernelBaseURL}/state/nodes/{urn}. Best-effort:
// any error yields "" (hover degrades to static info).
func fetchNode(urn string) string {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		strings.TrimRight(KernelBaseURL, "/")+"/state/nodes/"+url.PathEscape(urn), nil)
	if err != nil {
		return ""
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		return ""
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, 8192))
	if err != nil {
		return ""
	}
	var pretty json.RawMessage = body
	var buf []byte
	if b, err := json.MarshalIndent(json.RawMessage(body), "", "  "); err == nil {
		buf = b
	} else {
		buf = pretty
	}
	return string(buf)
}

func md(value string) *protocol.Hover {
	return &protocol.Hover{Contents: protocol.MarkupContent{Kind: protocol.MarkupKindMarkdown, Value: value}}
}
