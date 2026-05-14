#!/usr/bin/env julia

module SessionPipelineMVPGate

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_SESSION_PACK = "tmp/projections/session_pipeline/session_context/current_session.json"
const DEFAULT_GRAPH_PACK = "tmp/projections/session_pipeline/graph_artifacts/session_occasion_engineering.json"
const DEFAULT_TEMPORAL_GRAPH_PACK = "tmp/projections/session_pipeline/graph_artifacts/temporal_calendar_engineering.json"
const DEFAULT_T189_GRAPH_PACK = "tmp/projections/session_pipeline/graph_artifacts/t189_recommendation_engineering.json"
const DEFAULT_CALENDAR_SCOPE_GRAPH_PACK = "tmp/projections/session_pipeline/graph_artifacts/calendar_scope_engineering.json"
const DEFAULT_DOT_PATH = "tmp/projections/session_pipeline/visual/session_occasion_frame.dot"
const DEFAULT_SVG_PATH = "tmp/projections/session_pipeline/visual/session_occasion_frame.svg"
const DEFAULT_TEMPORAL_DOT_PATH = "tmp/projections/session_pipeline/visual/temporal_calendar_frame.dot"
const DEFAULT_TEMPORAL_SVG_PATH = "tmp/projections/session_pipeline/visual/temporal_calendar_frame.svg"
const DEFAULT_T189_DOT_PATH = "tmp/projections/session_pipeline/visual/t189_recommendation_frame.dot"
const DEFAULT_T189_SVG_PATH = "tmp/projections/session_pipeline/visual/t189_recommendation_frame.svg"
const DEFAULT_CALENDAR_SCOPE_DOT_PATH = "tmp/projections/session_pipeline/visual/calendar_scope_frame.dot"
const DEFAULT_CALENDAR_SCOPE_SVG_PATH = "tmp/projections/session_pipeline/visual/calendar_scope_frame.svg"
const DEFAULT_CALENDAR_PLAN_PATH = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json"
const DEFAULT_CALENDAR_REPORT_PATH = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.md"
const DEFAULT_CALENDAR_WRITE_RESULT_PATH = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_write_result.json"
const DEFAULT_RECOMMENDATION_PLAN_PATH = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json"
const DEFAULT_RECOMMENDATION_REPORT_PATH = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.md"
const DEFAULT_RECONCILIATION_PATH = "tmp/projections/session_pipeline/recommendations/t189_recommendation_reconciliation.json"
const DEFAULT_RECONCILIATION_REPORT_PATH = "tmp/projections/session_pipeline/recommendations/t189_recommendation_reconciliation.md"
const DEFAULT_ATLAS_PATH = "tmp/projections/session_pipeline/atlas/surface_context_atlas.json"
const DEFAULT_ATLAS_REPORT_PATH = "tmp/projections/session_pipeline/atlas/surface_context_atlas.md"
const DEFAULT_ONE_SHOT_APPLY_SCRIPT = "tmp/projections/session_pipeline/recommendations/apply_t189_grouped.ps1"
const DEFAULT_OUT_BASE = "tmp/projections/session_pipeline/mvp/session_pipeline_gate"
const DEFAULT_HTML_PATH = "tmp/projections/session_pipeline/index.html"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:vscode.hp-laptop.copilot"
const DEFAULT_KEEP_CHANNEL_URN = "urn:moos:channel:google.keep.sam"
const DEFAULT_KEEP_KI_URN = "urn:moos:ki:gdrive.t187-keep-session-occasion-lingo"

const PIPELINE_STAGE_SPECS = [
    Dict(
        "id" => "g-ingest",
        "name" => "G-ingest",
        "short_name" => "G",
        "description" => "Keep source material becomes HG evidence with explicit channel, knowledge_item, and WF12 topology.",
        "gate_names" => ["G input channel", "G input knowledge item", "G input evidence topology"],
    ),
    Dict(
        "id" => "f-session",
        "name" => "F session pack",
        "short_name" => "F/session",
        "description" => "Folded HG state becomes a session header plus purpose-colored affordance pack for VS Code, an agent, or a harness.",
        "gate_names" => ["F session handoff header", "session actor/occupant reconciliation", "session occasion topology", "session purpose color", "F affordance pack"],
    ),
    Dict(
        "id" => "f-visual",
        "name" => "F visual lens",
        "short_name" => "F/visual",
        "description" => "The selected graph lenses become engineering summaries, static visual artifacts, Calendar payloads, and recommendation HG plans while keeping disconnected roots visible.",
        "gate_names" => ["F graph artifact analysis", "Temporal Calendar lens", "T189 recommendation lens", "Calendar scope lens", "visual lens root coverage", "static visual output", "Calendar time-fabric artifacts", "T189/T200 recommendation artifacts", "T189 recommendation reconciliation", "deferred apply boundaries", "lens flexibility controls", "agent neighborhood visibility"],
    ),
    Dict(
        "id" => "operator-interface",
        "name" => "Operator interface",
        "short_name" => "UI",
        "description" => "The MVP is readable as a control surface: status, lineage, checks, artifacts, and next gates are visible in one place.",
        "gate_names" => ["interactive visual aid", "surface context atlas", "one-shot apply script cleanup"],
    ),
]

const INTERFACE_PRINCIPLES = [
    Dict(
        "name" => "Asset health over raw logs",
        "source" => "Dagster asset checks and freshness patterns",
        "application" => "Expose pass/warn/fail gates, runtime metadata, artifact paths, and next actions as structured materialization metadata.",
    ),
    Dict(
        "name" => "Lineage stays first-class",
        "source" => "Data orchestration lineage and materialization UIs",
        "application" => "Show G-ingest, F-session, and F-visual stages separately so operators can see where evidence, context, and renderers diverge.",
    ),
    Dict(
        "name" => "Graph UI needs selection semantics",
        "source" => "Cytoscape.js element data, selectors, layouts, and tap/select events",
        "application" => "Keep the static Graphviz artifact for review, but shape the interactive renderer around typed node data, style selectors, search/focus controls, layout controls, selection events, and an inspector panel.",
    ),
    Dict(
        "name" => "Warnings are design signals",
        "source" => "CI/CD quality gate practice",
        "application" => "Treat warn as a usable MVP with named next gates, not as hidden debt or a failed run.",
    ),
]

const RENDERER_CANDIDATES = [
    Dict(
        "name" => "Graphviz DOT/SVG",
        "role" => "current static renderer",
        "fit" => "MVP baseline: deterministic, local, reviewable in git, already wired through export_t200plus_projection.jl",
        "recommendation" => "keep",
    ),
    Dict(
        "name" => "Cytoscape.js",
        "role" => "next interactive HG lens renderer",
        "fit" => "Best next fit from Context7 scan: accepts graph elements JSON, supports selectors/styles/layouts, and has selection/viewport events for node inspection.",
        "recommendation" => "next",
    ),
    Dict(
        "name" => "Cytoscape layout extensions",
        "role" => "optional layout upgrade path",
        "fit" => "Dagre and cose-bilkent are useful follow-ups when the inspector needs hierarchy or cleaner compound layouts; keep built-in Cose/Grid/Circle/Breadthfirst/Concentric for the local no-build dashboard.",
        "recommendation" => "later",
    ),
    Dict(
        "name" => "svg-pan-zoom",
        "role" => "optional SVG viewport helper",
        "fit" => "Good library fit for polished pan/zoom on static Graphviz SVGs, but the generated dashboard keeps native controls so offline/local file review still works.",
        "recommendation" => "defer",
    ),
    Dict(
        "name" => "vis-network",
        "role" => "simple browser network fallback",
        "fit" => "Quick node/edge DataSet setup and clustering; useful if the first interactive prototype should be very small.",
        "recommendation" => "fallback",
    ),
    Dict(
        "name" => "force-graph",
        "role" => "dense canvas force renderer",
        "fit" => "Good for larger exploratory graphs with pan/zoom/drag interactions, but less semantically structured than Cytoscape for typed HG inspection.",
        "recommendation" => "later",
    ),
    Dict(
        "name" => "Sigma.js + Graphology",
        "role" => "large WebGL graph explorer",
        "fit" => "Strong for high-volume read-only exploration and graph analytics pipelines; less direct than Cytoscape for typed relation selectors and inspector-first workflows.",
        "recommendation" => "later",
    ),
    Dict(
        "name" => "GraphMakie + Graphs.jl",
        "role" => "Julia-native analysis and rendering path",
        "fit" => "Best Julia-side option when metrics, layouts, or notebooks need to stay inside the Julia process; keep generated JSON as the browser/dashboard contract.",
        "recommendation" => "analysis path",
    ),
    Dict(
        "name" => "ELK / Dagre hierarchical layout",
        "role" => "DAG and lineage layout upgrade",
        "fit" => "Useful for F/G pipelines, WF21 causality, and Calendar/recommendation lineage once the local dashboard can bundle layout extensions cleanly.",
        "recommendation" => "next layout extension",
    ),
]

const VISUAL_STACK_NOTES = [
    Dict(
        "name" => "Renderer separation",
        "guidance" => "Keep graph-artifact JSON as the contract. Graphviz SVG, Cytoscape, Julia notebooks, and any future WebGL renderer should all consume the same selected nodes and relations.",
    ),
    Dict(
        "name" => "Static proof plus interactive inspection",
        "guidance" => "Use DOT/SVG for deterministic review and diffable artifacts; use Cytoscape for search, filtering, focus, relation metadata, and operator triage.",
    ),
    Dict(
        "name" => "F/G semantics in data",
        "guidance" => "Encode F/G role and relation-family metadata on elements before rendering, so the UI can expose projection, ingest, authority, and lineage meaning without parsing labels.",
    ),
    Dict(
        "name" => "Julia analytics boundary",
        "guidance" => "Run graph metrics and lens checks in Julia where the pipeline already lives; avoid making the browser compute truth that belongs in the generated artifact.",
    ),
]

const FG_NODE_ROLES = Dict(
    "agent" => "authority",
    "group" => "authority",
    "role" => "authority",
    "user" => "authority",
    "session" => "f-context",
    "purpose" => "f-context",
    "program" => "f-context",
    "workflow" => "f-context",
    "view_filter" => "lens",
    "grammar_fragment" => "lens",
    "pattern" => "lens",
    "knowledge_item" => "g-evidence",
    "claim" => "g-evidence",
    "derivation" => "lineage",
    "channel" => "surface",
    "calendar_event" => "surface",
    "source_feed" => "surface",
    "external_op" => "surface",
    "kernel" => "substrate",
    "workstation" => "substrate",
    "transport_binding" => "substrate",
    "endpoint" => "substrate",
    "protocol" => "substrate",
)

const RELATION_FAMILIES = Dict(
    "WF01" => Dict("family" => "authority ownership", "fg_direction" => "authority context", "insight" => "Who owns the node, agent, session, or surface being inspected."),
    "WF02" => Dict("family" => "delegation and role", "fg_direction" => "authority context", "insight" => "Which principal can delegate or carry role-based capability."),
    "WF07" => Dict("family" => "source anchor", "fg_direction" => "G evidence", "insight" => "External source anchoring for evidence that entered the HG."),
    "WF12" => Dict("family" => "channel ingest", "fg_direction" => "G ingest", "insight" => "External channel material entering HG evidence topology."),
    "WF13" => Dict("family" => "governance proposal", "fg_direction" => "governance", "insight" => "Proposed action or review item, not an already-applied rewrite."),
    "WF16" => Dict("family" => "federation route", "fg_direction" => "substrate", "insight" => "Router/kernel reachability and federation shape."),
    "WF18" => Dict("family" => "composition and scope", "fg_direction" => "F/G spine", "insight" => "Containment and composition: programs, artifacts, chunks, and scoped bundles."),
    "WF19" => Dict("family" => "session/purpose/pin", "fg_direction" => "F session", "insight" => "Session purpose, occupant, tool, and pinned-scope topology."),
    "WF21" => Dict("family" => "causal lineage", "fg_direction" => "lineage", "insight" => "Why a node exists or how a projection/recommendation follows from prior graph state."),
)

const LINGO = Dict(
    "G_ingest" => "External source -> HG evidence. For this lane: Google Keep export/manual download -> channel + knowledge_item + claim/derivation topology.",
    "F_projection" => "HG folded state -> external/session artifact. For this lane: session context pack, graph engineering report, DOT/SVG visual aid.",
    "Calendar_projection" => "HG graph artifact -> Google Calendar payloads. Calendar is a visible projection surface; the graph remains source of truth.",
    "Recommendation_projection" => "Approved T189 recommendations -> dry candidate HG nodes/relations. This is a plan surface, not an APPLY batch.",
    "reconciliation" => "A comparison of a dry plan against folded HG state: applied, pending, and deferred rows are named explicitly.",
    "lens" => "A typed view functor: roots + radius + WF/port/type/predicate filters + authority/session context -> selected subgraph.",
    "scope" => "The domain of a lens: explicit roots plus reachable topology under chosen relation families. Session pins and view_filter nodes are durable scope carriers.",
    "visual_aid" => "A renderer of a lens result, not a truth source. DOT/SVG is the current static renderer; Cytoscape.js is the likely next interactive renderer.",
    "SVG_zoom_pane" => "A deterministic Graphviz SVG with local fit, zoom, reset, scroll, and wide-view controls. Use it to inspect layout, labels, and topology without changing the graph.",
    "HG_inspector" => "A typed interactive view of graph-artifact JSON. Use it when you need selectable node/relation metadata rather than the static Graphviz layout.",
    "mvp_gate" => "A generated check that the G input, F outputs, session header, and visual lens artifacts exist and expose known gaps instead of hiding them.",
    "HG_occupant" => "The folded WF19 has-occupant target for a session. This is the principal §M11 sees, regardless of which local process window is visible.",
    "IDE_harness_surface" => "The local tool container currently hosting the operator, such as VS Code/Copilot, Claude Desktop, Claude Code, or Antigravity. It is evidence for reconciliation, not itself a session.",
    "S0_conversation_staging" => "Raw chat/debug-log transcript substrate. It becomes durable only after G-ingest as knowledge_item/claim/derivation topology.",
    "actor_occupant_reconciliation" => "A dry check that actor_urn, the folded HG occupant, and the current harness agent candidate name the same driver before the handoff is used to emit rewrites.",
    "agent_neighborhood_lens" => "A lens widening rule: agents directly connected to selected session/program nodes stay visible in graph artifacts, SVGs, and inspectors even when ordinary type or match filters would otherwise hide them.",
    "F_G_role_color" => "A renderer hint derived from node type: authority, F-context, G-evidence, surface, lens, lineage, or substrate. It is visual metadata, not HG truth.",
    "relation_family_insight" => "A renderer hint derived from WF category: ownership, delegation, ingest, composition, session pinning, source anchoring, federation, proposal, or causal lineage.",
)

