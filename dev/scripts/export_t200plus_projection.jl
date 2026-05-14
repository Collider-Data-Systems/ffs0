#!/usr/bin/env julia

using Dates
using Downloads
using JSON3

const RAW_PRESET = lowercase(strip(get(ENV, "MOOS_PROJECTION_PRESET", "default")))
const PRESET_ALIASES = Dict(
    "visual" => "default",
    "calendar-temporal" => "temporal-calendar",
    "google-calendar" => "calendar-scope"
)
const PRESET = get(PRESET_ALIASES, RAW_PRESET, RAW_PRESET)
const PRESETS = Dict(
    "default" => Dict(
        "MOOS_PROJECTION_LABEL" => "T200+ Tiny Data Collider folded-state projection",
        "MOOS_PROJECTION_ROOT" => "urn:moos:program:sam.t200plus.tiny-data-collider-federation",
        "MOOS_PROJECTION_OUT" => "tmp/projections/t200plus_visual_projection",
        "MOOS_PROJECTION_RADIUS" => "2",
        "MOOS_PROJECTION_WFS" => "WF18,WF21",
        "MOOS_PROJECTION_TYPES" => "",
        "MOOS_PROJECTION_PORTS" => "",
        "MOOS_PROJECTION_MATCH" => "",
        "MOOS_PROJECTION_INCLUDE_OWNERS" => "true",
        "MOOS_PROJECTION_INCLUDE_VISUAL_LENS" => "true"
    ),
    "temporal-calendar" => Dict(
        "MOOS_PROJECTION_LABEL" => "T200+ temporal/calendar folded-state projection",
        "MOOS_PROJECTION_ROOT" => "urn:moos:program:sam.t200plus.temporal-projection-fabric",
        "MOOS_PROJECTION_OUT" => "tmp/projections/t200plus_temporal_calendar",
        "MOOS_PROJECTION_RADIUS" => "2",
        "MOOS_PROJECTION_WFS" => "WF18,WF21",
        "MOOS_PROJECTION_TYPES" => "calendar_event,channel,clock,derivation,program,purpose,view_filter",
        "MOOS_PROJECTION_PORTS" => "composes,composed-by,causes,caused-by",
        "MOOS_PROJECTION_MATCH" => "calendar|T200|temporal|time|clock|t-local|purpose",
        "MOOS_PROJECTION_INCLUDE_OWNERS" => "true",
        "MOOS_PROJECTION_INCLUDE_VISUAL_LENS" => "true"
    ),
    "calendar-scope" => Dict(
        "MOOS_PROJECTION_LABEL" => "Google Calendar F/G scope and reliability lens",
        "MOOS_PROJECTION_ROOT" => "urn:moos:program:sam.t200plus.temporal-projection-fabric",
        "MOOS_PROJECTION_ROOTS" => "urn:moos:session:sam.governance;urn:moos:channel:google.calendar.sam;urn:moos:program:sam.t200plus.temporal-projection-fabric;urn:moos:program:sam.t200plus.google-calendar-projection-contract;urn:moos:program:sam.t200plus.google-calendar-projection-planner;urn:moos:program:sam.t200plus.google-calendar-oauth-writer;urn:moos:derivation:guido.t200plus-google-calendar-write-result;urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision;urn:moos:program:sam.t189.calendar-event-g-ingest-shape;urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence;urn:moos:view_filter:sam.t189-time-fabric-session-lens",
        "MOOS_PROJECTION_OUT" => "tmp/projections/session_pipeline/visual/calendar_scope_frame",
        "MOOS_PROJECTION_RADIUS" => "3",
        "MOOS_PROJECTION_WFS" => "WF01,WF07,WF18,WF19,WF21",
        "MOOS_PROJECTION_TYPES" => "calendar_event,channel,claim,clock,derivation,external_op,group,knowledge_item,program,purpose,session,tool_call,view_filter",
        "MOOS_PROJECTION_PORTS" => "",
        "MOOS_PROJECTION_MATCH" => "calendar|temporal|time|clock|t189|t200|google|governance|session|event|projection|writer|oauth|time-fabric|surface|recommendation|convergence",
        "MOOS_PROJECTION_INCLUDE_OWNERS" => "true",
        "MOOS_PROJECTION_INCLUDE_VISUAL_LENS" => "false"
    ),
    "session-occasion" => Dict(
        "MOOS_PROJECTION_LABEL" => "T187 session-occasion implementation frame",
        "MOOS_PROJECTION_ROOT" => "urn:moos:derivation:guido.t187-session-occasion-implementation-frame",
        "MOOS_PROJECTION_ROOTS" => "urn:moos:derivation:guido.t187-session-occasion-implementation-frame;urn:moos:system_instruction:framework.session-occasion-lingo;urn:moos:grammar_fragment:v317-1-occasion-type;urn:moos:pattern:session-affordance-pack;urn:moos:workflow:z440-session-continuity-reconciliation",
        "MOOS_PROJECTION_OUT" => "tmp/projections/session_pipeline/visual/session_occasion_frame",
        "MOOS_PROJECTION_RADIUS" => "2",
        "MOOS_PROJECTION_WFS" => "WF12,WF18,WF20,WF21",
        "MOOS_PROJECTION_TYPES" => "claim,derivation,grammar_fragment,knowledge_item,pattern,program,purpose,session,system_instruction,workflow",
        "MOOS_PROJECTION_PORTS" => "causes,caused-by,composes,composed-by,consumes,consumed-by,produces,produced-by,provides-kb,provided-by,grammar-promotes,grammar-promoted-by",
        "MOOS_PROJECTION_MATCH" => "session|occasion|affordance|keep|purpose|program|workflow|grammar|z440",
        "MOOS_PROJECTION_INCLUDE_OWNERS" => "true",
        "MOOS_PROJECTION_INCLUDE_VISUAL_LENS" => "false"
    ),
    "t189-recommendations" => Dict(
        "MOOS_PROJECTION_LABEL" => "T189 recommendation grouped apply lens",
        "MOOS_PROJECTION_ROOT" => "urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence",
        "MOOS_PROJECTION_ROOTS" => "urn:moos:session:sam.governance;urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence;urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision;urn:moos:view_filter:sam.t189-time-fabric-session-lens;urn:moos:group:my-tiny-data-collider",
        "MOOS_PROJECTION_OUT" => "tmp/projections/session_pipeline/visual/t189_recommendation_frame",
        "MOOS_PROJECTION_RADIUS" => "2",
        "MOOS_PROJECTION_WFS" => "WF01,WF18,WF19,WF21",
        "MOOS_PROJECTION_TYPES" => "calendar_event,derivation,group,program,purpose,session,view_filter",
        "MOOS_PROJECTION_PORTS" => "causes,caused-by,composes,composed-by,filtered-by,filters-session,owns,owned-by,pinned-by-session,pins-urn",
        "MOOS_PROJECTION_MATCH" => "t189|t200|calendar|github|cytoscape|my-tiny-data-collider|convergence|governance|application",
        "MOOS_PROJECTION_INCLUDE_OWNERS" => "true",
        "MOOS_PROJECTION_INCLUDE_VISUAL_LENS" => "false"
    )
)

