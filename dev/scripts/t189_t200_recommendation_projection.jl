#!/usr/bin/env julia

module T189T200RecommendationProjection

using Dates
using JSON3

const DEFAULT_ONTOLOGY = "kb/superset/ontology.json"
const DEFAULT_CALENDAR_PLAN = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json"
const DEFAULT_CALENDAR_WRITE_RESULT = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_write_result.json"
const DEFAULT_OUT = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.md"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:claude-code.hp-laptop"
const DEFAULT_T0_DATE = Date("2025-11-01")
const CREATED_AT = "2026-05-09T12:45:00Z"

const REQUIRED_TYPES = ["calendar_event", "derivation", "program", "purpose", "view_filter", "group"]
const REQUIRED_WFS = ["WF01", "WF07", "WF18", "WF19", "WF21"]

function object_value(obj, name::Symbol, default=nothing)
    if obj isa AbstractDict
        if haskey(obj, name)
            return obj[name]
        end
        key = string(name)
        return haskey(obj, key) ? obj[key] : default
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

function read_json(path::AbstractString)
    return JSON3.read(read(path, String))
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function type_ids(ontology)
    ids = Set{String}()
    types = object_value(ontology, :types, Dict())
    for group in values(types)
        group isa AbstractVector || continue
        for spec in group
            id = string(object_value(spec, :id, ""))
            !isempty(id) && push!(ids, id)
        end
    end
    return ids
end

function wf_ids(ontology)
    ids = Set{String}()
    for spec in object_value(ontology, :rewrite_categories, Any[])
        id = string(object_value(spec, :id, ""))
        !isempty(id) && push!(ids, id)
    end
    return ids
end

t_day_for_date(date::Date; t0_date::Date=DEFAULT_T0_DATE) = Dates.value(date - t0_date)

function slug_tail(text::AbstractString; limit::Integer=44)
    slug = lowercase(replace(strip(text), r"[^a-zA-Z0-9]+" => "-"))
    slug = strip(slug, ['-'])
    isempty(slug) && return "node"
    return length(slug) > limit ? slug[1:limit] : slug
end

function write_result_index(write_result)
    index = Dict{String, Any}()
    for result in object_value(write_result, :results, Any[])
        projection_id = string(object_value(result, :projection_id, ""))
        source_urn = string(object_value(result, :source_urn, ""))
        !isempty(projection_id) && (index[projection_id] = result)
        !isempty(source_urn) && (index[source_urn] = result)
    end
    return index
end

function node(urn::AbstractString, type_id::AbstractString, properties::AbstractDict; scope::AbstractString="grouped", note::AbstractString="")
    result = Dict{String, Any}(
        "urn" => urn,
        "type_id" => type_id,
        "properties" => Dict{String, Any}(string(key) => value for (key, value) in pairs(properties)),
        "recommendation_scope" => scope,
    )
    !isempty(note) && (result["note"] = note)
    return result
end

function relation(wf::AbstractString, src::AbstractString, src_port::AbstractString, tgt::AbstractString, tgt_port::AbstractString; status::AbstractString="declared", note::AbstractString="")
    result = Dict{String, Any}(
        "rewrite_category" => wf,
        "src_urn" => src,
        "src_port" => src_port,
        "tgt_urn" => tgt,
        "tgt_port" => tgt_port,
        "status" => status,
    )
    !isempty(note) && (result["note"] = note)
    return result
end

function calendar_event_node(event, write_index; t0_date::Date=DEFAULT_T0_DATE)
    google_event = object_value(event, :google_event, Dict())
    start = object_value(google_event, :start, Dict())
    date = Date(string(object_value(start, :date, "2026-05-09")))
    projection_id = string(object_value(event, :projection_id, ""))
    source_urn = string(object_value(event, :source_urn, ""))
    result = get(write_index, projection_id, get(write_index, source_urn, Dict()))
    gcal_id = string(object_value(result, :google_event_id, projection_id))
    status = isempty(string(object_value(result, :action, ""))) ? "tentative" : "confirmed"
    urn = string("urn:moos:cal:", date, ".", slug_tail(projection_id; limit=32))
    return node(
        urn,
        "calendar_event",
        Dict(
            "summary" => string(object_value(google_event, :summary, "mo:os Calendar projection event")),
            "date" => string(date),
            "t_day" => t_day_for_date(date; t0_date=t0_date),
            "gcal_id" => gcal_id,
            "color_label" => string(object_value(event, :calendar_label, "gray")),
            "status" => status,
            "created_at" => CREATED_AT,
        );
        scope="individual-calendar-event",
        note=string("Observed Calendar projection for ", source_urn),
    )