function object_value(obj, name::Symbol, default=nothing)
    if obj isa AbstractDict
        if haskey(obj, name)
            return obj[name]
        end
        string_name = string(name)
        return haskey(obj, string_name) ? obj[string_name] : default
    end
    try
        if haskey(obj, name)
            return getproperty(obj, name)
        end
    catch
        return default
    end
    return default
end

function prop_value(node, name::Symbol, default=nothing)
    props = object_value(node, :properties, nothing)
    props === nothing && return default
    record = object_value(props, name, nothing)
    record === nothing && return default
    value = object_value(record, :value, nothing)
    return value === nothing ? default : value
end

function fetch_json(base_url::AbstractString, path::AbstractString)
    url = string(rstrip(base_url, '/'), "/", lstrip(path, '/'))
    temp_path = Downloads.download(url)
    try
        return JSON3.read(read(temp_path, String))
    finally
        rm(temp_path; force=true)
    end
end

function read_json(path::AbstractString)
    return JSON3.read(read(path, String))
end

function write_json(path::AbstractString, value)
    dir = dirname(path)
    !isempty(dir) && mkpath(dir)
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
end

function nodes_by_urn(nodes)
    result = Dict{String, Any}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        !isempty(urn) && (result[urn] = node)
    end
    return result
end

function relation_matches(rel; src=nothing, tgt=nothing, category=nothing, src_port=nothing, tgt_port=nothing)
    src !== nothing && string(object_value(rel, :src_urn, "")) != src && return false
    tgt !== nothing && string(object_value(rel, :tgt_urn, "")) != tgt && return false
    category !== nothing && string(object_value(rel, :rewrite_category, "")) != category && return false
    src_port !== nothing && string(object_value(rel, :src_port, "")) != src_port && return false
    tgt_port !== nothing && string(object_value(rel, :tgt_port, "")) != tgt_port && return false
    return true
end

function relations_touching(relations, urn::AbstractString; category=nothing)
    return [rel for rel in relations if (string(object_value(rel, :src_urn, "")) == urn || string(object_value(rel, :tgt_urn, "")) == urn) && (category === nothing || string(object_value(rel, :rewrite_category, "")) == category)]
end

function gate(status::AbstractString, name::AbstractString, detail::AbstractString; evidence=Dict{String, Any}(), next_action="")
    return Dict(
        "name" => name,
        "status" => status,
        "detail" => detail,
        "evidence" => evidence,
        "next_action" => next_action,
    )
end

function overall_status(gates)
    statuses = Set(string(gate["status"]) for gate in gates)
    "fail" in statuses && return "fail"
    "warn" in statuses && return "warn"
    return "pass"
end

function stage_status(stage_gates)
    statuses = Set(string(gate["status"]) for gate in stage_gates)
    "fail" in statuses && return "fail"
    "warn" in statuses && return "warn"
    isempty(statuses) && return "warn"
    return "pass"
end

function pipeline_stages(gates)
    by_name = Dict{String, Any}()
    for gate in gates
        by_name[string(gate["name"])] = gate
    end
    stages = Any[]
    for spec in PIPELINE_STAGE_SPECS
        names = [string(name) for name in spec["gate_names"]]
        selected = [by_name[name] for name in names if haskey(by_name, name)]
        push!(stages, Dict(
            "id" => spec["id"],
            "name" => spec["name"],
            "short_name" => spec["short_name"],
            "description" => spec["description"],
            "status" => stage_status(selected),
            "gate_names" => names,
            "summary" => Dict(
                "pass" => count(gate -> string(gate["status"]) == "pass", selected),
                "warn" => count(gate -> string(gate["status"]) == "warn", selected),
                "fail" => count(gate -> string(gate["status"]) == "fail", selected),
            ),
        ))
    end
    return stages
end

function priority_actions(gates)
    actions = Any[]
    for gate in gates
        action = strip(string(gate["next_action"]))
        if !isempty(action) && string(gate["status"]) != "pass"
            push!(actions, Dict(
                "status" => gate["status"],
                "gate" => gate["name"],
                "action" => action,
            ))
        end
    end
    return actions
end

function array_len(obj, path::Vector{Symbol})
    value = obj
    for key in path
        value = object_value(value, key, nothing)
        value === nothing && return 0
    end
    try
        return length(value)
    catch
        return 0
    end
end

function context_array(plan, name::Symbol)
    context = object_value(plan, :context, Dict())
    value = object_value(context, name, Any[])
    return value === nothing ? Any[] : value
end

function calendar_event_count(path::AbstractString)
    isfile(path) || return 0
    try
        plan = read_json(path)
        raw = object_value(plan, :event_count, 0)
        return Int(raw)
    catch
        return 0
    end
end

function recommendation_node_count(path::AbstractString)
    isfile(path) || return 0
    try
        plan = read_json(path)
        raw = object_value(plan, :candidate_node_count, 0)
        return Int(raw)
    catch
        return 0
    end
end

function selected_recommendation_count(path::AbstractString)
    isfile(path) || return 0
    try
        plan = read_json(path)
        return length(object_value(plan, :selected_t189_recommendations, Any[]))
    catch
        return 0
    end
end

function safe_read_json(path::AbstractString)
    isfile(path) || return Dict{String, Any}()
    try
        return read_json(path)
    catch
        return Dict{String, Any}()
    end
end

function reconciliation_summary(path::AbstractString)
    report = safe_read_json(path)
    return object_value(report, :summary, Dict{String, Any}())
end

function compact_label(text; fallback="")
    clean = strip(replace(string(text), r"\s+" => " "))
    isempty(clean) && (clean = string(fallback))
    length(clean) <= 36 && return clean
    return string(clean[1:33], "...")
end

fg_role(type_id::AbstractString) = get(FG_NODE_ROLES, string(type_id), "hg-node")

function relation_family(category::AbstractString)
    return get(RELATION_FAMILIES, string(category), Dict(
        "family" => "other relation",
        "fg_direction" => "HG relation",
        "insight" => "Relation category is not yet classified for F/G visual inspection.",
    ))
end

function sorted_count_entries(counts)
    entries = Any[]
    for key in sort(collect(keys(counts)); by=string)
        push!(entries, (string(key), Int(counts[key])))
    end
    return entries
end

function print_count_chips(io, counts)
    entries = sorted_count_entries(counts)
    if isempty(entries)
        print(io, "<span class=\"pill muted\">none</span>")
        return
    end
    for (key, value) in entries
        print(io, "<span class=\"pill\">", html_escape(key), " ", html_escape(value), "</span>")
    end
end

function graph_inspector_payload(graph_pack; id="lens", label="Lens")
    nodes = collect(object_value(graph_pack, :nodes, Any[]))
    relations = collect(object_value(graph_pack, :relations, Any[]))
    degree = Dict{String, Int}()
    for relation in relations
        src = string(object_value(relation, :src_urn, ""))
        tgt = string(object_value(relation, :tgt_urn, ""))
        !isempty(src) && (degree[src] = get(degree, src, 0) + 1)
        !isempty(tgt) && (degree[tgt] = get(degree, tgt, 0) + 1)
    end
    cy_nodes = Any[]
    cy_edges = Any[]
    type_counts = Dict{String, Int}()
    relation_counts = Dict{String, Int}()
    fg_counts = Dict{String, Int}()
    relation_family_counts = Dict{String, Int}()
    agent_urns = String[]
    node_records = Any[]
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        isempty(urn) && continue
        title = string(object_value(node, :title, urn))
        type_id = string(object_value(node, :type_id, "unknown"))
        role = fg_role(type_id)
        type_counts[type_id] = get(type_counts, type_id, 0) + 1
        fg_counts[role] = get(fg_counts, role, 0) + 1
        type_id == "agent" && push!(agent_urns, urn)
        node_record = Dict(
            "urn" => urn,
            "label" => compact_label(title; fallback=urn),
            "title" => title,
            "type_id" => type_id,
            "fg_role" => role,
            "degree" => get(degree, urn, 0),
        )
        push!(node_records, node_record)
        push!(cy_nodes, Dict(
            "data" => Dict(
                "id" => urn,
                "urn" => urn,
                "label" => node_record["label"],
                "title" => title,
                "type_id" => type_id,
                "fg_role" => role,
                "status" => string(object_value(node, :status, "")),
                "degree" => get(degree, urn, 0),
            ),
        ))
    end
    for (index, relation) in enumerate(relations)
        src = string(object_value(relation, :src_urn, ""))
        tgt = string(object_value(relation, :tgt_urn, ""))
        (isempty(src) || isempty(tgt)) && continue
        urn = string(object_value(relation, :urn, string("rel:", index)))
        category = string(object_value(relation, :rewrite_category, ""))
        family = relation_family(category)
        family_name = string(family["family"])
        relation_counts[category] = get(relation_counts, category, 0) + 1
        relation_family_counts[family_name] = get(relation_family_counts, family_name, 0) + 1
        push!(cy_edges, Dict(
            "data" => Dict(
                "id" => urn,
                "urn" => urn,
                "source" => src,
                "target" => tgt,
                "label" => category,
                "rewrite_category" => category,
                "family" => family_name,
                "fg_direction" => string(family["fg_direction"]),
                "insight" => string(family["insight"]),
                "src_port" => string(object_value(relation, :src_port, "")),
                "tgt_port" => string(object_value(relation, :tgt_port, "")),
            ),
        ))
    end
    top_nodes = first(sort(node_records; by=record -> (-Int(record["degree"]), string(record["urn"]))), min(5, length(node_records)))
    return Dict(
        "id" => id,
        "label" => label,
        "renderer" => "Cytoscape.js",
        "node_count" => length(cy_nodes),
        "relation_count" => length(cy_edges),
        "type_counts" => type_counts,
        "relation_counts" => relation_counts,
        "fg_counts" => fg_counts,
        "relation_family_counts" => relation_family_counts,
        "agent_urns" => sort(agent_urns),
        "top_nodes" => top_nodes,
        "elements" => vcat(cy_nodes, cy_edges),
    )
end

function graph_pack_contains_node(graph_pack, urn::AbstractString)
    isempty(strip(urn)) && return false
    for node in collect(object_value(graph_pack, :nodes, Any[]))
        string(object_value(node, :urn, "")) == urn && return true
    end
    return false
end

function json_literal(value)
    text = sprint(io -> JSON3.write(io, value))
    return replace(text, "</" => "<\\/")
end

