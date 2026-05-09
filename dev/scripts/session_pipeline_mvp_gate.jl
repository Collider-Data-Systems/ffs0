#!/usr/bin/env julia

module SessionPipelineMVPGate

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_SESSION_PACK = "tmp/projections/session_pipeline/session_context/current_session.json"
const DEFAULT_GRAPH_PACK = "tmp/projections/session_pipeline/graph_artifacts/session_occasion_engineering.json"
const DEFAULT_DOT_PATH = "tmp/projections/session_pipeline/visual/session_occasion_frame.dot"
const DEFAULT_SVG_PATH = "tmp/projections/session_pipeline/visual/session_occasion_frame.svg"
const DEFAULT_TEMPORAL_DOT_PATH = "tmp/projections/session_pipeline/visual/temporal_calendar_frame.dot"
const DEFAULT_TEMPORAL_SVG_PATH = "tmp/projections/session_pipeline/visual/temporal_calendar_frame.svg"
const DEFAULT_CALENDAR_PLAN_PATH = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json"
const DEFAULT_CALENDAR_REPORT_PATH = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.md"
const DEFAULT_CALENDAR_WRITE_RESULT_PATH = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_write_result.json"
const DEFAULT_RECOMMENDATION_PLAN_PATH = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json"
const DEFAULT_RECOMMENDATION_REPORT_PATH = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.md"
const DEFAULT_OUT_BASE = "tmp/projections/session_pipeline/mvp/session_pipeline_gate"
const DEFAULT_HTML_PATH = "tmp/projections/session_pipeline/index.html"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:claude-code.hp-laptop"
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
        "gate_names" => ["F session handoff header", "session occasion topology", "session purpose color", "F affordance pack"],
    ),
    Dict(
        "id" => "f-visual",
        "name" => "F visual lens",
        "short_name" => "F/visual",
        "description" => "The selected graph lenses become engineering summaries, static visual artifacts, Calendar payloads, and recommendation HG plans while keeping disconnected roots visible.",
        "gate_names" => ["F graph artifact analysis", "visual lens root coverage", "static visual output", "Calendar time-fabric artifacts", "T189/T200 recommendation artifacts", "lens flexibility controls"],
    ),
    Dict(
        "id" => "operator-interface",
        "name" => "Operator interface",
        "short_name" => "UI",
        "description" => "The MVP is readable as a control surface: status, lineage, checks, artifacts, and next gates are visible in one place.",
        "gate_names" => ["interactive visual aid"],
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
        "application" => "Keep the static Graphviz artifact for review, but shape the next renderer around typed node data, style selectors, selection events, and an inspector panel.",
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
]