end

function selected_recommendations()
    return [
        Dict("id" => "calendar-g-ingest", "mode" => "individual", "node_urn" => "urn:moos:program:sam.t189.calendar-event-g-ingest-shape", "decision" => "Reify each written Google Calendar event as an individual calendar_event node, plus one derivation that records the grouped ingest decision."),
        Dict("id" => "github-hg-urn-refresh", "mode" => "group", "node_urn" => "urn:moos:program:sam.t189.github-project-urn-refresh", "decision" => "Refresh Project #4 rows as a grouped identity repair before any board-to-HG MUTATE path."),
        Dict("id" => "cytoscape-inspector", "mode" => "group", "node_urn" => "urn:moos:program:sam.t189.cytoscape-typed-hg-inspector", "decision" => "Prototype the interactive lens as a grouped projection surface beside Graphviz."),
        Dict("id" => "reusable-lens-spec", "mode" => "group", "node_urn" => "urn:moos:view_filter:sam.t189-time-fabric-session-lens", "decision" => "Promote the current lens shape to a reusable view_filter candidate before asking for an ontology change."),
        Dict("id" => "application-group-model", "mode" => "group", "node_urn" => "urn:moos:group:my-tiny-data-collider", "decision" => "Model my-tiny-data-collider as an HG application group/domain, not as kernel code."),
    ]
end

