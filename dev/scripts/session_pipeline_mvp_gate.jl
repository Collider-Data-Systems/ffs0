#!/usr/bin/env julia

module SessionPipelineMVPGate

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_SESSION_PACK = "tmp/projections/session_context/current_session.json"
const DEFAULT_GRAPH_PACK = "tmp/projections/graph_artifacts/session_occasion_engineering.json"
const DEFAULT_DOT_PATH = "tmp/projections/session_occasion_frame.dot"
const DEFAULT_SVG_PATH = "tmp/projections/session_occasion_frame.svg"
const DEFAULT_OUT_BASE = "tmp/projections/mvp/session_pipeline_gate"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:claude-code.hp-laptop"
const DEFAULT_KEEP_CHANNEL_URN = "urn:moos:channel:google.keep.sam"
const DEFAULT_KEEP_KI_URN = "urn:moos:ki:gdrive.t187-keep-session-occasion-lingo"

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

function plan_mvp_gate(nodes, relations; health=Dict(), session_pack=Dict(), graph_pack=Dict(), session_pack_path=DEFAULT_SESSION_PACK, graph_pack_path=DEFAULT_GRAPH_PACK, dot_path=DEFAULT_DOT_PATH, svg_path=DEFAULT_SVG_PATH, session_urn=DEFAULT_SESSION_URN, actor_urn=DEFAULT_ACTOR_URN, keep_channel_urn=DEFAULT_KEEP_CHANNEL_URN, keep_ki_urn=DEFAULT_KEEP_KI_URN, base_url=DEFAULT_BASE_URL, generated_at=format_utc(now(UTC)))
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
    push!(gates, gate(
        dot_exists && svg_exists ? "pass" : "warn",
        "static visual output",
        dot_exists && svg_exists ? "DOT and SVG visual artifacts exist." : "One or more static visual artifacts are missing.",
        evidence=Dict("dot_path" => dot_path, "dot_exists" => dot_exists, "svg_path" => svg_path, "svg_exists" => svg_exists),
        next_action=dot_exists && svg_exists ? "" : "Run export_t200plus_projection.jl with the intended lens preset; install Graphviz if SVG is missing.",
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
        ),
        "renderer_candidates" => RENDERER_CANDIDATES,
        "gates" => gates,
        "summary" => Dict(
            "pass" => count(g -> string(g["status"]) == "pass", gates),
            "warn" => count(g -> string(g["status"]) == "warn", gates),
            "fail" => count(g -> string(g["status"]) == "fail", gates),
        ),
    )
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
        "out-base" => DEFAULT_OUT_BASE,
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
        session_urn=options["session-urn"],
        actor_urn=options["actor-urn"],
        keep_channel_urn=options["keep-channel-urn"],
        keep_ki_urn=options["keep-ki-urn"],
        base_url=options["base-url"],
    )
    json_path = string(options["out-base"], ".json")
    markdown_path = string(options["out-base"], ".md")
    write_json(json_path, plan)
    write_markdown(markdown_path, plan)
    println("Wrote MVP gate JSON: ", json_path)
    println("Wrote MVP gate Markdown: ", markdown_path)
    println("Overall: ", plan["overall_status"], " Pass: ", plan["summary"]["pass"], " Warn: ", plan["summary"]["warn"], " Fail: ", plan["summary"]["fail"])
    return plan["overall_status"] == "fail" ? 1 : 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(SessionPipelineMVPGate.main())
end