function plan_mvp_gate(nodes, relations; health=Dict(), session_pack=Dict(), graph_pack=Dict(), temporal_graph_pack=Dict(), t189_graph_pack=Dict(), calendar_scope_graph_pack=Dict(), session_pack_path=DEFAULT_SESSION_PACK, graph_pack_path=DEFAULT_GRAPH_PACK, temporal_graph_pack_path=DEFAULT_TEMPORAL_GRAPH_PACK, t189_graph_pack_path=DEFAULT_T189_GRAPH_PACK, calendar_scope_graph_pack_path=DEFAULT_CALENDAR_SCOPE_GRAPH_PACK, dot_path=DEFAULT_DOT_PATH, svg_path=DEFAULT_SVG_PATH, temporal_dot_path=DEFAULT_TEMPORAL_DOT_PATH, temporal_svg_path=DEFAULT_TEMPORAL_SVG_PATH, t189_dot_path=DEFAULT_T189_DOT_PATH, t189_svg_path=DEFAULT_T189_SVG_PATH, calendar_scope_dot_path=DEFAULT_CALENDAR_SCOPE_DOT_PATH, calendar_scope_svg_path=DEFAULT_CALENDAR_SCOPE_SVG_PATH, calendar_plan_path=DEFAULT_CALENDAR_PLAN_PATH, calendar_report_path=DEFAULT_CALENDAR_REPORT_PATH, calendar_write_result_path=DEFAULT_CALENDAR_WRITE_RESULT_PATH, recommendation_plan_path=DEFAULT_RECOMMENDATION_PLAN_PATH, recommendation_report_path=DEFAULT_RECOMMENDATION_REPORT_PATH, reconciliation_path=DEFAULT_RECONCILIATION_PATH, reconciliation_report_path=DEFAULT_RECONCILIATION_REPORT_PATH, atlas_path=DEFAULT_ATLAS_PATH, atlas_report_path=DEFAULT_ATLAS_REPORT_PATH, one_shot_apply_script_path=DEFAULT_ONE_SHOT_APPLY_SCRIPT, html_path=DEFAULT_HTML_PATH, session_urn=DEFAULT_SESSION_URN, actor_urn=DEFAULT_ACTOR_URN, keep_channel_urn=DEFAULT_KEEP_CHANNEL_URN, keep_ki_urn=DEFAULT_KEEP_KI_URN, base_url=DEFAULT_BASE_URL, generated_at=format_utc(now(UTC)))
    index = nodes_by_urn(nodes)
    gates = Any[]

    health_status = string(object_value(health, :status, ""))
    push!(gates, gate(
        health_status == "ok" ? "pass" : "fail",
        "runtime health",
        health_status == "ok" ? "Kernel health endpoint is ok." : "Kernel health endpoint is not ok.",
        evidence=Dict(
            "ontology_version" => string(object_value(health, :ontology_version, "")),
            "t_day" => object_value(health, :t_day, nothing),
            "log_len" => object_value(health, :log_len, nothing),
        ),
        next_action=health_status == "ok" ? "" : "Repair kernel before trusting projections.",
    ))

    keep_channel = get(index, keep_channel_urn, nothing)
    keep_ki = get(index, keep_ki_urn, nothing)
    push!(gates, gate(
        keep_channel === nothing ? "fail" : "pass",
        "G input channel",
        keep_channel === nothing ? "Keep channel is missing from folded HG state." : "Keep channel exists as the G-ingest boundary.",
        evidence=Dict("urn" => keep_channel_urn, "type_id" => keep_channel === nothing ? "<missing>" : string(object_value(keep_channel, :type_id, ""))),
        next_action=keep_channel === nothing ? "Ingest or repair channel:google.keep.sam before reusing this lane." : "",
    ))
    push!(gates, gate(
        keep_ki === nothing ? "fail" : "pass",
        "G input knowledge item",
        keep_ki === nothing ? "Keep knowledge_item is missing from folded HG state." : "Keep knowledge_item exists as ingested evidence.",
        evidence=Dict("urn" => keep_ki_urn, "type_id" => keep_ki === nothing ? "<missing>" : string(object_value(keep_ki, :type_id, ""))),
        next_action=keep_ki === nothing ? "Re-run the Keep note ingest path before deriving from it." : "",
    ))
    keep_wf12 = relations_touching(relations, keep_ki_urn; category="WF12")
    push!(gates, gate(
        isempty(keep_wf12) ? "fail" : "pass",
        "G input evidence topology",
        isempty(keep_wf12) ? "Keep knowledge_item has no WF12 evidence relations in the folded state." : "Keep knowledge_item participates in WF12 evidence topology.",
        evidence=Dict("wf12_relation_count" => length(keep_wf12)),
        next_action=isempty(keep_wf12) ? "Link the channel/knowledge_item/claims with WF12 provides-kb before treating the note as graph evidence." : "",
    ))

    header = object_value(object_value(session_pack, :handoff, Dict()), :session_header, Dict())
    session_header_ok = string(object_value(header, :session_urn, "")) == session_urn && string(object_value(header, :actor, "")) == actor_urn
    push!(gates, gate(
        session_header_ok ? "pass" : "fail",
        "F session handoff header",
        session_header_ok ? "Session context pack carries the expected actor and session_urn." : "Session context pack does not carry the expected actor/session header.",
        evidence=Dict("session_pack" => session_pack_path, "actor" => object_value(header, :actor, ""), "session_urn" => object_value(header, :session_urn, "")),
        next_action=session_header_ok ? "" : "Regenerate session_context_projection.jl with explicit --session-urn and --actor-urn.",
    ))

    identity = object_value(session_pack, :identity, Dict())
    identity_status = string(object_value(identity, :status, ""))
    identity_gate_status = isempty(identity_status) ? "warn" : identity_status
    identity_actor = string(object_value(identity, :actor_urn, object_value(header, :actor, "")))
    identity_occupants = object_value(identity, :hg_occupant_urns, Any[])
    push!(gates, gate(
        identity_gate_status,
        "session actor/occupant reconciliation",
        identity_gate_status == "pass" ? "Session context pack reconciles actor_urn with the folded HG occupant and current IDE harness candidate." : "Session context pack does not fully reconcile actor_urn, folded HG occupant, and current IDE harness candidate.",
        evidence=Dict(
            "actor" => identity_actor,
            "occupants" => identity_occupants,
            "harness_kind" => object_value(identity, :harness_kind, ""),
            "harness_agent_urn" => object_value(identity, :harness_agent_urn, ""),
            "reasons" => object_value(identity, :reasons, Any[]),
        ),
        next_action=identity_gate_status == "pass" ? "" : string(object_value(identity, :next_action, "Regenerate the session pack with identity reconciliation metadata, then rotate or restage the occupant explicitly.")),
    ))

    opens_on_count = length(context_array(session_pack, :opens_on))
    occupant_count = length(context_array(session_pack, :occupants))
    purpose_count = length(context_array(session_pack, :purposes))
    scope_count = length(context_array(session_pack, :scope_roots))
    push!(gates, gate(
        opens_on_count > 0 && occupant_count > 0 && scope_count > 0 ? "pass" : "fail",
        "session occasion topology",
        "Session pack exposes kernel place, occupant, and scope roots.",
        evidence=Dict("opens_on" => opens_on_count, "occupants" => occupant_count, "scope_roots" => scope_count),
        next_action=opens_on_count > 0 && occupant_count > 0 && scope_count > 0 ? "" : "Repair WF19 opens-on/has-occupant/pins-urn topology before using this as a live session header.",
    ))
    push!(gates, gate(
        purpose_count > 0 ? "pass" : "warn",
        "session purpose color",
        purpose_count > 0 ? "Session has a durable has-purpose relation." : "Session has no durable has-purpose relation; the projection is using its focus string as temporary occasion color.",
        evidence=Dict("purposes" => purpose_count, "purpose_color" => object_value(session_pack, :purpose_color, "")),
        next_action=purpose_count > 0 ? "" : "When the durable purpose is clear, add/rotate the WF19 has-purpose relation instead of relying on a prompt focus string.",
    ))

    skill_count = array_len(session_pack, [:affordance_pack, :recommended_skills])
    extension_count = array_len(session_pack, [:affordance_pack, :recommended_extensions])
    mcp_count = array_len(session_pack, [:affordance_pack, :mcp_servers])
    push!(gates, gate(
        skill_count >= 5 && extension_count >= 1 && mcp_count >= 1 ? "pass" : "warn",
        "F affordance pack",
        "Session projection recommends concrete skills, VS Code extensions, and MCP servers.",
        evidence=Dict("skills" => skill_count, "extensions" => extension_count, "mcp_servers" => mcp_count),
        next_action=skill_count >= 5 && extension_count >= 1 && mcp_count >= 1 ? "" : "Regenerate the session pack after syncing skills/extensions/MCP config.",
    ))

    graph_kind_ok = string(object_value(graph_pack, :projection_kind, "")) == "graph_artifact_engineering"
    node_count = Int(object_value(graph_pack, :node_count, 0))
    relation_count = Int(object_value(graph_pack, :relation_count, 0))
    root_coverage = object_value(object_value(graph_pack, :analysis, Dict()), :root_coverage, Any[])
    push!(gates, gate(
        graph_kind_ok && node_count > 0 && relation_count > 0 && length(root_coverage) > 0 ? "pass" : "fail",
        "F graph artifact analysis",
        "Graph artifact projection produced a reviewable engineering frame with root coverage.",
        evidence=Dict("graph_pack" => graph_pack_path, "nodes" => node_count, "relations" => relation_count, "root_count" => length(root_coverage)),
        next_action=graph_kind_ok && node_count > 0 && relation_count > 0 && length(root_coverage) > 0 ? "" : "Regenerate graph_artifact_projection.jl and inspect root filters.",
    ))

    temporal_graph_kind_ok = string(object_value(temporal_graph_pack, :projection_kind, "")) == "graph_artifact_engineering"
    temporal_node_count = Int(object_value(temporal_graph_pack, :node_count, 0))
    temporal_relation_count = Int(object_value(temporal_graph_pack, :relation_count, 0))
    temporal_analysis = object_value(temporal_graph_pack, :analysis, Dict())
    temporal_root_coverage = object_value(temporal_analysis, :root_coverage, Any[])
    temporal_disconnected = [entry for entry in temporal_root_coverage if !Bool(object_value(entry, :connected, false))]
    push!(gates, gate(
        temporal_graph_kind_ok && temporal_node_count >= 4 && temporal_relation_count >= 2 ? (isempty(temporal_disconnected) ? "pass" : "warn") : "warn",
        "Temporal Calendar lens",
        temporal_graph_kind_ok && temporal_node_count > 0 ? "The Calendar Time-Fabric has its own graph artifact lens aligned with the temporal-calendar visual." : "The Calendar Time-Fabric does not yet have a dedicated graph artifact lens.",
        evidence=Dict("graph_pack" => temporal_graph_pack_path, "nodes" => temporal_node_count, "relations" => temporal_relation_count, "root_count" => length(temporal_root_coverage), "disconnected_root_count" => length(temporal_disconnected)),
        next_action=temporal_graph_kind_ok && temporal_node_count >= 4 && temporal_relation_count >= 2 ? (isempty(temporal_disconnected) ? "" : "Review the temporal roots and either connect them with valid topology or keep the warning visible.") : "Run the temporal-calendar graph artifact projection before treating the temporal SVG as a full inspection surface.",
    ))

    t189_graph_kind_ok = string(object_value(t189_graph_pack, :projection_kind, "")) == "graph_artifact_engineering"
    t189_node_count = Int(object_value(t189_graph_pack, :node_count, 0))
    t189_relation_count = Int(object_value(t189_graph_pack, :relation_count, 0))
    t189_root_coverage = object_value(object_value(t189_graph_pack, :analysis, Dict()), :root_coverage, Any[])
    t189_disconnected = [entry for entry in t189_root_coverage if !Bool(object_value(entry, :connected, false))]
    push!(gates, gate(
        t189_graph_kind_ok && t189_node_count >= 8 && t189_relation_count >= 8 && isempty(t189_disconnected) ? "pass" : "warn",
        "T189 recommendation lens",
        t189_graph_kind_ok && t189_node_count > 0 ? "The grouped recommendation apply has a dedicated graph artifact lens." : "The grouped recommendation apply is not visible through a dedicated graph artifact lens yet.",
        evidence=Dict("graph_pack" => t189_graph_pack_path, "nodes" => t189_node_count, "relations" => t189_relation_count, "root_count" => length(t189_root_coverage), "disconnected_root_count" => length(t189_disconnected)),
        next_action=t189_graph_kind_ok && t189_node_count >= 8 && t189_relation_count >= 8 && isempty(t189_disconnected) ? "" : "Regenerate the T189 recommendation graph artifact with roots for session, purpose, derivation, view_filter, and application group.",
    ))

    calendar_scope_kind_ok = string(object_value(calendar_scope_graph_pack, :projection_kind, "")) == "graph_artifact_engineering"
    calendar_scope_node_count = Int(object_value(calendar_scope_graph_pack, :node_count, 0))
    calendar_scope_relation_count = Int(object_value(calendar_scope_graph_pack, :relation_count, 0))
    calendar_scope_analysis = object_value(calendar_scope_graph_pack, :analysis, Dict())
    calendar_scope_root_coverage = object_value(calendar_scope_analysis, :root_coverage, Any[])
    calendar_scope_components = Int(object_value(calendar_scope_analysis, :component_count, 0))
    calendar_scope_largest = Int(object_value(calendar_scope_analysis, :largest_component_size, 0))
    calendar_scope_disconnected = [entry for entry in calendar_scope_root_coverage if !Bool(object_value(entry, :connected, false))]
    push!(gates, gate(
        calendar_scope_kind_ok && calendar_scope_node_count >= 10 && calendar_scope_relation_count >= 8 ? (isempty(calendar_scope_disconnected) ? "pass" : "warn") : "warn",
        "Calendar scope lens",
        calendar_scope_kind_ok && calendar_scope_node_count > 0 ? "The Calendar F/G surface has a dedicated scope graph with session, purpose, channel, programs, writer result, and G-ingest anchors visible." : "The Calendar F/G surface does not yet have a dedicated scope graph artifact.",
        evidence=Dict("graph_pack" => calendar_scope_graph_pack_path, "nodes" => calendar_scope_node_count, "relations" => calendar_scope_relation_count, "root_count" => length(calendar_scope_root_coverage), "disconnected_root_count" => length(calendar_scope_disconnected), "component_count" => calendar_scope_components, "largest_component_size" => calendar_scope_largest),
        next_action=calendar_scope_kind_ok && calendar_scope_node_count >= 10 && calendar_scope_relation_count >= 8 ? (isempty(calendar_scope_disconnected) ? "" : "Use the disconnected roots as the next topology worklist; do not treat Calendar as full-scope truth until those roots are related or intentionally out of scope.") : "Regenerate the Calendar scope graph artifact with the calendar-scope preset before relying on the Calendar report.",
    ))

    disconnected = [entry for entry in root_coverage if !Bool(object_value(entry, :connected, false))]
    push!(gates, gate(
        isempty(disconnected) ? "pass" : "warn",
        "visual lens root coverage",
        isempty(disconnected) ? "All explicit roots are relation-connected in the selected graph lens." : "Some explicit roots are visible only because the lens forces them into view; the selected relations do not connect them yet.",
        evidence=Dict("disconnected_root_count" => length(disconnected), "disconnected_roots" => [string(object_value(entry, :urn, "")) for entry in disconnected]),
        next_action=isempty(disconnected) ? "" : "Either widen the lens if relations already exist, or emit/link the missing topology when the relation is durable and valid under the operad.",
    ))

    dot_exists = isfile(dot_path)
    svg_exists = isfile(svg_path)
    temporal_dot_exists = isfile(temporal_dot_path)
    temporal_svg_exists = isfile(temporal_svg_path)
    t189_dot_exists = isfile(t189_dot_path)
    t189_svg_exists = isfile(t189_svg_path)
    calendar_scope_dot_exists = isfile(calendar_scope_dot_path)
    calendar_scope_svg_exists = isfile(calendar_scope_svg_path)
    push!(gates, gate(
        dot_exists && svg_exists && temporal_dot_exists && temporal_svg_exists && t189_dot_exists && t189_svg_exists && calendar_scope_dot_exists && calendar_scope_svg_exists ? "pass" : "warn",
        "static visual output",
        dot_exists && svg_exists && temporal_dot_exists && temporal_svg_exists && t189_dot_exists && t189_svg_exists && calendar_scope_dot_exists && calendar_scope_svg_exists ? "Session-occasion, temporal/calendar, T189 recommendation, and Calendar-scope DOT/SVG visual artifacts exist." : "One or more static visual artifacts are missing.",
        evidence=Dict("dot_path" => dot_path, "dot_exists" => dot_exists, "svg_path" => svg_path, "svg_exists" => svg_exists, "temporal_dot_path" => temporal_dot_path, "temporal_dot_exists" => temporal_dot_exists, "temporal_svg_path" => temporal_svg_path, "temporal_svg_exists" => temporal_svg_exists, "t189_dot_path" => t189_dot_path, "t189_dot_exists" => t189_dot_exists, "t189_svg_path" => t189_svg_path, "t189_svg_exists" => t189_svg_exists, "calendar_scope_dot_path" => calendar_scope_dot_path, "calendar_scope_dot_exists" => calendar_scope_dot_exists, "calendar_scope_svg_path" => calendar_scope_svg_path, "calendar_scope_svg_exists" => calendar_scope_svg_exists),
        next_action=dot_exists && svg_exists && temporal_dot_exists && temporal_svg_exists && t189_dot_exists && t189_svg_exists && calendar_scope_dot_exists && calendar_scope_svg_exists ? "" : "Run export_t200plus_projection.jl for session-occasion, temporal-calendar, t189-recommendations, and calendar-scope presets; install Graphviz if SVG is missing.",
    ))

    calendar_plan_exists = isfile(calendar_plan_path)
    calendar_report_exists = isfile(calendar_report_path)
    calendar_write_result_exists = isfile(calendar_write_result_path)
    planned_calendar_events = calendar_event_count(calendar_plan_path)
    push!(gates, gate(
        calendar_plan_exists && calendar_report_exists && planned_calendar_events > 0 ? "pass" : "warn",
        "Calendar time-fabric artifacts",
        calendar_plan_exists && calendar_report_exists && planned_calendar_events > 0 ? "Calendar time-fabric projection plan and Markdown report exist." : "Calendar time-fabric projection artifacts are missing or empty.",
        evidence=Dict("calendar_plan" => calendar_plan_path, "calendar_plan_exists" => calendar_plan_exists, "calendar_report" => calendar_report_path, "calendar_report_exists" => calendar_report_exists, "event_count" => planned_calendar_events, "write_result" => calendar_write_result_path, "write_result_exists" => calendar_write_result_exists),
        next_action=calendar_plan_exists && calendar_report_exists && planned_calendar_events > 0 ? "" : "Run calendar_time_fabric_projection.jl after the graph artifact projection, then use google_calendar_writer.jl only as an explicit actuator step.",
    ))

    recommendation_plan_exists = isfile(recommendation_plan_path)
    recommendation_report_exists = isfile(recommendation_report_path)
    recommendation_nodes = recommendation_node_count(recommendation_plan_path)
    selected_recommendations = selected_recommendation_count(recommendation_plan_path)
    push!(gates, gate(
        recommendation_plan_exists && recommendation_report_exists && recommendation_nodes > 0 && selected_recommendations == 5 ? "pass" : "warn",
        "T189/T200 recommendation artifacts",
        recommendation_plan_exists && recommendation_report_exists && recommendation_nodes > 0 && selected_recommendations == 5 ? "T189/T200 recommendation HG plan and Markdown report exist." : "Recommendation HG projection artifacts are missing, empty, or incomplete.",
        evidence=Dict("recommendation_plan" => recommendation_plan_path, "recommendation_plan_exists" => recommendation_plan_exists, "recommendation_report" => recommendation_report_path, "recommendation_report_exists" => recommendation_report_exists, "candidate_node_count" => recommendation_nodes, "selected_t189_recommendations" => selected_recommendations),
        next_action=recommendation_plan_exists && recommendation_report_exists && recommendation_nodes > 0 && selected_recommendations == 5 ? "" : "Run t189_t200_recommendation_projection.jl after the Calendar projection so the next sprint has candidate HG nodes/relations to inspect.",
    ))

    reconciliation_exists = isfile(reconciliation_path)
    reconciliation_report_exists = isfile(reconciliation_report_path)
    rec_summary = reconciliation_summary(reconciliation_path)
    grouped_nodes_applied = Int(object_value(rec_summary, :grouped_nodes_applied, 0))
    grouped_nodes_total = Int(object_value(rec_summary, :grouped_nodes_total, 0))
    grouped_relations_applied = Int(object_value(rec_summary, :grouped_relations_applied, 0))
    grouped_relations_total = Int(object_value(rec_summary, :grouped_relations_total, 0))
    calendar_event_nodes_applied = Int(object_value(rec_summary, :calendar_event_nodes_applied, 0))
    calendar_event_nodes_total = Int(object_value(rec_summary, :calendar_event_nodes_total, 0))
    calendar_event_nodes_pending = Int(object_value(rec_summary, :calendar_event_nodes_pending, 0))
    calendar_event_relations_applied = Int(object_value(rec_summary, :calendar_event_relations_applied, 0))
    calendar_event_relations_total = Int(object_value(rec_summary, :calendar_event_relations_total, 0))
    calendar_event_relations_pending = Int(object_value(rec_summary, :calendar_event_relations_pending, 0))
    deferred_relations = Int(object_value(rec_summary, :deferred_relations, 0))
    grouped_nodes_ok = Bool(object_value(rec_summary, :grouped_nodes_ok, false))
    grouped_relations_ok = Bool(object_value(rec_summary, :grouped_relations_ok, false))
    calendar_nodes_ok = calendar_event_nodes_total == 0 || calendar_event_nodes_pending == 0
    calendar_relations_ok = calendar_event_relations_total == 0 || calendar_event_relations_pending == 0
    reconciliation_ok = reconciliation_exists && reconciliation_report_exists && grouped_nodes_ok && grouped_relations_ok && calendar_nodes_ok && calendar_relations_ok && grouped_nodes_total > 0 && grouped_relations_total > 0
    push!(gates, gate(
        reconciliation_ok ? "pass" : "warn",
        "T189 recommendation reconciliation",
        reconciliation_ok ? "The dry recommendation plan is reconciled against folded HG state: grouped rows plus Calendar event nodes/session pins are applied when present." : "The recommendation plan has not been reconciled against folded HG state yet, or apply-ready rows are still pending.",
        evidence=Dict(
            "reconciliation" => reconciliation_path,
            "reconciliation_exists" => reconciliation_exists,
            "reconciliation_report" => reconciliation_report_path,
            "reconciliation_report_exists" => reconciliation_report_exists,
            "grouped_nodes_applied" => grouped_nodes_applied,
            "grouped_nodes_total" => grouped_nodes_total,
            "grouped_relations_applied" => grouped_relations_applied,
            "grouped_relations_total" => grouped_relations_total,
            "calendar_event_nodes_applied" => calendar_event_nodes_applied,
            "calendar_event_nodes_total" => calendar_event_nodes_total,
            "calendar_event_nodes_pending" => calendar_event_nodes_pending,
            "calendar_event_relations_applied" => calendar_event_relations_applied,
            "calendar_event_relations_total" => calendar_event_relations_total,
            "calendar_event_relations_pending" => calendar_event_relations_pending,
        ),
        next_action=reconciliation_ok ? "" : "Run t189_recommendation_reconciliation.jl after the recommendation HG plan, then inspect pending rows before any further APPLY work.",
    ))

    deferred_boundaries_ok = reconciliation_exists && deferred_relations > 0 && (calendar_event_nodes_total > 0 || calendar_event_nodes_pending > 0)
    deferred_detail = if deferred_boundaries_ok && calendar_event_nodes_pending == 0
        "Calendar event nodes and session pins are applied; WF07 source-anchor relations remain explicitly deferred for operad review."
    elseif deferred_boundaries_ok
        "Calendar event nodes and WF07 anchor relations remain explicitly pending/deferred instead of being silently applied."
    else
        "Deferred Calendar/WF07 boundaries are not visible in the reconciliation artifact."
    end
    push!(gates, gate(
        deferred_boundaries_ok ? "pass" : "warn",
        "deferred apply boundaries",
        deferred_detail,
        evidence=Dict(
            "calendar_event_nodes_applied" => calendar_event_nodes_applied,
            "calendar_event_nodes_total" => calendar_event_nodes_total,
            "calendar_event_nodes_pending" => calendar_event_nodes_pending,
            "calendar_event_relations_applied" => calendar_event_relations_applied,
            "calendar_event_relations_total" => calendar_event_relations_total,
            "calendar_event_relations_pending" => calendar_event_relations_pending,
            "deferred_relations" => deferred_relations,
            "grouped_nodes_ok" => grouped_nodes_ok,
            "grouped_relations_ok" => grouped_relations_ok,
        ),
        next_action=deferred_boundaries_ok ? "" : "Keep WF07 anchors and board repair out of live APPLY batches until the next explicit actor/operad review step.",
    ))

    filters = object_value(graph_pack, :filters, Dict())
    has_lens_controls = length(object_value(graph_pack, :root_urns, Any[])) > 0 && haskey(filters, :wfs) && haskey(filters, :ports) && haskey(filters, :types)
    push!(gates, gate(
        has_lens_controls ? "pass" : "warn",
        "lens flexibility controls",
        has_lens_controls ? "The graph projection records roots plus WF, port, type, and match filters." : "The graph projection does not expose enough lens controls for flexible scope inspection.",
        evidence=Dict("root_count" => length(object_value(graph_pack, :root_urns, Any[])), "filters" => filters),
        next_action=has_lens_controls ? "" : "Promote the lens spec to a shared JSON or view_filter-backed adapter.",
    ))

    lens_packs = [
        ("Session Occasion", graph_pack),
        ("Calendar Time-Fabric", temporal_graph_pack),
        ("T189 Recommendations", t189_graph_pack),
        ("Calendar Scope", calendar_scope_graph_pack),
    ]
    actor_lens_visibility = Dict(label => graph_pack_contains_node(pack, actor_urn) for (label, pack) in lens_packs)
    visible_agent_counts = Dict(label => Int(object_value(object_value(object_value(pack, :analysis, Dict()), :type_counts, Dict()), :agent, 0)) for (label, pack) in lens_packs)
    agent_visibility_ok = all(values(actor_lens_visibility))
    push!(gates, gate(
        agent_visibility_ok ? "pass" : "warn",
        "agent neighborhood visibility",
        agent_visibility_ok ? "The current actor/occupant agent is visible across all four graph artifacts and therefore reaches the SVG and inspector surfaces." : "One or more graph artifacts hide the current actor/occupant agent.",
        evidence=Dict("actor" => actor_urn, "lens_visibility" => actor_lens_visibility, "agent_counts" => visible_agent_counts),
        next_action=agent_visibility_ok ? "" : "Regenerate graph artifacts after enabling the session/program agent-neighborhood widening rule.",
    ))

    one_shot_apply_script_exists = isfile(one_shot_apply_script_path)
    push!(gates, gate(
        one_shot_apply_script_exists ? "warn" : "pass",
        "one-shot apply script cleanup",
        one_shot_apply_script_exists ? "The ignored one-shot grouped apply script still exists under tmp; it is not a projection artifact." : "No ignored one-shot grouped apply script remains under the generated projection tree.",
        evidence=Dict("one_shot_apply_script" => one_shot_apply_script_path, "exists" => one_shot_apply_script_exists),
        next_action=one_shot_apply_script_exists ? "Delete or archive the already-run apply script outside tmp/projections before treating the dashboard as the projection surface." : "",
    ))

    inspector = graph_inspector_payload(graph_pack; id="session-occasion", label="Session Occasion")
    temporal_inspector = graph_inspector_payload(temporal_graph_pack; id="temporal-calendar", label="Calendar Time-Fabric")
    t189_inspector = graph_inspector_payload(t189_graph_pack; id="t189-recommendations", label="T189 Recommendations")
    calendar_scope_inspector = graph_inspector_payload(calendar_scope_graph_pack; id="calendar-scope", label="Calendar Scope")
    inspectors = Any[inspector, temporal_inspector, t189_inspector, calendar_scope_inspector]
    inspector_ready = all(lens -> lens["node_count"] > 0 && lens["relation_count"] > 0, inspectors)
    push!(gates, gate(
        inspector_ready ? "pass" : "warn",
        "interactive visual aid",
        inspector_ready ? "The dashboard embeds Cytoscape.js typed element sets for four lenses: session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope." : "The dashboard does not yet have enough graph element data for all interactive browser/IDE graph lenses.",
        evidence=Dict("renderer" => "Cytoscape.js", "lens_count" => length(inspectors), "session_nodes" => inspector["node_count"], "session_relations" => inspector["relation_count"], "temporal_nodes" => temporal_inspector["node_count"], "temporal_relations" => temporal_inspector["relation_count"], "t189_nodes" => t189_inspector["node_count"], "t189_relations" => t189_inspector["relation_count"], "calendar_scope_nodes" => calendar_scope_inspector["node_count"], "calendar_scope_relations" => calendar_scope_inspector["relation_count"], "features" => ["type filters", "relation filters", "agent focus", "selected neighborhood", "multi-layout", "wide view", "lens JSON export", "F/G role metadata", "relation family counts", "top-degree node insights"], "context7_candidates_checked" => [candidate["name"] for candidate in RENDERER_CANDIDATES]),
        next_action=inspector_ready ? "" : "Regenerate all graph artifact packs before relying on the interactive inspector.",
    ))

    atlas_exists = isfile(atlas_path)
    atlas_report_exists = isfile(atlas_report_path)
    atlas = safe_read_json(atlas_path)
    atlas_surfaces = length(object_value(atlas, :surfaces, Any[]))
    atlas_pending = length(object_value(atlas, :pending_moves, Any[]))
    push!(gates, gate(
        atlas_exists && atlas_report_exists && atlas_surfaces >= 6 && atlas_pending >= 5 ? "pass" : "warn",
        "surface context atlas",
        atlas_exists && atlas_report_exists ? "The dashboard has a generated atlas explaining JSON, JSONL, Git, Calendar, dashboard, visual, type/relation/program, and pending-move surfaces." : "The surface context atlas is missing from the generated projection artifacts.",
        evidence=Dict("atlas" => atlas_path, "atlas_exists" => atlas_exists, "atlas_report" => atlas_report_path, "atlas_report_exists" => atlas_report_exists, "surface_count" => atlas_surfaces, "pending_move_count" => atlas_pending),
        next_action=atlas_exists && atlas_report_exists && atlas_surfaces >= 6 && atlas_pending >= 5 ? "" : "Run surface_context_atlas.jl after the first MVP gate pass, then regenerate the dashboard.",
    ))

    status = overall_status(gates)
    stages = pipeline_stages(gates)
    return Dict(
        "mode" => "plan",
        "projection_kind" => "session_pipeline_mvp_gate",
        "generated_at" => generated_at,
        "base_url" => base_url,
        "overall_status" => status,
        "health" => health,
        "lingo" => LINGO,
        "artifacts" => Dict(
            "session_pack" => session_pack_path,
            "graph_pack" => graph_pack_path,
            "temporal_graph_pack" => temporal_graph_pack_path,
            "t189_graph_pack" => t189_graph_pack_path,
            "calendar_scope_graph_pack" => calendar_scope_graph_pack_path,
            "dot" => dot_path,
            "svg" => svg_path,
            "temporal_calendar_dot" => temporal_dot_path,
            "temporal_calendar_svg" => temporal_svg_path,
            "t189_recommendation_dot" => t189_dot_path,
            "t189_recommendation_svg" => t189_svg_path,
            "calendar_scope_dot" => calendar_scope_dot_path,
            "calendar_scope_svg" => calendar_scope_svg_path,
            "calendar_time_fabric_plan" => calendar_plan_path,
            "calendar_time_fabric_report" => calendar_report_path,
            "calendar_time_fabric_write_result" => calendar_write_result_path,
            "recommendation_hg_plan" => recommendation_plan_path,
            "recommendation_hg_report" => recommendation_report_path,
            "recommendation_reconciliation" => reconciliation_path,
            "recommendation_reconciliation_report" => reconciliation_report_path,
            "surface_context_atlas" => atlas_path,
            "surface_context_atlas_report" => atlas_report_path,
            "dashboard" => html_path,
        ),
        "pipeline_stages" => stages,
        "interface_principles" => INTERFACE_PRINCIPLES,
        "renderer_candidates" => RENDERER_CANDIDATES,
        "visual_stack_notes" => VISUAL_STACK_NOTES,
        "interactive_inspector" => inspector,
        "interactive_inspectors" => inspectors,
        "gates" => gates,
        "priority_actions" => priority_actions(gates),
        "summary" => Dict(
            "pass" => count(g -> string(g["status"]) == "pass", gates),
            "warn" => count(g -> string(g["status"]) == "warn", gates),
            "fail" => count(g -> string(g["status"]) == "fail", gates),
        ),
    )