function grouped_nodes()
    return [
        node("urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence", "purpose", Dict(
            "subject_urn" => "urn:moos:user:sam",
            "target_state" => "T189 through T200 convergence: external events, project rows, dashboards, app groups, and sessions carry graph identity and valid relations.",
            "status" => "open",
            "started_at" => CREATED_AT,
        ); note="Umbrella purpose for the five T189 recommendations and T200+ convergence arc."),
        node("urn:moos:program:sam.t189.calendar-event-g-ingest-shape", "program", Dict(
            "title" => "Choose Calendar event G-ingest shape",
            "owner_urn" => "urn:moos:user:sam",
            "status" => "draft",
            "scope" => "Hybrid: individual calendar_event nodes for IRL events; one grouped derivation/result for the ingest decision.",
            "starts_t" => 189,
            "target_t" => 190,
            "created_at" => CREATED_AT,
        ); note="Individual side of this sprint: each IRL Calendar event is its own node with T properties."),
        node("urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision", "derivation", Dict(
            "name" => "T189 Calendar event G-ingest decision",
            "inference_kind" => "hand_authored",
            "confidence" => 0.9,
            "status" => "closed",
            "owner_urn" => "urn:moos:user:sam",
            "created_at" => CREATED_AT,
        ); note="Grouped decision node for the 16 event-node plan."),
        node("urn:moos:program:sam.t189.github-project-urn-refresh", "program", Dict(
            "title" => "Refresh Project #4 HG URN coverage",
            "owner_urn" => "urn:moos:user:sam",
            "status" => "draft",
            "scope" => "Populate HG URN on active GitHub Project rows before conservative G-direction board sync.",
            "starts_t" => 189,
            "target_t" => 190,
            "created_at" => CREATED_AT,
        )),
        node("urn:moos:program:sam.t189.cytoscape-typed-hg-inspector", "program", Dict(
            "title" => "Prototype Cytoscape.js typed HG inspector",
            "owner_urn" => "urn:moos:user:sam",
            "status" => "draft",
            "scope" => "Add an interactive graph lens beside Graphviz using existing graph artifact JSON.",
            "starts_t" => 190,
            "target_t" => 191,
            "created_at" => CREATED_AT,
        )),
        node("urn:moos:view_filter:sam.t189-time-fabric-session-lens", "view_filter", Dict(
            "name" => "T189 time fabric session lens",
            "owner_urn" => "urn:moos:user:sam",
            "predicate" => Dict(
                "filter_type" => "all_of",
                "predicates" => [
                    Dict("predicate_type" => "on_type", "type_ids" => ["program", "purpose", "calendar_event", "view_filter", "group", "channel", "derivation"]),
                    Dict("predicate_type" => "on_relation", "rewrite_categories" => ["WF01", "WF07", "WF18", "WF19", "WF21"]),
                ],
            ),
            "status" => "draft",
            "created_at" => CREATED_AT,
        ); note="Reusable lens candidate. Reify only after it serves multiple lanes."),
        node("urn:moos:group:my-tiny-data-collider", "group", Dict(
            "name" => "my-tiny-data-collider",
            "owner_urn" => "urn:moos:user:sam",
            "description" => "HG application group/domain for websites, DNS, servers, Calendar, GitHub, and Workspace surfaces running through mo:os kernels.",
            "status" => "active",
            "created_at" => CREATED_AT,
        ); note="Application domain group, separate from moos-kernel and moos-router runtime code."),
        node("urn:moos:purpose:sam.my-tiny-data-collider-application", "purpose", Dict(
            "subject_urn" => "urn:moos:group:my-tiny-data-collider",
            "target_state" => "A domain application whose external surfaces carry stable HG identity and are projected/ingested through explicit adapters.",
            "status" => "open",
            "started_at" => CREATED_AT,
        )),
        node("urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider", "program", Dict(
            "title" => "Model my-tiny-data-collider application group",
            "owner_urn" => "urn:moos:user:sam",
            "status" => "draft",
            "scope" => "Create the group, purpose, channel set, and program family for the application domain.",
            "starts_t" => 191,
            "target_t" => 192,
            "created_at" => CREATED_AT,
        )),
        node("urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence", "program", Dict(
            "title" => "T200+ identity-stable projection surface convergence",
            "owner_urn" => "urn:moos:user:sam",
            "status" => "draft",
            "scope" => "Calendar, GitHub, dashboard, website, DNS, Workspace, and OS-host surfaces carry graph-derived identity and have conservative G-ingest paths.",
            "starts_t" => 190,
            "target_t" => 200,
            "created_at" => CREATED_AT,
        ); note="T200 convergence carrier. Programs may have T properties; external IRL events become calendar_event nodes."),
    ]
end

function grouped_relations(calendar_nodes)
    purpose = "urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence"
    group = "urn:moos:group:my-tiny-data-collider"
    app_purpose = "urn:moos:purpose:sam.my-tiny-data-collider-application"
    ingest_program = "urn:moos:program:sam.t189.calendar-event-g-ingest-shape"
    relations = [
        relation("WF19", DEFAULT_SESSION_URN, "pins-urn", purpose, "pinned-by-session"),
        relation("WF19", DEFAULT_SESSION_URN, "pins-urn", "urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision", "pinned-by-session"),
        relation("WF19", DEFAULT_SESSION_URN, "filtered-by", "urn:moos:view_filter:sam.t189-time-fabric-session-lens", "filters-session"),
        relation("WF21", "urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision", "causes", ingest_program, "caused-by"),
        relation("WF01", group, "owns", app_purpose, "owned-by"),
        relation("WF18", app_purpose, "composes", "urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider", "composed-by"),
    ]
    for program in [
        "urn:moos:program:sam.t189.calendar-event-g-ingest-shape",
        "urn:moos:program:sam.t189.github-project-urn-refresh",
        "urn:moos:program:sam.t189.cytoscape-typed-hg-inspector",
        "urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider",
        "urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence",
    ]
        push!(relations, relation("WF18", purpose, "composes", program, "composed-by"))
        push!(relations, relation("WF19", DEFAULT_SESSION_URN, "pins-urn", program, "pinned-by-session"))
    end
    for event_node in calendar_nodes
        push!(relations, relation("WF19", DEFAULT_SESSION_URN, "pins-urn", event_node["urn"], "pinned-by-session"))
    end
    return relations
