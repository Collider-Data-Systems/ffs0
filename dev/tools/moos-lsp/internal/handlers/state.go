// Package handlers implements the mo:os language server's analysis: diagnostics,
// completion, and hover, all driven by the generated ontology symbol tables.
package handlers

import "sync"

// Docs is the in-memory full-text store for open documents (full text sync).
var Docs = &docStore{m: map[string]string{}}

// KernelBaseURL, when non-empty, enables live hover: URN hovers fetch folded node
// state from GET {KernelBaseURL}/state/nodes/{urn}. Empty disables kernel calls.
var KernelBaseURL string

type docStore struct {
	mu sync.RWMutex
	m  map[string]string
}

func (d *docStore) Set(uri, text string) {
	d.mu.Lock()
	d.m[uri] = text
	d.mu.Unlock()
}

func (d *docStore) Get(uri string) (string, bool) {
	d.mu.RLock()
	defer d.mu.RUnlock()
	t, ok := d.m[uri]
	return t, ok
}

func (d *docStore) Delete(uri string) {
	d.mu.Lock()
	delete(d.m, uri)
	d.mu.Unlock()
}