end

function html_escape(value)
    text = string(value)
    text = replace(text, "&" => "&amp;")
    text = replace(text, "<" => "&lt;")
    text = replace(text, ">" => "&gt;")
    text = replace(text, "\"" => "&quot;")
    return replace(text, "'" => "&#39;")
end

function compact_html_value(value; limit=220)
    text = ""
    if value isa AbstractDict
        parts = String[]
        for key in sort(collect(keys(value)); by=string)
            push!(parts, string(key, "=", compact_html_value(value[key]; limit=80)))
        end
        text = join(parts, "; ")
    elseif value isa AbstractVector
        items = [compact_html_value(item; limit=80) for item in value]
        text = join(items[1:min(length(items), 4)], ", ")
        length(items) > 4 && (text = string(text, ", +", length(items) - 4, " more"))
    else
        text = string(value)
    end
    return length(text) > limit ? string(text[1:limit], "...") : text
end

function artifact_link(html_path::AbstractString, artifact_path::AbstractString)
    isempty(strip(artifact_path)) && return "#"
    base_dir = dirname(html_path)
    return replace(relpath(artifact_path, base_dir), "\\" => "/")
end

function status_word(status)
    status == "pass" && return "Pass"
    status == "warn" && return "Warn"
    status == "fail" && return "Fail"
    return uppercase(string(status))