end

function deferred_calendar_anchor_relations(calendar_nodes, calendar_plan)
    events_by_projection = Dict(string(object_value(event, :projection_id, "")) => event for event in object_value(calendar_plan, :events, Any[]))
    deferred = Any[]
    for event_node in calendar_nodes
        projection_tail = split(string(event_node["urn"]), ".")[end]
        projection_id = startswith(projection_tail, "moos-") ? projection_tail : ""
        event = get(events_by_projection, projection_id, nothing)
        event === nothing && continue
        source_urn = string(object_value(event, :source_urn, ""))
        isempty(source_urn) && continue
        push!(deferred, relation("WF07", event_node["urn"], "anchors", source_urn, "anchor"; status="requires-operad-review", note="calendar_event declares anchors and port_color_compat lists WF07 anchors/anchor, but WF07 top-level declaration still names participates/participated-by. Check loader behavior before applying."))
    end
    return deferred
end

function t200_recommendations()
    return [
        Dict("t_range" => "T189-T190", "urn" => "urn:moos:program:sam.t189.calendar-event-g-ingest-shape", "recommendation" => "Land the hybrid Calendar G-ingest shape: individual calendar_event nodes for IRL events with date/t_day/gcal_id/color_label/status, plus one derivation/result for the batch decision."),
        Dict("t_range" => "T190", "urn" => "urn:moos:program:sam.t189.github-project-urn-refresh", "recommendation" => "Reproject active Project #4 rows from HG and restore HG URN coverage before trusting board edits as rewrite intents."),
        Dict("t_range" => "T190-T191", "urn" => "urn:moos:program:sam.t189.cytoscape-typed-hg-inspector", "recommendation" => "Add Cytoscape.js as a typed selection/inspector surface over the same graph artifact JSON; keep Graphviz as deterministic review output."),
        Dict("t_range" => "T191-T192", "urn" => "urn:moos:group:my-tiny-data-collider", "recommendation" => "Model the application domain as group + purpose + program family + channels. Keep runtime repos as substrate, not application identity."),
        Dict("t_range" => "T192-T200", "urn" => "urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence", "recommendation" => "Converge all external surfaces on graph-derived identity and explicit dry planner / writer / readback adapters: Calendar, GitHub, dashboard, websites, DNS, Workspace, and OS-host channels."),
    ]
end

function plan_projection(ontology, calendar_plan, write_result; t0_date::Date=DEFAULT_T0_DATE)
    known_types = type_ids(ontology)
    known_wfs = wf_ids(ontology)
    write_index = write_result_index(write_result)
    calendar_nodes = [calendar_event_node(event, write_index; t0_date=t0_date) for event in object_value(calendar_plan, :events, Any[])]
    group_nodes = grouped_nodes()
    candidate_nodes = vcat(group_nodes, calendar_nodes)
    candidate_relations = grouped_relations(calendar_nodes)
    deferred_relations = deferred_calendar_anchor_relations(calendar_nodes, calendar_plan)
    used_types = Set(string(node["type_id"]) for node in candidate_nodes)
    used_wfs = Set(string(rel["rewrite_category"]) for rel in vcat(candidate_relations, deferred_relations))

    return Dict(
        "mode" => "plan",
        "projection_kind" => "t189_t200_recommendation_hg_plan",
        "generated_at" => CREATED_AT,
        "session_urn" => DEFAULT_SESSION_URN,
        "actor_urn" => DEFAULT_ACTOR_URN,
        "ontology_version" => string(object_value(ontology, :version, "")),
        "selected_t189_recommendations" => selected_recommendations(),
        "calendar_ingest_decision" => Dict(
            "chosen_shape" => "hybrid",
            "individual" => "Each real Google Calendar write becomes one calendar_event node with date, t_day, gcal_id, color_label, and status.",
            "group" => "One derivation records why the batch uses individual event nodes and causes the Calendar G-ingest program.",
            "event_count" => length(calendar_nodes),
        ),
        "candidate_nodes" => candidate_nodes,
        "candidate_relations" => candidate_relations,
        "deferred_relations" => deferred_relations,
        "candidate_node_count" => length(candidate_nodes),
        "candidate_relation_count" => length(candidate_relations),
        "deferred_relation_count" => length(deferred_relations),
        "calendar_event_node_count" => length(calendar_nodes),
        "ontology_check" => Dict(
            "required_types" => REQUIRED_TYPES,
            "required_wfs" => REQUIRED_WFS,
            "unknown_required_types" => [type for type in REQUIRED_TYPES if !(type in known_types)],
            "unknown_required_wfs" => [wf for wf in REQUIRED_WFS if !(wf in known_wfs)],
            "used_types" => sort(collect(used_types)),
            "used_wfs" => sort(collect(used_wfs)),
        ),
        "t200_recommendations" => t200_recommendations(),
    )
