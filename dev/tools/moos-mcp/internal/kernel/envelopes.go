// Package kernel models the mo:os kernel HTTP API and rewrite-envelope wire format.
//
// The four rewrites (ADD, LINK, MUTATE, UNLINK) are the kernel's only mutation
// opcodes. Envelopes are emitted as an atomic batch to POST /programs. Field
// names here match the live wire format exactly (see dev/scripts/ops/*.program.json).
package kernel

// Property is one typed key on a node, as carried inside an ADD envelope's
// "properties" map: {"value": ..., "mutability": ..., "authority_scope": ...,
// "stratum_origin": 2}.
type Property struct {
	Value          any    `json:"value"`
	Mutability     string `json:"mutability,omitempty"`
	AuthorityScope string `json:"authority_scope"`
	StratumOrigin  int    `json:"stratum_origin,omitempty"`
}

// Envelope is a permissive rewrite envelope. Only the fields relevant to a given
// rewrite_type are populated; it is forwarded as-is to POST /programs. Keeping it
// a map (rather than four rigid structs) lets agents pass envelopes the builders
// below don't cover, without the server rejecting valid-but-unmodeled shapes.
type Envelope map[string]any

// NewAdd builds an ADD envelope (create a node). session may be "".
func NewAdd(actor, nodeURN, typeID string, props map[string]Property, session string) Envelope {
	e := Envelope{
		"rewrite_type": "ADD",
		"actor":        actor,
		"node_urn":     nodeURN,
		"type_id":      typeID,
		"properties":   props,
	}
	if session != "" {
		e["session_urn"] = session
	}
	return e
}

// NewLink builds a LINK envelope (create a relation). wf is the WF rewrite_category.
func NewLink(actor, relationURN, srcURN, srcPort, tgtURN, tgtPort, wf, session string) Envelope {
	e := Envelope{
		"rewrite_type":     "LINK",
		"actor":            actor,
		"relation_urn":     relationURN,
		"src_urn":          srcURN,
		"src_port":         srcPort,
		"tgt_urn":          tgtURN,
		"tgt_port":         tgtPort,
		"rewrite_category": wf,
	}
	if session != "" {
		e["session_urn"] = session
	}
	return e
}

// NewMutate builds a MUTATE envelope (change exactly one field on one node).
func NewMutate(actor, targetURN, field string, newValue any, wf string) Envelope {
	e := Envelope{
		"rewrite_type": "MUTATE",
		"actor":        actor,
		"target_urn":   targetURN,
		"field":        field,
		"new_value":    newValue,
	}
	if wf != "" {
		e["rewrite_category"] = wf
	}
	return e
}

// NewUnlink builds an UNLINK envelope (remove a relation). wf may be "" — the
// kernel infers it from the existing relation.
func NewUnlink(actor, relationURN, wf string) Envelope {
	e := Envelope{
		"rewrite_type": "UNLINK",
		"actor":        actor,
		"relation_urn": relationURN,
	}
	if wf != "" {
		e["rewrite_category"] = wf
	}
	return e
}
