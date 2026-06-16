package handlers

import (
	"strings"

	protocol "github.com/tliron/glsp/protocol_3_16"
)

// posAt converts a byte offset into a Position (line, UTF-16-ish character). Columns
// are computed by byte for ASCII content, which envelope JSON and URNs are.
func posAt(text string, off int) protocol.Position {
	if off > len(text) {
		off = len(text)
	}
	line := 0
	lineStart := 0
	for i := 0; i < off; i++ {
		if text[i] == '\n' {
			line++
			lineStart = i + 1
		}
	}
	return protocol.Position{Line: protocol.UInteger(line), Character: protocol.UInteger(off - lineStart)}
}

// locate returns the range of the first occurrence of needle, or a zero range at
// the document start if not found.
func locate(text, needle string) protocol.Range {
	if needle == "" {
		return protocol.Range{}
	}
	idx := strings.Index(text, needle)
	if idx < 0 {
		return protocol.Range{}
	}
	return protocol.Range{Start: posAt(text, idx), End: posAt(text, idx+len(needle))}
}

// lineAt returns the text of a 0-based line.
func lineAt(text string, line protocol.UInteger) string {
	lines := strings.Split(text, "\n")
	if int(line) < len(lines) {
		return lines[line]
	}
	return ""
}

// offsetAt converts a Position to a byte offset.
func offsetAt(text string, pos protocol.Position) int {
	lines := strings.Split(text, "\n")
	off := 0
	for i := 0; i < int(pos.Line) && i < len(lines); i++ {
		off += len(lines[i]) + 1 // + newline
	}
	off += int(pos.Character)
	if off > len(text) {
		off = len(text)
	}
	return off
}

// wordAt extracts the maximal identifier/URN token around a position. The token
// alphabet includes URN punctuation (':', '.', '-') so full URNs and WF/type/port
// names are captured.
func wordAt(text string, pos protocol.Position) string {
	off := offsetAt(text, pos)
	isTok := func(b byte) bool {
		return b == '_' || b == ':' || b == '.' || b == '-' ||
			(b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z') || (b >= '0' && b <= '9')
	}
	start := off
	for start > 0 && isTok(text[start-1]) {
		start--
	}
	end := off
	for end < len(text) && isTok(text[end]) {
		end++
	}
	if start >= end {
		return ""
	}
	return strings.Trim(text[start:end], ".:-")
}

// urnType returns the type segment of a urn:moos:<type>:... string, or "".
func urnType(urn string) string {
	parts := strings.SplitN(urn, ":", 4)
	if len(parts) >= 3 && parts[0] == "urn" && parts[1] == "moos" {
		return parts[2]
	}
	return ""
}

func str(v any) string {
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}

func contains(xs []string, x string) bool {
	for _, v := range xs {
		if v == x {
			return true
		}
	}
	return false
}