end

function write_html(path::AbstractString, plan)
    dir = dirname(path)
    !isempty(dir) && mkpath(dir)
    stages = object_value(plan, :pipeline_stages, Any[])
    gates = object_value(plan, :gates, Any[])
    actions = object_value(plan, :priority_actions, Any[])
    artifacts = object_value(plan, :artifacts, Dict())
    summary = object_value(plan, :summary, Dict())
    svg_path = string(object_value(artifacts, :svg, ""))
    svg_href = artifact_link(path, svg_path)
    temporal_svg_path = string(object_value(artifacts, :temporal_calendar_svg, ""))
    temporal_svg_href = artifact_link(path, temporal_svg_path)
    t189_svg_path = string(object_value(artifacts, :t189_recommendation_svg, ""))
    t189_svg_href = artifact_link(path, t189_svg_path)
    calendar_scope_svg_path = string(object_value(artifacts, :calendar_scope_svg, ""))
    calendar_scope_svg_href = artifact_link(path, calendar_scope_svg_path)
    svg_lenses = [
        Dict("label" => "Session Occasion", "svg_path" => svg_path, "svg_href" => svg_href, "dot_href" => artifact_link(path, string(object_value(artifacts, :dot, ""))), "missing" => "Session-occasion SVG is not present yet."),
        Dict("label" => "Calendar Time-Fabric", "svg_path" => temporal_svg_path, "svg_href" => temporal_svg_href, "dot_href" => artifact_link(path, string(object_value(artifacts, :temporal_calendar_dot, ""))), "missing" => "Temporal/calendar SVG is not present yet."),
        Dict("label" => "T189 Recommendations", "svg_path" => t189_svg_path, "svg_href" => t189_svg_href, "dot_href" => artifact_link(path, string(object_value(artifacts, :t189_recommendation_dot, ""))), "missing" => "T189 recommendation SVG is not present yet."),
        Dict("label" => "Calendar Scope", "svg_path" => calendar_scope_svg_path, "svg_href" => calendar_scope_svg_href, "dot_href" => artifact_link(path, string(object_value(artifacts, :calendar_scope_dot, ""))), "missing" => "Calendar-scope SVG is not present yet."),
    ]
    inspectors = collect(object_value(plan, :interactive_inspectors, Any[object_value(plan, :interactive_inspector, Dict("elements" => Any[], "node_count" => 0, "relation_count" => 0))]))
    inspector = isempty(inspectors) ? Dict("elements" => Any[], "node_count" => 0, "relation_count" => 0) : inspectors[1]
    visual_stack_notes = collect(object_value(plan, :visual_stack_notes, Any[]))
    inspector_json = json_literal(inspector)
    inspectors_json = json_literal(inspectors)
    open(path, "w") do io
        println(io, "<!doctype html>")
        println(io, "<html lang=\"en\">")
        println(io, "<head>")
        println(io, "<meta charset=\"utf-8\">")
        println(io, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
        println(io, "<title>mo:os Session Pipeline MVP</title>")
        println(io, "<style>")
        println(io, "html{font-family:Inter,Segoe UI,Arial,sans-serif;background:#f7f7f2;color:#202522}body{margin:0}.shell{max-width:1180px;margin:0 auto;padding:24px}.top{display:grid;grid-template-columns:minmax(0,1.7fr) minmax(260px,.8fr);gap:16px;align-items:stretch}.panel,.stage,.gate,.artifact,.principle{background:#fff;border:1px solid #d9ded7;border-radius:8px;box-shadow:0 1px 2px rgba(20,30,25,.05)}.panel{padding:18px}h1{font-size:28px;line-height:1.15;margin:0 0 8px}h2{font-size:16px;margin:0 0 12px}p{line-height:1.45}.muted{color:#5f6b62}.status{display:inline-flex;align-items:center;border-radius:999px;padding:3px 9px;font-size:12px;font-weight:700;text-transform:uppercase}.pass{background:#dff4df;color:#195d25}.warn{background:#fff0bd;color:#735600}.fail{background:#ffd8d3;color:#8a1f16}.summary{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:12px}.metric{border:1px solid #e3e6e0;border-radius:8px;padding:10px;background:#fafbf8}.metric strong{display:block;font-size:24px}.stageGrid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin:16px 0}.stage{padding:14px;min-height:138px}.stageHead{display:flex;justify-content:space-between;gap:8px;align-items:center;margin-bottom:8px}.stageName{font-weight:800}.stageDesc{font-size:13px;color:#46524a}.gateToolbar{display:flex;flex-wrap:wrap;gap:8px;margin:10px 0 12px}.gateToolbar button,.linkButton{border:1px solid #ccd3cb;background:#fff;border-radius:6px;padding:7px 10px;cursor:pointer;color:#24362e;text-decoration:none;display:inline-flex;align-items:center;gap:6px}.gateToolbar button.active{background:#24362e;color:#fff;border-color:#24362e}.gateList{display:grid;gap:8px}.gate{padding:12px}.gateTop{display:flex;align-items:center;justify-content:space-between;gap:12px}.gateName{font-weight:750}.evidence{font-size:12px;color:#526057;margin-top:8px;word-break:break-word}.next{border-left:3px solid #c68a00;background:#fff8df;padding:8px;margin-top:8px;border-radius:4px}.cols{display:grid;grid-template-columns:1fr 1fr;gap:16px}.artifactList,.principleList{display:grid;gap:8px}.artifact,.principle{padding:12px}.artifact a{color:#245c84;text-decoration:none;word-break:break-word}.artifact a:hover,.linkButton:hover{text-decoration:underline}.visualActions{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 12px}.actions{display:grid;gap:8px}.action{border-left:4px solid #c68a00;background:#fff8df;border-radius:6px;padding:10px}.foot{margin-top:22px;font-size:12px;color:#667168}@media(max-width:900px){.top,.cols,.stageGrid{grid-template-columns:1fr}.shell{padding:16px}}")
        println(io, ".inspectorGrid{display:grid;grid-template-columns:minmax(0,1.45fr) minmax(280px,.55fr);gap:12px}.cyBox{height:560px;border:1px solid #d9ded7;border-radius:8px;background:#fcfdf9}.inspectPane{border:1px solid #d9ded7;border-radius:8px;background:#fff;padding:12px;min-height:160px;overflow:auto}.inspectTitle{font-weight:800;margin-bottom:8px}.inspectMeta{font-size:12px;color:#526057;word-break:break-word}.inspectorTools,.filterRow{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 12px}.inspectorTools input,.svgSearch{border:1px solid #ccd3cb;border-radius:6px;padding:7px 10px;min-width:220px}.filterButton{border:1px solid #ccd3cb;background:#fff;border-radius:999px;padding:5px 9px;cursor:pointer;color:#24362e;font-size:12px}.filterButton.active{background:#24362e;color:#fff;border-color:#24362e}.legend{display:flex;flex-wrap:wrap;gap:6px;margin-top:10px}.legend span{font-size:11px;border:1px solid #d9ded7;border-radius:999px;padding:3px 7px;background:#fafbf8}.chip{display:inline-block;width:10px;height:10px;border-radius:999px;margin-right:5px;vertical-align:-1px}.inspectorBackdrop{display:none;position:fixed;inset:0;background:rgba(20,25,22,.55);z-index:30}.inspectorBackdrop.open{display:block}.inspectorPanel.wide{position:fixed;inset:22px;z-index:31;overflow:auto;box-shadow:0 18px 70px rgba(0,0,0,.35)}.inspectorPanel.wide .cyBox{height:calc(100vh - 335px);min-height:620px}.wideOnly{display:none}.inspectorPanel.wide .wideOnly{display:inline-flex}@media(max-width:900px){.inspectorGrid{grid-template-columns:1fr}.cyBox{height:460px}.inspectorPanel.wide{inset:10px}.inspectorPanel.wide .cyBox{height:calc(100vh - 410px);min-height:420px}}")
        println(io, ".insightGrid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px}.insightCard{border:1px solid #d9ded7;border-radius:8px;background:#fff;padding:12px}.insightCard h3{font-size:14px;margin:0 0 8px}.pillRow{display:flex;flex-wrap:wrap;gap:6px;margin:7px 0 10px}.pill{display:inline-flex;border:1px solid #d9ded7;border-radius:999px;background:#fafbf8;color:#24362e;font-size:11px;padding:3px 7px}.topNode{font-size:12px;color:#46524a;border-top:1px solid #eef0ec;padding-top:6px;margin-top:6px}.stackGrid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}@media(max-width:900px){.insightGrid,.stackGrid{grid-template-columns:1fr}}")
        println(io, ".visualPair{display:grid;grid-template-columns:1fr 1fr;gap:14px}.visualPanel{min-width:0}.visualTitle{font-weight:800;margin:0 0 8px}.visualPanel.wide{position:fixed;inset:22px;z-index:31;overflow:auto;box-shadow:0 18px 70px rgba(0,0,0,.35)}.visualPanel.wide .visualBox{height:calc(100vh - 270px);min-height:620px}.visualPanel.wide .wideOnly{display:inline-flex}.visualBox{border:1px solid #d9ded7;border-radius:8px;background:#fff;height:430px;overflow:auto;position:relative}.visualCanvas{width:1080px;height:680px}.visualCanvas object{width:1080px;height:680px;display:block;transform-origin:0 0}.visualHelp{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px;margin:10px 0 12px}.visualHelp div{border:1px solid #e3e6e0;border-radius:8px;padding:9px;background:#fafbf8}.lensTabs,.svgTabs{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 12px}.lensTabs button,.svgTabs button{border:1px solid #ccd3cb;background:#fff;border-radius:6px;padding:7px 10px;cursor:pointer;color:#24362e}.lensTabs button.active,.svgTabs button.active{background:#24362e;color:#fff;border-color:#24362e}@media(max-width:900px){.visualPair,.visualHelp{grid-template-columns:1fr}.visualBox{height:380px}.visualPanel.wide{inset:10px}.visualPanel.wide .visualBox{height:calc(100vh - 340px);min-height:420px}}")
        println(io, "</style>")
        println(io, "</head>")
        println(io, "<body>")
        println(io, "<main class=\"shell\">")
        println(io, "<section class=\"top\">")
        println(io, "<div class=\"panel\">")
        println(io, "<span class=\"status ", html_escape(plan["overall_status"]), "\">", status_word(string(plan["overall_status"])), "</span>")
        println(io, "<h1>Session Pipeline MVP</h1>")
        println(io, "<p class=\"muted\">A dry control surface for the Keep-note G-ingest, session F-projection, and visual-lens F-projection lane. HG remains the source of truth; this page is a readable materialization of the current checks.</p>")
        println(io, "<div class=\"summary\">")
        println(io, "<div class=\"metric\"><strong>", html_escape(object_value(summary, :pass, 0)), "</strong><span>pass</span></div>")
        println(io, "<div class=\"metric\"><strong>", html_escape(object_value(summary, :warn, 0)), "</strong><span>warn</span></div>")
        println(io, "<div class=\"metric\"><strong>", html_escape(object_value(summary, :fail, 0)), "</strong><span>fail</span></div>")
        println(io, "</div></div>")
        health = object_value(plan, :health, Dict())
        println(io, "<div class=\"panel\"><h2>Runtime</h2>")
        println(io, "<p><strong>", html_escape(object_value(health, :status, "unknown")), "</strong></p>")
        println(io, "<p class=\"muted\">ontology ", html_escape(object_value(health, :ontology_version, "")), "<br>t_day ", html_escape(object_value(health, :t_day, "")), "<br>log_len ", html_escape(object_value(health, :log_len, "")), "</p>")
        println(io, "<p class=\"muted\">Generated ", html_escape(plan["generated_at"]), "</p></div>")
        println(io, "</section>")
        println(io, "<section class=\"stageGrid\">")
        for stage in stages
            status = string(stage["status"])
            println(io, "<article class=\"stage\"><div class=\"stageHead\"><div><div class=\"stageName\">", html_escape(stage["name"]), "</div><div class=\"muted\">", html_escape(stage["short_name"]), "</div></div><span class=\"status ", html_escape(status), "\">", status_word(status), "</span></div><p class=\"stageDesc\">", html_escape(stage["description"]), "</p><p class=\"muted\">", html_escape(stage["summary"]["pass"]), " pass / ", html_escape(stage["summary"]["warn"]), " warn / ", html_escape(stage["summary"]["fail"]), " fail</p></article>")
        end
        println(io, "</section>")
        println(io, "<section class=\"cols\">")
        println(io, "<div class=\"panel\"><h2>Priority Actions</h2><div class=\"actions\">")
        if isempty(actions)
            println(io, "<p class=\"muted\">No failing or warning gates with next actions.</p>")
        else
            for action in actions
                println(io, "<div class=\"action\"><span class=\"status ", html_escape(action["status"]), "\">", status_word(string(action["status"])), "</span><p><strong>", html_escape(action["gate"]), "</strong><br>", html_escape(action["action"]), "</p></div>")
            end
        end
        println(io, "</div></div>")
        println(io, "<div class=\"panel\"><h2>Review Surfaces</h2><div class=\"artifactList\">")
        println(io, "<div class=\"artifact\"><strong>Atlas</strong><p class=\"muted\">Table of contents for the projection surfaces and next moves.</p><a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :surface_context_atlas_report, "")))), "\">Open report</a> · <a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :surface_context_atlas, "")))), "\">JSON</a></div>")
        println(io, "<div class=\"artifact\"><strong>Graph Artifacts</strong><p class=\"muted\">Engineering JSON/Markdown for the four interactive lenses.</p><a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :graph_pack, "")))), "\">Session</a> · <a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :temporal_graph_pack, "")))), "\">Time-Fabric</a> · <a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :t189_graph_pack, "")))), "\">T189</a> · <a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_scope_graph_pack, "")))), "\">Calendar Scope</a></div>")
        println(io, "<div class=\"artifact\"><strong>Calendar</strong><p class=\"muted\">Dry time-fabric plan plus explicit Google writer result.</p><a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_report, "")))), "\">Report</a> · <a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_plan, "")))), "\">Plan</a> · <a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_write_result, "")))), "\">Write result</a></div>")
        println(io, "<div class=\"artifact\"><strong>Recommendations</strong><p class=\"muted\">Candidate HG plan and folded-state reconciliation.</p><a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_hg_report, "")))), "\">Plan report</a> · <a href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_reconciliation_report, "")))), "\">Reconciliation</a></div>")
        println(io, "<div class=\"artifact\"><strong>MVP Gate</strong><p class=\"muted\">Current pass/warn/fail contract for the local control surface.</p><a href=\"mvp/session_pipeline_gate.md\">Gate report</a> · <a href=\"mvp/session_pipeline_gate.json\">JSON</a></div>")
        println(io, "</div></div>")
        println(io, "</section>")
        println(io, "<div id=\"svgBackdrop\" class=\"inspectorBackdrop\"></div>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>Visual Lenses</h2>")
        println(io, "<div class=\"visualHelp\"><div><strong>SVG zoom pane</strong><p class=\"muted\">Static Graphviz proof frame. Use Fit for topology, Zoom for label work, and Wide view for a review pass.</p></div><div><strong>Interactive HG inspector</strong><p class=\"muted\">Typed graph-artifact JSON below. Use it when you need selectable node and relation metadata.</p></div></div>")
        println(io, "<div class=\"visualPair\">")
        for (index, lens) in enumerate(svg_lenses)
            println(io, "<div class=\"visualPanel\" data-svg-panel=\"", index - 1, "\"><p class=\"visualTitle\">", html_escape(lens["label"]), "</p>")
            if !isempty(string(lens["svg_path"])) && isfile(string(lens["svg_path"]))
                println(io, "<div class=\"visualActions\"><input class=\"svgSearch\" data-svg-search type=\"search\" placeholder=\"Find label or URN\"><button class=\"linkButton\" type=\"button\" data-svg-action=\"svg-find\">Find</button><button class=\"linkButton\" type=\"button\" data-svg-action=\"fit\">Fit</button><button class=\"linkButton\" type=\"button\" data-svg-action=\"center\">Center</button><button class=\"linkButton\" type=\"button\" data-svg-action=\"zoom-in\">Zoom +</button><button class=\"linkButton\" type=\"button\" data-svg-action=\"zoom-out\">Zoom -</button><button class=\"linkButton\" type=\"button\" data-svg-action=\"reset\">Reset</button><button class=\"linkButton\" type=\"button\" data-svg-action=\"wide\">Wide view</button><button class=\"linkButton wideOnly\" type=\"button\" data-svg-action=\"close\">Close</button><a class=\"linkButton\" href=\"", html_escape(lens["svg_href"]), "\">Open SVG</a><a class=\"linkButton\" href=\"", html_escape(lens["dot_href"]), "\">Open DOT</a></div>")
                println(io, "<div class=\"visualBox\" data-svg-scale=\"1\"><div class=\"visualCanvas\"><object type=\"image/svg+xml\" data=\"", html_escape(lens["svg_href"]), "\"></object></div></div>")
            else
                println(io, "<p class=\"muted\">", html_escape(lens["missing"]), "</p>")
            end
            println(io, "</div>")
        end
        println(io, "</div>")
        println(io, "</section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>F/G Relation Insights</h2>")
        println(io, "<p class=\"muted\">Per-lens visual metadata derived from node types and WF categories. This keeps projection, ingest, authority, surface, and lineage meaning visible in the graphview without changing HG truth.</p>")
        println(io, "<div class=\"insightGrid\">")
        for lens in inspectors
            println(io, "<article class=\"insightCard\"><h3>", html_escape(object_value(lens, :label, "Lens")), "</h3>")
            println(io, "<div class=\"muted\">F/G roles</div><div class=\"pillRow\">")
            print_count_chips(io, object_value(lens, :fg_counts, Dict()))
            println(io, "</div><div class=\"muted\">Relation families</div><div class=\"pillRow\">")
            print_count_chips(io, object_value(lens, :relation_family_counts, Dict()))
            println(io, "</div>")
            top_nodes = collect(object_value(lens, :top_nodes, Any[]))
            for node in top_nodes[1:min(3, length(top_nodes))]
                println(io, "<div class=\"topNode\"><strong>", html_escape(object_value(node, :label, object_value(node, :urn, ""))), "</strong><br>", html_escape(object_value(node, :fg_role, "")), " · degree ", html_escape(object_value(node, :degree, 0)), "</div>")
            end
            println(io, "</article>")
        end
        println(io, "</div></section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>Calendar Time-Fabric</h2>")
        println(io, "<div class=\"visualActions\"><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_plan, "")))), "\">Open Calendar Plan</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_report, "")))), "\">Open Calendar Report</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_write_result, "")))), "\">Open Write Result</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :temporal_graph_pack, "")))), "\">Open Graph Artifact</a></div>")
        println(io, "<p class=\"muted\">Temporal plan, temporal visual lens, and temporal graph artifact are now separate review surfaces: plan for Calendar payload semantics, SVG/DOT for deterministic visual review, and the HG inspector for node/relation inspection.</p>")
        println(io, "</section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>HG Recommendations</h2>")
        println(io, "<div class=\"visualActions\"><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_hg_plan, "")))), "\">Open Recommendation Plan</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_hg_report, "")))), "\">Open Recommendation Report</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_reconciliation, "")))), "\">Open Reconciliation</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_reconciliation_report, "")))), "\">Open Reconciliation Report</a></div>")
        println(io, "<p class=\"muted\">Dry candidate nodes and relations for the five T189 recommendations plus the T200+ convergence arc, reconciled against folded HG state. This panel is a projection surface; it does not apply rewrites.</p>")
        println(io, "</section>")
        println(io, "<div id=\"inspectorBackdrop\" class=\"inspectorBackdrop\"></div>")
        println(io, "<section id=\"inspectorPanel\" class=\"panel inspectorPanel\" style=\"margin-top:16px\"><h2>Interactive HG Inspector</h2>")
        println(io, "<div class=\"lensTabs\" id=\"lensTabs\">")
        for (index, lens) in enumerate(inspectors)
            active = index == 1 ? " active" : ""
            println(io, "<button class=\"", active, "\" data-lens=\"", index - 1, "\">", html_escape(object_value(lens, :label, string("Lens ", index))), " <span class=\"muted\">", html_escape(object_value(lens, :node_count, 0)), "/", html_escape(object_value(lens, :relation_count, 0)), "</span></button>")
        end
        println(io, "</div>")
        println(io, "<div class=\"inspectorTools\"><input id=\"cySearch\" type=\"search\" placeholder=\"Search URN, label, type, relation\"><button class=\"linkButton\" id=\"cyFit\" type=\"button\">Fit</button><button class=\"linkButton\" id=\"cyZoomIn\" type=\"button\">Zoom +</button><button class=\"linkButton\" id=\"cyZoomOut\" type=\"button\">Zoom -</button><button class=\"linkButton\" id=\"cyReset\" type=\"button\">Reset</button><button class=\"linkButton\" id=\"cyCose\" type=\"button\">Cose</button><button class=\"linkButton\" id=\"cyGrid\" type=\"button\">Grid</button><button class=\"linkButton\" id=\"cyCircle\" type=\"button\">Circle</button><button class=\"linkButton\" id=\"cyBreadth\" type=\"button\">Breadth</button><button class=\"linkButton\" id=\"cyConcentric\" type=\"button\">Concentric</button><button class=\"linkButton\" id=\"cyAgents\" type=\"button\">Agents</button><button class=\"linkButton\" id=\"cyNeighborhood\" type=\"button\">Neighborhood</button><button class=\"linkButton\" id=\"cyExport\" type=\"button\">Export lens JSON</button><button class=\"linkButton\" id=\"cyWide\" type=\"button\">Wide view</button><button class=\"linkButton wideOnly\" id=\"cyClose\" type=\"button\">Close</button></div>")
        println(io, "<div class=\"filterRow\" id=\"cyTypeFilters\"></div><div class=\"filterRow\" id=\"cyRelationFilters\"></div>")
        println(io, "<div class=\"inspectorGrid\"><div id=\"cy\" class=\"cyBox\"></div><div class=\"inspectPane\"><div class=\"inspectTitle\" id=\"inspectTitle\">No selection</div><div class=\"inspectMeta\" id=\"inspectMeta\">", html_escape(inspector["node_count"]), " nodes / ", html_escape(inspector["relation_count"]), " relations</div></div></div>")
        println(io, "<div class=\"legend\"><span><i class=\"chip\" style=\"background:#4c78a8\"></i>claim</span><span><i class=\"chip\" style=\"background:#7b61a8\"></i>derivation</span><span><i class=\"chip\" style=\"background:#9c755f\"></i>program</span><span><i class=\"chip\" style=\"background:#b279a2\"></i>purpose</span><span><i class=\"chip\" style=\"background:#72b7b2\"></i>view_filter</span><span><i class=\"chip\" style=\"background:#54a24b\"></i>knowledge_item</span><span><i class=\"chip\" style=\"background:#4267a5\"></i>agent</span></div>")
        println(io, "</section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>Surface Context Atlas</h2>")
        println(io, "<div class=\"visualActions\"><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :surface_context_atlas, "")))), "\">Open Atlas JSON</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :surface_context_atlas_report, "")))), "\">Open Atlas Report</a></div>")
        println(io, "<p class=\"muted\">Explanatory map for JSON API, JSONL log, Git repositories, Google Calendar, dashboard, visuals, node types, relation families, IRL/external programs, existing HG anchors, and next-round moves. Use this as the human/agent table of contents before changing projections.</p>")
        println(io, "</section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>Gates</h2><div class=\"gateToolbar\"><button class=\"active\" data-filter=\"all\">All</button><button data-filter=\"pass\">Pass</button><button data-filter=\"warn\">Warn</button><button data-filter=\"fail\">Fail</button></div><div class=\"gateList\">")
        for gate in gates
            status = string(gate["status"])
            evidence = compact_html_value(gate["evidence"])
            println(io, "<article class=\"gate\" data-status=\"", html_escape(status), "\"><div class=\"gateTop\"><div class=\"gateName\">", html_escape(gate["name"]), "</div><span class=\"status ", html_escape(status), "\">", status_word(status), "</span></div><p>", html_escape(gate["detail"]), "</p><div class=\"evidence\">", html_escape(evidence), "</div>")
            if !isempty(strip(string(gate["next_action"])))
                println(io, "<div class=\"next\"><strong>Next:</strong> ", html_escape(gate["next_action"]), "</div>")
            end
            println(io, "</article>")
        end
        println(io, "</div></section>")
        println(io, "<section class=\"cols\" style=\"margin-top:16px\">")
        println(io, "<div class=\"panel\"><h2>Interface Principles</h2><div class=\"principleList\">")
        for principle in plan["interface_principles"]
            println(io, "<div class=\"principle\"><strong>", html_escape(principle["name"]), "</strong><p class=\"muted\">", html_escape(principle["source"]), "</p><p>", html_escape(principle["application"]), "</p></div>")
        end
        println(io, "</div></div>")
        println(io, "<div class=\"panel\"><h2>Renderer Candidates</h2><div class=\"principleList\">")
        for candidate in plan["renderer_candidates"]
            println(io, "<div class=\"principle\"><strong>", html_escape(candidate["name"]), "</strong> <span class=\"muted\">", html_escape(candidate["recommendation"]), "</span><p>", html_escape(candidate["fit"]), "</p></div>")
        end
        println(io, "</div></div></section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>Graphview Stack Notes</h2><div class=\"stackGrid\">")
        for note in visual_stack_notes
            println(io, "<div class=\"principle\"><strong>", html_escape(object_value(note, :name, "Note")), "</strong><p>", html_escape(object_value(note, :guidance, "")), "</p></div>")
        end
        println(io, "</div></section>")
        println(io, "<p class=\"foot\">Generated from session_pipeline_mvp_gate.jl. This page is an artifact of the projection lane; it does not emit rewrites.</p>")
        println(io, "</main>")
        println(io, "<script>document.querySelectorAll('[data-filter]').forEach(function(btn){btn.addEventListener('click',function(){document.querySelectorAll('[data-filter]').forEach(function(b){b.classList.remove('active')});btn.classList.add('active');var f=btn.getAttribute('data-filter');document.querySelectorAll('.gate').forEach(function(g){g.style.display=(f==='all'||g.getAttribute('data-status')===f)?'block':'none'});});});</script>")
        println(io, raw"""<script>(function(){var BASE_W=1080,BASE_H=680;var backdrop=document.getElementById('svgBackdrop');var activeWide=null;function setScale(panel,scale){var box=panel.querySelector('.visualBox');var canvas=panel.querySelector('.visualCanvas');var object=panel.querySelector('object');if(!box||!canvas||!object)return;scale=Math.max(.3,Math.min(3,scale));box.dataset.svgScale=String(scale);canvas.style.width=Math.ceil(BASE_W*scale)+'px';canvas.style.height=Math.ceil(BASE_H*scale)+'px';object.style.transform='scale('+scale+')'}function fit(panel){var box=panel.querySelector('.visualBox');if(!box)return;setScale(panel,Math.max(.3,Math.min(1.4,(box.clientWidth-24)/BASE_W)));box.scrollTo({left:0,top:0,behavior:'smooth'})}function objectDoc(panel){try{var object=panel.querySelector('object');return object&&object.contentDocument}catch(_){return null}}function clearMatches(panel){var doc=objectDoc(panel);if(!doc)return;doc.querySelectorAll('[data-moos-svg-match]').forEach(function(el){el.removeAttribute('data-moos-svg-match');el.style.outline='';el.style.stroke='';el.style.strokeWidth='';el.style.filter=''})}function centerOn(panel,el){var box=panel.querySelector('.visualBox');var scale=Number(box&&box.dataset.svgScale||1);if(!box||!el||!el.getBBox)return;try{var bb=el.getBBox();box.scrollTo({left:Math.max(0,(bb.x+bb.width/2)*scale-box.clientWidth/2),top:Math.max(0,(bb.y+bb.height/2)*scale-box.clientHeight/2),behavior:'smooth'})}catch(_){}}function find(panel){clearMatches(panel);var q=(panel.querySelector('[data-svg-search]')?.value||'').toLowerCase().trim();if(!q)return null;var doc=objectDoc(panel);if(!doc)return null;var matches=[];doc.querySelectorAll('text,title').forEach(function(el){var text=(el.textContent||'').toLowerCase();if(text.indexOf(q)>=0){var target=el.tagName.toLowerCase()==='title'?el.parentElement:el;matches.push(target);target.setAttribute('data-moos-svg-match','1');target.style.outline='3px solid #202522';target.style.stroke='#202522';target.style.strokeWidth='2px'}});panel.dataset.svgMatchIndex='0';if(matches[0])centerOn(panel,matches[0]);return matches[0]||null}function centerCurrent(panel){var doc=objectDoc(panel);var match=doc&&doc.querySelector('[data-moos-svg-match]');if(match){centerOn(panel,match);return}var object=panel.querySelector('object');var box=panel.querySelector('.visualBox');if(object&&box){box.scrollTo({left:Math.max(0,object.clientWidth/2-box.clientWidth/2),top:Math.max(0,object.clientHeight/2-box.clientHeight/2),behavior:'smooth'})}}function setWide(panel,on){if(on){if(activeWide&&activeWide!==panel){setWide(activeWide,false)}activeWide=panel;panel.classList.add('wide');if(backdrop)backdrop.classList.add('open');setTimeout(function(){fit(panel)},80)}else{panel.classList.remove('wide');if(activeWide===panel)activeWide=null;if(backdrop)backdrop.classList.remove('open');setTimeout(function(){fit(panel)},80)}}document.querySelectorAll('[data-svg-panel]').forEach(function(panel){setScale(panel,1);var search=panel.querySelector('[data-svg-search]');if(search){search.addEventListener('keydown',function(evt){if(evt.key==='Enter')find(panel)})}panel.querySelectorAll('[data-svg-action]').forEach(function(button){button.addEventListener('click',function(){var action=button.getAttribute('data-svg-action');var scale=Number(panel.querySelector('.visualBox')?.dataset.svgScale||1);if(action==='svg-find')find(panel);if(action==='fit')fit(panel);if(action==='center')centerCurrent(panel);if(action==='zoom-in')setScale(panel,scale*1.25);if(action==='zoom-out')setScale(panel,scale*.8);if(action==='reset'){clearMatches(panel);setScale(panel,1)}if(action==='wide')setWide(panel,true);if(action==='close')setWide(panel,false)})})});if(backdrop){backdrop.addEventListener('click',function(){if(activeWide)setWide(activeWide,false)})}document.addEventListener('keydown',function(evt){if(evt.key==='Escape'&&activeWide){setWide(activeWide,false)}});})();</script>""")
        println(io, "<script src=\"https://unpkg.com/cytoscape@3.28.1/dist/cytoscape.min.js\"></script>")
        println(io, "<script id=\"inspectorData\" type=\"application/json\">", inspector_json, "</script>")
        println(io, "<script id=\"inspectorsData\" type=\"application/json\">", inspectors_json, "</script>")
        println(io, raw"""<script>(function(){var raw=document.getElementById('inspectorsData');var title=document.getElementById('inspectTitle');var meta=document.getElementById('inspectMeta');var buttons=document.querySelectorAll('[data-lens]');var search=document.getElementById('cySearch');var fit=document.getElementById('cyFit');var zoomIn=document.getElementById('cyZoomIn');var zoomOut=document.getElementById('cyZoomOut');var reset=document.getElementById('cyReset');var cose=document.getElementById('cyCose');var grid=document.getElementById('cyGrid');var circle=document.getElementById('cyCircle');var breadth=document.getElementById('cyBreadth');var concentric=document.getElementById('cyConcentric');var agentsBtn=document.getElementById('cyAgents');var neighborhoodBtn=document.getElementById('cyNeighborhood');var exportBtn=document.getElementById('cyExport');var typeFilters=document.getElementById('cyTypeFilters');var relationFilters=document.getElementById('cyRelationFilters');var wide=document.getElementById('cyWide');var close=document.getElementById('cyClose');var panel=document.getElementById('inspectorPanel');var backdrop=document.getElementById('inspectorBackdrop');var lenses=raw?JSON.parse(raw.textContent):[];var cy=null,currentLens=null,activeTypes=new Set(),activeRelations=new Set(),lastSelected=null;function esc(v){return String(v==null?'':v).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]})}function unique(values){return Array.from(new Set(values.filter(Boolean))).sort()}function showLensMeta(data){var agentCount=(data.agent_urns||[]).length;title.textContent=data.label||'Lens';meta.innerHTML=esc(data.node_count||0)+' nodes / '+esc(data.relation_count||0)+' relations<br><strong>agents</strong> '+esc(agentCount)+'<br><strong>types</strong> '+esc(Object.keys(data.type_counts||{}).join(', '))}function show(d){var kind=d.type_id||d.rewrite_category||'relation';var ports=d.src_port?'<br><strong>ports</strong> '+esc(d.src_port)+' / '+esc(d.tgt_port):'';var degree=d.degree!=null?'<br><strong>degree</strong> '+esc(d.degree):'';title.textContent=d.title||d.label||d.urn||'Selection';meta.innerHTML='<strong>'+esc(kind)+'</strong><br>'+esc(d.urn||d.id||'')+'<br>'+esc(d.status||'')+degree+ports}function runLayout(name){if(!cy)return;var opts={name:name,animate:false,fit:true,padding:32};if(name==='breadthfirst'){opts.directed=true;opts.spacingFactor=1.2}if(name==='concentric'){opts.concentric=function(n){return n.degree()+1};opts.levelWidth=function(){return 2}}if(name==='cose'){opts.nodeRepulsion=9000;opts.idealEdgeLength=110}cy.layout(opts).run()}function resizeFit(){if(!cy)return;cy.resize();cy.fit(null,32)}function zoomBy(factor){if(!cy)return;var box=cy.container().getBoundingClientRect();cy.zoom({level:cy.zoom()*factor,renderedPosition:{x:box.width/2,y:box.height/2}})}function setWide(on){if(!panel)return;panel.classList.toggle('wide',on);if(backdrop)backdrop.classList.toggle('open',on);setTimeout(resizeFit,80)}function applyFilters(){if(!cy)return;cy.elements().removeClass('filtered');cy.nodes().forEach(function(n){if(activeTypes.size&& !activeTypes.has(n.data('type_id'))){n.addClass('filtered')}});cy.edges().forEach(function(e){if((activeRelations.size&& !activeRelations.has(e.data('rewrite_category'))) || e.source().hasClass('filtered') || e.target().hasClass('filtered')){e.addClass('filtered')}});applySearch(false)}function renderFilters(data){function render(container,values,activeSet,prefix){if(!container)return;container.innerHTML='';values.forEach(function(value){activeSet.add(value);var b=document.createElement('button');b.type='button';b.className='filterButton active';b.textContent=prefix+' '+value;b.addEventListener('click',function(){if(activeSet.has(value)){activeSet.delete(value);b.classList.remove('active')}else{activeSet.add(value);b.classList.add('active')}applyFilters()});container.appendChild(b)})}activeTypes=new Set();activeRelations=new Set();var nodeTypes=unique((data.elements||[]).filter(function(e){return e.data&&e.data.type_id}).map(function(e){return e.data.type_id}));var relTypes=unique((data.elements||[]).filter(function(e){return e.data&&e.data.rewrite_category}).map(function(e){return e.data.rewrite_category}));render(typeFilters,nodeTypes,activeTypes,'T');render(relationFilters,relTypes,activeRelations,'WF')}function applySearch(fitMatches){if(!cy)return;var q=(search.value||'').toLowerCase().trim();cy.elements().removeClass('matched dimmed');if(!q){return}cy.elements().not('.filtered').forEach(function(ele){var d=ele.data();var hay=[d.urn,d.label,d.title,d.type_id,d.rewrite_category,d.src_port,d.tgt_port].join(' ').toLowerCase();if(hay.indexOf(q)>=0){ele.addClass('matched')}else{ele.addClass('dimmed')}});var matched=cy.elements('.matched').not('.filtered');if(fitMatches!==false&&matched.length){cy.fit(matched,48)}}function focusCollection(collection){if(!cy||!collection||!collection.length)return;cy.elements().removeClass('matched dimmed');var expanded=collection.union(collection.neighborhood()).not('.filtered');expanded.addClass('matched');cy.elements().not(expanded).not('.filtered').addClass('dimmed');cy.fit(expanded,48)}function focusAgents(){if(!cy)return;focusCollection(cy.nodes('[type_id = "agent"]').not('.filtered'))}function focusNeighborhood(){if(!cy)return;var selected=cy.$(':selected').not('.filtered');if(selected.length){focusCollection(selected);return}var agents=cy.nodes('[type_id = "agent"]').not('.filtered');if(agents.length){focusCollection(agents)}}function exportLens(){if(!currentLens)return;var blob=new Blob([JSON.stringify(currentLens,null,2)],{type:'application/json'});var a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=(currentLens.label||'moos-lens').toLowerCase().replace(/[^a-z0-9]+/g,'-')+'.json';document.body.appendChild(a);a.click();setTimeout(function(){URL.revokeObjectURL(a.href);a.remove()},0)}function activate(index){buttons.forEach(function(btn){btn.classList.toggle('active',Number(btn.getAttribute('data-lens'))===index)});if(search){search.value=''}var data=lenses[index]||{label:'Lens',elements:[],node_count:0,relation_count:0,type_counts:{},relation_counts:{},agent_urns:[]};currentLens=data;showLensMeta(data);renderFilters(data);if(!window.cytoscape){title.textContent='Cytoscape.js unavailable';return}if(cy){cy.destroy()}cy=cytoscape({container:document.getElementById('cy'),elements:data.elements||[],layout:{name:'cose',animate:false,fit:true,padding:32,nodeRepulsion:9000,idealEdgeLength:110},minZoom:.18,maxZoom:3.5,style:[{selector:'node',style:{'label':'data(label)','font-size':10,'text-wrap':'wrap','text-max-width':120,'background-color':'#6f7f73','color':'#24362e','text-valign':'bottom','text-halign':'center','width':'mapData(degree,0,8,28,54)','height':'mapData(degree,0,8,28,54)','border-width':1,'border-color':'#ffffff'}},{selector:'node[type_id = "agent"]',style:{'background-color':'#4267a5'}},{selector:'node[type_id = "claim"]',style:{'background-color':'#4c78a8'}},{selector:'node[type_id = "derivation"]',style:{'background-color':'#7b61a8'}},{selector:'node[type_id = "knowledge_item"]',style:{'background-color':'#54a24b'}},{selector:'node[type_id = "program"]',style:{'background-color':'#9c755f'}},{selector:'node[type_id = "purpose"]',style:{'background-color':'#b279a2'}},{selector:'node[type_id = "view_filter"]',style:{'background-color':'#72b7b2'}},{selector:'node[type_id = "group"]',style:{'background-color':'#eeca3b'}},{selector:'node[type_id = "calendar_event"]',style:{'background-color':'#e15759'}},{selector:'node[type_id = "channel"]',style:{'background-color':'#59a14f'}},{selector:'edge',style:{'label':'data(label)','font-size':9,'curve-style':'bezier','target-arrow-shape':'triangle','line-color':'#9da8a0','target-arrow-color':'#9da8a0','width':1.4,'color':'#526057','text-background-color':'#fff','text-background-opacity':0.8}},{selector:'edge[rewrite_category = "WF01"]',style:{'line-color':'#5d6f2f','target-arrow-color':'#5d6f2f'}},{selector:'edge[rewrite_category = "WF02"]',style:{'line-color':'#6d5aa7','target-arrow-color':'#6d5aa7'}},{selector:'edge[rewrite_category = "WF18"]',style:{'line-color':'#2f6f9f','target-arrow-color':'#2f6f9f'}},{selector:'edge[rewrite_category = "WF19"]',style:{'line-color':'#287a72','target-arrow-color':'#287a72'}},{selector:'edge[rewrite_category = "WF21"]',style:{'line-color':'#7a4aa0','target-arrow-color':'#7a4aa0','line-style':'dashed'}},{selector:'.filtered',style:{'display':'none'}},{selector:'.dimmed',style:{'opacity':0.16}},{selector:'.matched',style:{'border-width':4,'border-color':'#202522','line-color':'#202522','target-arrow-color':'#202522','opacity':1}},{selector:':selected',style:{'border-width':4,'border-color':'#202522','line-color':'#202522','target-arrow-color':'#202522'}}]});cy.on('tap','node, edge',function(evt){lastSelected=evt.target;show(evt.target.data())});cy.on('tap',function(evt){if(evt.target===cy){lastSelected=null;showLensMeta(data)}});cy.ready(function(){applyFilters();resizeFit()});}buttons.forEach(function(btn){btn.addEventListener('click',function(){activate(Number(btn.getAttribute('data-lens'))||0)})});if(search){search.addEventListener('input',function(){applySearch(true)})}if(fit){fit.addEventListener('click',resizeFit)}if(zoomIn){zoomIn.addEventListener('click',function(){zoomBy(1.25)})}if(zoomOut){zoomOut.addEventListener('click',function(){zoomBy(.8)})}if(reset){reset.addEventListener('click',function(){if(cy){if(search)search.value='';cy.elements().removeClass('matched dimmed filtered');cy.zoom(1);cy.center();resizeFit();applyFilters()}})}if(cose){cose.addEventListener('click',function(){runLayout('cose')})}if(grid){grid.addEventListener('click',function(){runLayout('grid')})}if(circle){circle.addEventListener('click',function(){runLayout('circle')})}if(breadth){breadth.addEventListener('click',function(){runLayout('breadthfirst')})}if(concentric){concentric.addEventListener('click',function(){runLayout('concentric')})}if(agentsBtn){agentsBtn.addEventListener('click',focusAgents)}if(neighborhoodBtn){neighborhoodBtn.addEventListener('click',focusNeighborhood)}if(exportBtn){exportBtn.addEventListener('click',exportLens)}if(wide){wide.addEventListener('click',function(){setWide(true)})}if(close){close.addEventListener('click',function(){setWide(false)})}if(backdrop){backdrop.addEventListener('click',function(){setWide(false)})}document.addEventListener('keydown',function(evt){if(evt.key==='Escape'){setWide(false)}});activate(0);})();</script>""")
        println(io, "</body></html>")
    end
end

function write_markdown(path::AbstractString, plan)
    dir = dirname(path)
    !isempty(dir) && mkpath(dir)
    open(path, "w") do io
        println(io, "# mo:os Session Pipeline MVP Gate")
        println(io)
        println(io, "Generated: ", plan["generated_at"])
        println(io, "Base URL: ", plan["base_url"])
        println(io, "Overall: ", uppercase(plan["overall_status"]))
        println(io)
        println(io, "This is a dry gate report for the T189 Keep/session/visual/Calendar/recommendation projection lane. It does not emit rewrites or write to external systems.")
        println(io)
        println(io, "## Lingo")
        for key in sort(collect(keys(plan["lingo"])))
            println(io, "- ", key, ": ", plan["lingo"][key])
        end
        println(io)
        println(io, "## Gates")
        for gate in plan["gates"]
            println(io, "- [", gate["status"], "] ", gate["name"], " - ", gate["detail"])
            if !isempty(string(gate["next_action"]))
                println(io, "  Next: ", gate["next_action"])
            end
        end
        println(io)
        println(io, "## Renderer Candidates")
        for candidate in plan["renderer_candidates"]
            println(io, "- ", candidate["name"], " (", candidate["recommendation"], "): ", candidate["fit"])
        end
    end
end

function parse_args(argv)
    options = Dict(
        "base-url" => DEFAULT_BASE_URL,
        "session-pack" => DEFAULT_SESSION_PACK,
        "graph-pack" => DEFAULT_GRAPH_PACK,
        "temporal-graph-pack" => DEFAULT_TEMPORAL_GRAPH_PACK,
        "t189-graph-pack" => DEFAULT_T189_GRAPH_PACK,
        "calendar-scope-graph-pack" => DEFAULT_CALENDAR_SCOPE_GRAPH_PACK,
        "dot-path" => DEFAULT_DOT_PATH,
        "svg-path" => DEFAULT_SVG_PATH,
        "temporal-dot-path" => DEFAULT_TEMPORAL_DOT_PATH,
        "temporal-svg-path" => DEFAULT_TEMPORAL_SVG_PATH,
        "t189-dot-path" => DEFAULT_T189_DOT_PATH,
        "t189-svg-path" => DEFAULT_T189_SVG_PATH,
        "calendar-scope-dot-path" => DEFAULT_CALENDAR_SCOPE_DOT_PATH,
        "calendar-scope-svg-path" => DEFAULT_CALENDAR_SCOPE_SVG_PATH,
        "calendar-plan-path" => DEFAULT_CALENDAR_PLAN_PATH,
        "calendar-report-path" => DEFAULT_CALENDAR_REPORT_PATH,
        "calendar-write-result-path" => DEFAULT_CALENDAR_WRITE_RESULT_PATH,
        "recommendation-plan-path" => DEFAULT_RECOMMENDATION_PLAN_PATH,
        "recommendation-report-path" => DEFAULT_RECOMMENDATION_REPORT_PATH,
        "reconciliation-path" => DEFAULT_RECONCILIATION_PATH,
        "reconciliation-report-path" => DEFAULT_RECONCILIATION_REPORT_PATH,
        "atlas-path" => DEFAULT_ATLAS_PATH,
        "atlas-report-path" => DEFAULT_ATLAS_REPORT_PATH,
        "one-shot-apply-script-path" => DEFAULT_ONE_SHOT_APPLY_SCRIPT,
        "out-base" => DEFAULT_OUT_BASE,
        "html-path" => DEFAULT_HTML_PATH,
        "session-urn" => DEFAULT_SESSION_URN,
        "actor-urn" => DEFAULT_ACTOR_URN,
        "keep-channel-urn" => DEFAULT_KEEP_CHANNEL_URN,
        "keep-ki-urn" => DEFAULT_KEEP_KI_URN,
        "nodes-file" => "",
        "relations-file" => "",
        "health-file" => "",
    )
    i = 1
    while i <= length(argv)
        arg = argv[i]
        startswith(arg, "--") || error("unexpected argument: ", arg)
        key = arg[3:end]
        haskey(options, key) || error("unknown option: ", arg)
        i < length(argv) || error("missing value for ", arg)
        options[key] = argv[i + 1]
        i += 2
    end
    return options
end

function main(argv=ARGS)
    options = parse_args(argv)
    nodes = isempty(options["nodes-file"]) ? fetch_json(options["base-url"], "/state/nodes") : read_json(options["nodes-file"])
    relations = isempty(options["relations-file"]) ? fetch_json(options["base-url"], "/state/relations") : read_json(options["relations-file"])
    health = isempty(options["health-file"]) ? fetch_json(options["base-url"], "/healthz") : read_json(options["health-file"])
    session_pack = read_json(options["session-pack"])
    graph_pack = read_json(options["graph-pack"])
    temporal_graph_pack = safe_read_json(options["temporal-graph-pack"])
    t189_graph_pack = safe_read_json(options["t189-graph-pack"])
    calendar_scope_graph_pack = safe_read_json(options["calendar-scope-graph-pack"])
    plan = plan_mvp_gate(
        nodes,
        relations;
        health=health,
        session_pack=session_pack,
        graph_pack=graph_pack,
        temporal_graph_pack=temporal_graph_pack,
        t189_graph_pack=t189_graph_pack,
        calendar_scope_graph_pack=calendar_scope_graph_pack,
        session_pack_path=options["session-pack"],
        graph_pack_path=options["graph-pack"],
        temporal_graph_pack_path=options["temporal-graph-pack"],
        t189_graph_pack_path=options["t189-graph-pack"],
        calendar_scope_graph_pack_path=options["calendar-scope-graph-pack"],
        dot_path=options["dot-path"],
        svg_path=options["svg-path"],
        temporal_dot_path=options["temporal-dot-path"],
        temporal_svg_path=options["temporal-svg-path"],
        t189_dot_path=options["t189-dot-path"],
        t189_svg_path=options["t189-svg-path"],
        calendar_scope_dot_path=options["calendar-scope-dot-path"],
        calendar_scope_svg_path=options["calendar-scope-svg-path"],
        calendar_plan_path=options["calendar-plan-path"],
        calendar_report_path=options["calendar-report-path"],
        calendar_write_result_path=options["calendar-write-result-path"],
        recommendation_plan_path=options["recommendation-plan-path"],
        recommendation_report_path=options["recommendation-report-path"],
        reconciliation_path=options["reconciliation-path"],
        reconciliation_report_path=options["reconciliation-report-path"],
        atlas_path=options["atlas-path"],
        atlas_report_path=options["atlas-report-path"],
        one_shot_apply_script_path=options["one-shot-apply-script-path"],
        html_path=options["html-path"],
        session_urn=options["session-urn"],
        actor_urn=options["actor-urn"],
        keep_channel_urn=options["keep-channel-urn"],
        keep_ki_urn=options["keep-ki-urn"],
        base_url=options["base-url"],
    )
    json_path = string(options["out-base"], ".json")
    markdown_path = string(options["out-base"], ".md")
    html_path = options["html-path"]
    write_json(json_path, plan)
    write_markdown(markdown_path, plan)
    write_html(html_path, plan)
    println("Wrote MVP gate JSON: ", json_path)
    println("Wrote MVP gate Markdown: ", markdown_path)
    println("Wrote MVP dashboard HTML: ", html_path)
    println("Overall: ", plan["overall_status"], " Pass: ", plan["summary"]["pass"], " Warn: ", plan["summary"]["warn"], " Fail: ", plan["summary"]["fail"])
    return plan["overall_status"] == "fail" ? 1 : 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(SessionPipelineMVPGate.main())
end