if !haskey(PRESETS, PRESET)
    error("Unknown MOOS_PROJECTION_PRESET=", RAW_PRESET, ". Available presets: ", join(sort(collect(keys(PRESETS))), ", "))
end

const PRESET_VALUES = PRESETS[PRESET]

function preset_value(name::AbstractString, default::AbstractString = "")
    return get(PRESET_VALUES, name, default)
end

function env_set(name::AbstractString, default::AbstractString = "")
    raw = get(ENV, name, preset_value(name, default))
    items = String[]
    for part in split(raw, ',')
        item = strip(part)
        if !isempty(item)
            push!(items, String(item))
        end
    end
    return Set(items)
end

function env_bool(name::AbstractString, default::Bool)
    raw = lowercase(strip(get(ENV, name, preset_value(name, default ? "true" : "false"))))
    return raw in Set(["1", "true", "yes", "y", "on"])
end

const BASE_URL = get(ENV, "MOOS_BASE_URL", "http://localhost:8000")
const ROOT_URN = get(ENV, "MOOS_PROJECTION_ROOT", preset_value("MOOS_PROJECTION_ROOT"))
const ROOT_URNS_RAW = get(ENV, "MOOS_PROJECTION_ROOTS", preset_value("MOOS_PROJECTION_ROOTS", ROOT_URN))
const OUT_BASE = get(ENV, "MOOS_PROJECTION_OUT", preset_value("MOOS_PROJECTION_OUT"))
const RADIUS = parse(Int, get(ENV, "MOOS_PROJECTION_RADIUS", preset_value("MOOS_PROJECTION_RADIUS", "2")))
const WF_FILTER = env_set("MOOS_PROJECTION_WFS", "WF18,WF21")
const TYPE_FILTER = env_set("MOOS_PROJECTION_TYPES")
const PORT_FILTER = env_set("MOOS_PROJECTION_PORTS")
const MATCH_PATTERN = strip(get(ENV, "MOOS_PROJECTION_MATCH", preset_value("MOOS_PROJECTION_MATCH")))
const MATCH_REGEX = isempty(MATCH_PATTERN) ? nothing : Regex(MATCH_PATTERN, "i")
const CONTEXT_AGENT_URNS_RAW = strip(get(ENV, "MOOS_PROJECTION_CONTEXT_AGENT_URNS", ""))
const INCLUDE_OWNERS = env_bool("MOOS_PROJECTION_INCLUDE_OWNERS", true)
const INCLUDE_VISUAL_LENS = env_bool("MOOS_PROJECTION_INCLUDE_VISUAL_LENS", true)
const PROJECTION_LABEL = get(ENV, "MOOS_PROJECTION_LABEL", preset_value("MOOS_PROJECTION_LABEL", "mo:os folded-state projection"))
const VISUAL_LENS_URN = "urn:moos:program:sam.t200plus.visual-projection-lens"
const VIEW_FILTER_URN = "urn:moos:view_filter:sam.t200plus-visual-projection-lens"