end

function write_markdown(path::AbstractString, plan)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# T189/T200 Recommendation HG Projection")
        println(io)
        println(io, "Generated: ", plan["generated_at"])
        println(io, "Ontology: ", plan["ontology_version"])
        println(io, "Session: `", plan["session_urn"], "`")
        println(io)
        println(io, "## T189 Selection")
        for rec in plan["selected_t189_recommendations"]
            println(io, "- `", rec["id"], "` (", rec["mode"], "): ", rec["decision"])
        end
        println(io)
        decision = plan["calendar_ingest_decision"]
        println(io, "## Calendar G-Ingest Decision")
        println(io, "Chosen shape: `", decision["chosen_shape"], "`")
        println(io)
        println(io, "- Individual: ", decision["individual"])
        println(io, "- Group: ", decision["group"])
        println(io, "- Planned calendar_event nodes: ", decision["event_count"])
        println(io)
        println(io, "## Candidate Graph")
        println(io, "- Candidate nodes: ", plan["candidate_node_count"])
        println(io, "- Candidate relations: ", plan["candidate_relation_count"])
        println(io, "- Deferred relation checks: ", plan["deferred_relation_count"])
        println(io)
        println(io, "| Type | URN | Scope |")
        println(io, "| --- | --- | --- |")
        for candidate in plan["candidate_nodes"]
            println(io, "| `", candidate["type_id"], "` | `", candidate["urn"], "` | ", candidate["recommendation_scope"], " |")
        end
        println(io)
        println(io, "## T200+ Recommendations")
        for rec in plan["t200_recommendations"]
            println(io, "- ", rec["t_range"], " `", rec["urn"], "`: ", rec["recommendation"])
        end
        println(io)
        println(io, "## Ontology Check")
        check = plan["ontology_check"]
        println(io, "- Unknown required types: ", isempty(check["unknown_required_types"]) ? "none" : join(check["unknown_required_types"], ", "))
        println(io, "- Unknown required WFs: ", isempty(check["unknown_required_wfs"]) ? "none" : join(check["unknown_required_wfs"], ", "))
        println(io)
        println(io, "Deferred relations are not failures. They mark where the current ontology has a useful port-color clue, but the top-level rewrite category still needs loader/validator confirmation before an APPLY batch.")
    end
end

function parse_args(argv)
    options = Dict(
        "ontology" => DEFAULT_ONTOLOGY,
        "calendar-plan" => DEFAULT_CALENDAR_PLAN,
        "calendar-write-result" => DEFAULT_CALENDAR_WRITE_RESULT,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "t0-date" => string(DEFAULT_T0_DATE),
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
    ontology = read_json(options["ontology"])
    calendar_plan = read_json(options["calendar-plan"])
    write_result = isfile(options["calendar-write-result"]) ? read_json(options["calendar-write-result"]) : Dict("results" => Any[])
    plan = plan_projection(ontology, calendar_plan, write_result; t0_date=Date(options["t0-date"]))
    write_json(options["out"], plan)
    write_markdown(options["markdown-out"], plan)
    println("Wrote recommendation HG plan: ", options["out"])
    println("Wrote recommendation HG report: ", options["markdown-out"])
    println("Candidate nodes: ", plan["candidate_node_count"], " Candidate relations: ", plan["candidate_relation_count"], " Deferred relations: ", plan["deferred_relation_count"])
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(T189T200RecommendationProjection.main())
end