const LINGO = Dict(
    "G_ingest" => "External source -> HG evidence. For this lane: Google Keep export/manual download -> channel + knowledge_item + claim/derivation topology.",
    "F_projection" => "HG folded state -> external/session artifact. For this lane: session context pack, graph engineering report, DOT/SVG visual aid.",
    "Calendar_projection" => "HG graph artifact -> Google Calendar payloads. Calendar is a visible projection surface; the graph remains source of truth.",
    "Recommendation_projection" => "Approved T189 recommendations -> dry candidate HG nodes/relations. This is a plan surface, not an APPLY batch.",
    "lens" => "A typed view functor: roots + radius + WF/port/type/predicate filters + authority/session context -> selected subgraph.",
    "scope" => "The domain of a lens: explicit roots plus reachable topology under chosen relation families. Session pins and view_filter nodes are durable scope carriers.",
    "visual_aid" => "A renderer of a lens result, not a truth source. DOT/SVG is the current static renderer; Cytoscape.js is the likely next interactive renderer.",
    "mvp_gate" => "A generated check that the G input, F outputs, session header, and visual lens artifacts exist and expose known gaps instead of hiding them.",
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

function plan_mvp_gate(nodes, relations; health=Dict(), session_pack=Dict(), graph_pack=Dict(), session_pack_path=DEFAULT_SESSION_PACK, graph_pack_path=DEFAULT_GRAPH_PACK, dot_path=DEFAULT_DOT_PATH, svg_path=DEFAULT_SVG_PATH, temporal_dot_path=DEFAULT_TEMPORAL_DOT_PATH, temporal_svg_path=DEFAULT_TEMPORAL_SVG_PATH, calendar_plan_path=DEFAULT_CALENDAR_PLAN_PATH, calendar_report_path=DEFAULT_CALENDAR_REPORT_PATH, calendar_write_result_path=DEFAULT_CALENDAR_WRITE_RESULT_PATH, recommendation_plan_path=DEFAULT_RECOMMENDATION_PLAN_PATH, recommendation_report_path=DEFAULT_RECOMMENDATION_REPORT_PATH, html_path=DEFAULT_HTML_PATH, session_urn=DEFAULT_SESSION_URN, actor_urn=DEFAULT_ACTOR_URN, keep_channel_urn=DEFAULT_KEEP_CHANNEL_URN, keep_ki_urn=DEFAULT_KEEP_KI_URN, base_url=DEFAULT_BASE_URL, generated_at=format_utc(now(UTC)))
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
    push!(gates, gate(
        dot_exists && svg_exists && temporal_dot_exists && temporal_svg_exists ? "pass" : "warn",
        "static visual output",
        dot_exists && svg_exists && temporal_dot_exists && temporal_svg_exists ? "Session-occasion and temporal/calendar DOT/SVG visual artifacts exist." : "One or more static visual artifacts are missing.",
        evidence=Dict("dot_path" => dot_path, "dot_exists" => dot_exists, "svg_path" => svg_path, "svg_exists" => svg_exists, "temporal_dot_path" => temporal_dot_path, "temporal_dot_exists" => temporal_dot_exists, "temporal_svg_path" => temporal_svg_path, "temporal_svg_exists" => temporal_svg_exists),
        next_action=dot_exists && svg_exists && temporal_dot_exists && temporal_svg_exists ? "" : "Run export_t200plus_projection.jl for both session-occasion and temporal-calendar presets; install Graphviz if SVG is missing.",
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

    filters = object_value(graph_pack, :filters, Dict())
    has_lens_controls = length(object_value(graph_pack, :root_urns, Any[])) > 0 && haskey(filters, :wfs) && haskey(filters, :ports) && haskey(filters, :types)
    push!(gates, gate(
        has_lens_controls ? "pass" : "warn",
        "lens flexibility controls",
        has_lens_controls ? "The graph projection records roots plus WF, port, type, and match filters." : "The graph projection does not expose enough lens controls for flexible scope inspection.",
        evidence=Dict("root_count" => length(object_value(graph_pack, :root_urns, Any[])), "filters" => filters),
        next_action=has_lens_controls ? "" : "Promote the lens spec to a shared JSON or view_filter-backed adapter.",
    ))

    push!(gates, gate(
        "warn",
        "interactive visual aid",
        "The MVP has deterministic DOT/SVG, but not yet an interactive browser/IDE graph surface.",
        evidence=Dict("recommended_next_renderer" => "Cytoscape.js", "context7_candidates_checked" => [candidate["name"] for candidate in RENDERER_CANDIDATES]),
        next_action="Keep Graphviz as the static review artifact; prototype Cytoscape.js when node selection, filtering, and inspector panels become the bottleneck.",
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
            "dot" => dot_path,
            "svg" => svg_path,
            "temporal_calendar_dot" => temporal_dot_path,
            "temporal_calendar_svg" => temporal_svg_path,
            "calendar_time_fabric_plan" => calendar_plan_path,
            "calendar_time_fabric_report" => calendar_report_path,
            "calendar_time_fabric_write_result" => calendar_write_result_path,
            "recommendation_hg_plan" => recommendation_plan_path,
            "recommendation_hg_report" => recommendation_report_path,
            "dashboard" => html_path,
        ),
        "pipeline_stages" => stages,
        "interface_principles" => INTERFACE_PRINCIPLES,
        "renderer_candidates" => RENDERER_CANDIDATES,
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
    open(path, "w") do io
        println(io, "<!doctype html>")
        println(io, "<html lang=\"en\">")
        println(io, "<head>")
        println(io, "<meta charset=\"utf-8\">")
        println(io, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
        println(io, "<title>mo:os Session Pipeline MVP</title>")
        println(io, "<style>")
        println(io, "html{font-family:Inter,Segoe UI,Arial,sans-serif;background:#f7f7f2;color:#202522}body{margin:0}.shell{max-width:1180px;margin:0 auto;padding:24px}.top{display:grid;grid-template-columns:minmax(0,1.7fr) minmax(260px,.8fr);gap:16px;align-items:stretch}.panel,.stage,.gate,.artifact,.principle{background:#fff;border:1px solid #d9ded7;border-radius:8px;box-shadow:0 1px 2px rgba(20,30,25,.05)}.panel{padding:18px}h1{font-size:28px;line-height:1.15;margin:0 0 8px}h2{font-size:16px;margin:0 0 12px}p{line-height:1.45}.muted{color:#5f6b62}.status{display:inline-flex;align-items:center;border-radius:999px;padding:3px 9px;font-size:12px;font-weight:700;text-transform:uppercase}.pass{background:#dff4df;color:#195d25}.warn{background:#fff0bd;color:#735600}.fail{background:#ffd8d3;color:#8a1f16}.summary{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:12px}.metric{border:1px solid #e3e6e0;border-radius:8px;padding:10px;background:#fafbf8}.metric strong{display:block;font-size:24px}.stageGrid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin:16px 0}.stage{padding:14px;min-height:138px}.stageHead{display:flex;justify-content:space-between;gap:8px;align-items:center;margin-bottom:8px}.stageName{font-weight:800}.stageDesc{font-size:13px;color:#46524a}.gateToolbar{display:flex;flex-wrap:wrap;gap:8px;margin:10px 0 12px}.gateToolbar button,.linkButton{border:1px solid #ccd3cb;background:#fff;border-radius:6px;padding:7px 10px;cursor:pointer;color:#24362e;text-decoration:none;display:inline-flex;align-items:center;gap:6px}.gateToolbar button.active{background:#24362e;color:#fff;border-color:#24362e}.gateList{display:grid;gap:8px}.gate{padding:12px}.gateTop{display:flex;align-items:center;justify-content:space-between;gap:12px}.gateName{font-weight:750}.evidence{font-size:12px;color:#526057;margin-top:8px;word-break:break-word}.next{border-left:3px solid #c68a00;background:#fff8df;padding:8px;margin-top:8px;border-radius:4px}.cols{display:grid;grid-template-columns:1fr 1fr;gap:16px}.artifactList,.principleList{display:grid;gap:8px}.artifact,.principle{padding:12px}.artifact a{color:#245c84;text-decoration:none;word-break:break-word}.artifact a:hover,.linkButton:hover{text-decoration:underline}.visualBox{border:1px solid #d9ded7;border-radius:8px;background:#fff;min-height:360px;overflow:auto}.visualBox object{width:100%;min-width:1080px;height:680px;display:block}.visualActions{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 12px}.actions{display:grid;gap:8px}.action{border-left:4px solid #c68a00;background:#fff8df;border-radius:6px;padding:10px}.foot{margin-top:22px;font-size:12px;color:#667168}@media(max-width:900px){.top,.cols,.stageGrid{grid-template-columns:1fr}.shell{padding:16px}.visualBox object{height:560px}}")
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
        println(io, "<div class=\"panel\"><h2>Artifacts</h2><div class=\"artifactList\">")
        for key in sort(collect(keys(artifacts)); by=string)
            artifact_path = string(artifacts[key])
            println(io, "<div class=\"artifact\"><strong>", html_escape(key), "</strong><br><a href=\"", html_escape(artifact_link(path, artifact_path)), "\">", html_escape(artifact_path), "</a></div>")
        end
        println(io, "</div></div>")
        println(io, "</section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>Visual Lens</h2>")
        if !isempty(svg_path) && isfile(svg_path)
            println(io, "<div class=\"visualActions\"><a class=\"linkButton\" href=\"", html_escape(svg_href), "\">Open SVG</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :dot, "")))), "\">Open DOT</a></div>")
            println(io, "<div class=\"visualBox\"><object type=\"image/svg+xml\" data=\"", html_escape(svg_href), "\"></object></div>")
        else
            println(io, "<p class=\"muted\">Static SVG is not present yet. Run the session-occasion visual projection before using the visual lens panel.</p>")
        end
        println(io, "</section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>Calendar Time-Fabric</h2>")
        println(io, "<div class=\"visualActions\"><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_plan, "")))), "\">Open Calendar Plan</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_report, "")))), "\">Open Calendar Report</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :calendar_time_fabric_write_result, "")))), "\">Open Write Result</a><a class=\"linkButton\" href=\"", html_escape(temporal_svg_href), "\">Open Temporal SVG</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :temporal_calendar_dot, "")))), "\">Open Temporal DOT</a></div>")
        if !isempty(temporal_svg_path) && isfile(temporal_svg_path)
            println(io, "<div class=\"visualBox\"><object type=\"image/svg+xml\" data=\"", html_escape(temporal_svg_href), "\"></object></div>")
        else
            println(io, "<p class=\"muted\">Temporal/calendar SVG is not present yet. Run the temporal-calendar visual projection before using this panel.</p>")
        end
        println(io, "</section>")
        println(io, "<section class=\"panel\" style=\"margin-top:16px\"><h2>HG Recommendations</h2>")
        println(io, "<div class=\"visualActions\"><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_hg_plan, "")))), "\">Open Recommendation Plan</a><a class=\"linkButton\" href=\"", html_escape(artifact_link(path, string(object_value(artifacts, :recommendation_hg_report, "")))), "\">Open Recommendation Report</a></div>")
        println(io, "<p class=\"muted\">Dry candidate nodes and relations for the five T189 recommendations plus the T200+ convergence arc. This panel is a projection surface; it does not apply rewrites.</p>")
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
        println(io, "<p class=\"foot\">Generated from session_pipeline_mvp_gate.jl. This page is an artifact of the projection lane; it does not emit rewrites.</p>")
        println(io, "</main>")
        println(io, "<script>document.querySelectorAll('[data-filter]').forEach(function(btn){btn.addEventListener('click',function(){document.querySelectorAll('[data-filter]').forEach(function(b){b.classList.remove('active')});btn.classList.add('active');var f=btn.getAttribute('data-filter');document.querySelectorAll('.gate').forEach(function(g){g.style.display=(f==='all'||g.getAttribute('data-status')===f)?'block':'none'});});});</script>")
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
        println(io, "This is a dry gate report for the T188 Keep-note/session/visual-projection lane. It does not emit rewrites or write to external systems.")
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
        "dot-path" => DEFAULT_DOT_PATH,
        "svg-path" => DEFAULT_SVG_PATH,
        "temporal-dot-path" => DEFAULT_TEMPORAL_DOT_PATH,
        "temporal-svg-path" => DEFAULT_TEMPORAL_SVG_PATH,
        "calendar-plan-path" => DEFAULT_CALENDAR_PLAN_PATH,
        "calendar-report-path" => DEFAULT_CALENDAR_REPORT_PATH,
        "calendar-write-result-path" => DEFAULT_CALENDAR_WRITE_RESULT_PATH,
        "recommendation-plan-path" => DEFAULT_RECOMMENDATION_PLAN_PATH,
        "recommendation-report-path" => DEFAULT_RECOMMENDATION_REPORT_PATH,
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
    plan = plan_mvp_gate(
        nodes,
        relations;
        health=health,
        session_pack=session_pack,
        graph_pack=graph_pack,
        session_pack_path=options["session-pack"],
        graph_pack_path=options["graph-pack"],
        dot_path=options["dot-path"],
        svg_path=options["svg-path"],
        temporal_dot_path=options["temporal-dot-path"],
        temporal_svg_path=options["temporal-svg-path"],
        calendar_plan_path=options["calendar-plan-path"],
        calendar_report_path=options["calendar-report-path"],
        calendar_write_result_path=options["calendar-write-result-path"],
        recommendation_plan_path=options["recommendation-plan-path"],
        recommendation_report_path=options["recommendation-report-path"],
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