function root_urns()
    roots = Set{String}()
    for part in split(ROOT_URNS_RAW, ';')
        item = strip(part)
        !isempty(item) && push!(roots, String(item))
    end
    isempty(roots) && !isempty(ROOT_URN) && push!(roots, ROOT_URN)
    return roots
end

function context_agent_urns()
    agents = Set{String}()
    for part in split(CONTEXT_AGENT_URNS_RAW, ';')
        item = strip(part)
        !isempty(item) && push!(agents, String(item))
    end
    return agents
end

function fetch_json(path::AbstractString)
    url = string(rstrip(BASE_URL, '/'), path)
    temp_path = Downloads.download(url)
    try
        return JSON3.read(read(temp_path, String))
    finally
        rm(temp_path; force = true)
    end
end

function hasprop(obj, name::Symbol)
    return haskey(obj, name)
end

function prop_value(node, names::AbstractVector{Symbol}; default = "")
    if !hasprop(node, :properties)
        return default
    end
    props = node.properties
    for name in names
        if haskey(props, name)
            record = props[name]
            if haskey(record, :value) && record.value !== nothing
                return string(record.value)
            end
        end
    end
    return default
end

function short_urn(urn::AbstractString)
    parts = split(urn, ':')
    tail = isempty(parts) ? urn : parts[end]
    return replace(tail, "." => "\n")
end

function node_label(node)
    urn = string(node.urn)
    primary = prop_value(node, [:title, :name, :display_name, :summary]; default = short_urn(urn))
    return string(primary, "\n", node.type_id)
end

function dot_escape(value::AbstractString)
    value = replace(value, "\\" => "\\\\")
    value = replace(value, "\"" => "\\\"")
    return replace(value, "\n" => "\\n")
end

function node_style(type_id::AbstractString, urn::AbstractString)
    palette = Dict(
        "program" => ("#d8ecff", "#2f6f9f"),
        "purpose" => ("#fff2b8", "#9a7a00"),
        "derivation" => ("#eadcff", "#6f4ca3"),
        "channel" => ("#ddf7df", "#3e8c46"),
        "calendar_event" => ("#ffe8ef", "#a7355d"),
        "clock" => ("#e1f4f2", "#287a72"),
        "repository" => ("#f0eadf", "#7b6650"),
        "agent" => ("#dce8ff", "#4267a5"),
        "group" => ("#fff5cf", "#8f7b22"),
        "user" => ("#eeeeee", "#666666"),
        "view_filter" => ("#ffe3c2", "#b86b14")
    )
    fill, stroke = get(palette, type_id, ("#f8f8f8", "#777777"))
    style = urn == VIEW_FILTER_URN ? "filled,dashed" : "filled"
    return fill, stroke, style
end

function edge_style(category::AbstractString)
    if category == "WF18"
        return "#2f6f9f", "solid"
    elseif category == "WF21"
        return "#7a4aa0", "dashed"
    elseif category == "WF01"
        return "#666666", "dotted"
    elseif category == "WF19"
        return "#287a72", "solid"
    end
    return "#999999", "solid"
end

function wf_allowed(category::AbstractString)
    return "*" in WF_FILTER || category in WF_FILTER
end

function port_allowed(rel)
    if isempty(PORT_FILTER)
        return true
    end
    return string(rel.src_port) in PORT_FILTER || string(rel.tgt_port) in PORT_FILTER
end

