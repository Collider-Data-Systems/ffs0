package kernel

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Client is a thin HTTP client for one mo:os kernel (or router) base URL.
// All reads return raw JSON so callers can pass it straight through to an MCP
// text result without lossy re-marshalling.
type Client struct {
	BaseURL string
	HTTP    *http.Client
}

// New returns a Client for baseURL (e.g. http://localhost:8000). A trailing
// slash is trimmed. The 5s timeout mirrors the router's federation fanout deadline.
func New(baseURL string) *Client {
	return &Client{
		BaseURL: strings.TrimRight(baseURL, "/"),
		HTTP:    &http.Client{Timeout: 5 * time.Second},
	}
}

func (c *Client) get(ctx context.Context, path string) (json.RawMessage, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.BaseURL+path, nil)
	if err != nil {
		return nil, err
	}
	return c.do(req)
}

func (c *Client) do(req *http.Request) (json.RawMessage, error) {
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, fmt.Errorf("kernel request %s %s: %w", req.Method, req.URL.Path, err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("kernel %s %s -> %d: %s", req.Method, req.URL.Path, resp.StatusCode, strings.TrimSpace(string(body)))
	}
	return json.RawMessage(body), nil
}

// Healthz: GET /healthz -> {status, ontology_version, t_day, log_len}.
func (c *Client) Healthz(ctx context.Context) (json.RawMessage, error) {
	return c.get(ctx, "/healthz")
}

// ListNodes: GET /state/nodes -> array of node objects.
func (c *Client) ListNodes(ctx context.Context) (json.RawMessage, error) {
	return c.get(ctx, "/state/nodes")
}

// GetNode: GET /state/nodes/{urn} -> single node object. The URN is path-escaped
// because it contains ':' separators.
func (c *Client) GetNode(ctx context.Context, urn string) (json.RawMessage, error) {
	return c.get(ctx, "/state/nodes/"+url.PathEscape(urn))
}

// Relations: GET /state/relations -> array of relation objects.
func (c *Client) Relations(ctx context.Context) (json.RawMessage, error) {
	return c.get(ctx, "/state/relations")
}

// RelationsBySrc: GET /state/relations/src/{urn} -> relations outbound from a node.
func (c *Client) RelationsBySrc(ctx context.Context, urn string) (json.RawMessage, error) {
	return c.get(ctx, "/state/relations/src/"+url.PathEscape(urn))
}

// NodeTypes: GET /operad/node-types -> the type registry.
func (c *Client) NodeTypes(ctx context.Context) (json.RawMessage, error) {
	return c.get(ctx, "/operad/node-types")
}

// RewriteCategories: GET /operad/rewrite-categories -> the WF registry.
func (c *Client) RewriteCategories(ctx context.Context) (json.RawMessage, error) {
	return c.get(ctx, "/operad/rewrite-categories")
}

// ApplyProgram: POST /programs with a JSON array of envelopes (atomic, all-or-nothing)
// -> {applied, log_seq, applied_count, error}.
func (c *Client) ApplyProgram(ctx context.Context, envelopes []Envelope) (json.RawMessage, error) {
	body, err := json.Marshal(envelopes)
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+"/programs", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	return c.do(req)
}