function relation_allowed(rel)
    category = string(rel.rewrite_category)
    if INCLUDE_OWNERS && category == "WF01"
        return true
    end
    return wf_allowed(category) && port_allowed(rel)
end

function node_allowed(node, urn::AbstractString)
    type_ok = isempty(TYPE_FILTER) || string(node.type_id) in TYPE_FILTER
    match_ok = MATCH_REGEX === nothing || occursin(MATCH_REGEX, urn) || occursin(MATCH_REGEX, node_label(node))
    return type_ok && match_ok
end

function filter_summary()
    parts = [
        string("preset=", PRESET),
        string("root=", ROOT_URN),
        string("radius=", RADIUS),
        string("wfs=", isempty(WF_FILTER) ? "<none>" : join(sort(collect(WF_FILTER)), ",")),
        string("types=", isempty(TYPE_FILTER) ? "*" : join(sort(collect(TYPE_FILTER)), ",")),
        string("ports=", isempty(PORT_FILTER) ? "*" : join(sort(collect(PORT_FILTER)), ",")),
        string("match=", isempty(MATCH_PATTERN) ? "*" : MATCH_PATTERN),
        string("context_agents=", isempty(CONTEXT_AGENT_URNS_RAW) ? "<none>" : CONTEXT_AGENT_URNS_RAW),
        string("owners=", INCLUDE_OWNERS),
        "agent-neighborhood=true"
    ]
    return join(parts, "\n")
end

nodes = fetch_json("/state/nodes")
relations = fetch_json("/state/relations")

nodes_by_urn = Dict{String, Any}()
for node in nodes
    nodes_by_urn[string(node.urn)] = node
end

forced_urns = root_urns()
if INCLUDE_VISUAL_LENS
    push!(forced_urns, VISUAL_LENS_URN)
    push!(forced_urns, VIEW_FILTER_URN)
end

selected = copy(forced_urns)
for _ in 1:RADIUS
    global selected
    next_selected = copy(selected)
    for rel in relations
        category = string(rel.rewrite_category)
        if !wf_allowed(category) || !port_allowed(rel)
            continue
        end
        src = string(rel.src_urn)
        tgt = string(rel.tgt_urn)
        if src in selected || tgt in selected
            push!(next_selected, src)
            push!(next_selected, tgt)
        end
    end
    if length(next_selected) == length(selected)
        break
    end
    selected = next_selected
end

function endpoint_type(urn::AbstractString)
    haskey(nodes_by_urn, urn) || return ""
    return string(nodes_by_urn[urn].type_id)
end

const AGENT_CONTEXT_TYPES = Set(["session", "program"])
const AGENT_CONTEXT_RELATION_CATEGORIES = Set(["WF01", "WF02", "WF19"])
const AGENT_CONTEXT_PRINCIPAL_TYPES = Set(["agent", "group", "role", "user"])

function is_session_program_agent_relation(rel, selected_urns)
    src = string(rel.src_urn)
    tgt = string(rel.tgt_urn)
    src_type = endpoint_type(src)
    tgt_type = endpoint_type(tgt)
    src_context = src in selected_urns && src_type in AGENT_CONTEXT_TYPES
    tgt_context = tgt in selected_urns && tgt_type in AGENT_CONTEXT_TYPES
    return (src_context && tgt_type == "agent") || (tgt_context && src_type == "agent")
end

agent_context_urns = Set{String}()
agent_urns = Set{String}()
agent_relation_urns = Set{String}()
function add_agent_context!(rel)
    src = string(rel.src_urn)
    tgt = string(rel.tgt_urn)
    src_type = endpoint_type(src)
    tgt_type = endpoint_type(tgt)
    push!(agent_context_urns, src)
    push!(agent_context_urns, tgt)
    src_type == "agent" && push!(agent_urns, src)
    tgt_type == "agent" && push!(agent_urns, tgt)
    push!(agent_relation_urns, string(rel.urn))
end

for agent in context_agent_urns()
    if endpoint_type(agent) == "agent"
        push!(agent_urns, agent)
        push!(agent_context_urns, agent)
    end
end

for rel in relations
    if is_session_program_agent_relation(rel, selected)
        add_agent_context!(rel)
    end
end

for rel in relations
    category = string(rel.rewrite_category)
    category in AGENT_CONTEXT_RELATION_CATEGORIES || continue
    src = string(rel.src_urn)
    tgt = string(rel.tgt_urn)
    src_type = endpoint_type(src)
    tgt_type = endpoint_type(tgt)
    touches_agent = src in agent_urns || tgt in agent_urns
    owns_selected_context = category == "WF01" && ((src_type in AGENT_CONTEXT_PRINCIPAL_TYPES && tgt in selected && tgt_type in AGENT_CONTEXT_TYPES) || (tgt_type in AGENT_CONTEXT_PRINCIPAL_TYPES && src in selected && src_type in AGENT_CONTEXT_TYPES))
    if touches_agent || owns_selected_context
        add_agent_context!(rel)
    end
end

union!(selected, agent_context_urns)

if INCLUDE_VISUAL_LENS && haskey(nodes_by_urn, VIEW_FILTER_URN)
    push!(selected, VIEW_FILTER_URN)
end

if INCLUDE_OWNERS
    for rel in relations
        category = string(rel.rewrite_category)
        src = string(rel.src_urn)
        tgt = string(rel.tgt_urn)
        if category == "WF01" && tgt in selected
            push!(selected, src)
        end
    end
end

filtered_selected = Set{String}()
for urn in selected
    if !haskey(nodes_by_urn, urn)
        continue
    end
    if urn in forced_urns || urn in agent_context_urns || node_allowed(nodes_by_urn[urn], urn)
        push!(filtered_selected, urn)
    end
end
selected = filtered_selected

selected_relations = Any[]
for rel in relations
    src = string(rel.src_urn)
    tgt = string(rel.tgt_urn)
    if (relation_allowed(rel) || string(rel.urn) in agent_relation_urns) && src in selected && tgt in selected
        push!(selected_relations, rel)
    end
end

mkpath(dirname(OUT_BASE))
dot_path = string(OUT_BASE, ".dot")
svg_path = string(OUT_BASE, ".svg")

open(dot_path, "w") do io
    println(io, "digraph t200plus_projection {")
    graph_label = string(PROJECTION_LABEL, "\\n", filter_summary())
    println(io, "  graph [rankdir=LR, bgcolor=\"#ffffff\", pad=0.3, nodesep=0.45, ranksep=0.75, labelloc=\"t\", label=\"", dot_escape(graph_label), "\"];" )
    println(io, "  node [shape=box, style=filled, fontname=\"Segoe UI\", fontsize=10, margin=0.08];")
    println(io, "  edge [fontname=\"Segoe UI\", fontsize=8, arrowsize=0.7];")
    println(io)
    for urn in sort(collect(selected))
        if !haskey(nodes_by_urn, urn)
            continue
        end
        node = nodes_by_urn[urn]
        fill, stroke, style = node_style(string(node.type_id), urn)
        label = dot_escape(node_label(node))
        tooltip = dot_escape(urn)
        println(io, "  \"", dot_escape(urn), "\" [label=\"", label, "\", tooltip=\"", tooltip, "\", fillcolor=\"", fill, "\", color=\"", stroke, "\", style=\"", style, "\"];" )
    end
    println(io)
    for rel in selected_relations
        category = string(rel.rewrite_category)
        color, style = edge_style(category)
        src = string(rel.src_urn)
        tgt = string(rel.tgt_urn)
        label = string(category, " ", rel.src_port, " -> ", rel.tgt_port)
        tooltip = dot_escape(string(rel.urn))
        println(io, "  \"", dot_escape(src), "\" -> \"", dot_escape(tgt), "\" [label=\"", dot_escape(label), "\", tooltip=\"", tooltip, "\", color=\"", color, "\", fontcolor=\"", color, "\", style=\"", style, "\"];" )
    end
    println(io)
    if INCLUDE_VISUAL_LENS && VIEW_FILTER_URN in selected
        println(io, "  \"", dot_escape(VIEW_FILTER_URN), "\" [xlabel=\"declared lens; session-scoped view filter\"];" )
    end
    println(io, "}")
end

function graphviz_dot()
    path = Sys.which("dot")
    if path !== nothing
        return path
    end
    candidates = [
        raw"C:\Program Files\Graphviz\bin\dot.exe",
        raw"C:\Program Files (x86)\Graphviz\bin\dot.exe"
    ]
    for candidate in candidates
        if isfile(candidate)
            return candidate
        end
    end
    return nothing
end

dot_bin = graphviz_dot()
if dot_bin === nothing
    println("Wrote DOT: ", dot_path)
    println("Graphviz dot was not found on PATH or standard Windows install paths; SVG not generated.")
else
    run(`$dot_bin -Tsvg -o $svg_path $dot_path`)
    println("Wrote DOT: ", dot_path)
    println("Wrote SVG: ", svg_path)
end
println("Nodes: ", length(selected), " Relations: ", length(selected_relations), " Generated at: ", Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
println("Filters: ", filter_summary())