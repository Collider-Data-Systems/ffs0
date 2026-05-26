#!/usr/bin/env julia

module CalendarTimeFabricProjection

using Dates
using Downloads
using JSON3
using SHA

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_GRAPH_ARTIFACT = "tmp/projections/session_pipeline/graph_artifacts/session_occasion_engineering.json"
const DEFAULT_SCOPE_ARTIFACT = "tmp/projections/session_pipeline/graph_artifacts/calendar_scope_engineering.json"
const DEFAULT_OUT = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.md"
const DEFAULT_WRITE_RESULT = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_write_result.json"
const DEFAULT_CONTRACT_URN = "urn:moos:program:sam.t189.calendar-time-fabric-proof"
const DEFAULT_CHANNEL_URN = "urn:moos:channel:google.calendar.sam"
const DEFAULT_T0_DATE = Date("2025-11-01")

const TYPE_LABELS = Dict(
    "claim" => "blue",
    "derivation" => "purple",
    "grammar_fragment" => "red",
    "knowledge_item" => "green",
    "pattern" => "yellow",
    "program" => "purple",
    "purpose" => "purple",
    "session" => "gray",
    "system_instruction" => "gray",
    "workflow" => "orange",
)

const TYPE_ORDER = Dict(
    "derivation" => 1,
    "knowledge_item" => 2,
    "claim" => 3,
    "grammar_fragment" => 4,
    "pattern" => 5,
    "system_instruction" => 6,
    "workflow" => 7,
    "program" => 8,
    "purpose" => 9,
    "session" => 10,
)

const TEMPORAL_FIELDS = [:t_day, :starts_t, :target_t, :deadline_t, :completed_t, :t_start, :t_target]

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

function string_value(value, default="")
    if value === nothing
        return default
    end
    text = strip(string(value))
    return isempty(text) ? default : text
end

function optional_t(value)
    text = string_value(value)
    isempty(text) && return nothing
    try
        return parse(Int, text)
    catch
        return nothing
    end
end

t_day_date(t_day::Integer; t0_date::Date=DEFAULT_T0_DATE) = t0_date + Day(t_day)

function projection_id(urn::AbstractString, contract_urn::AbstractString=DEFAULT_CONTRACT_URN)
    digest = bytes2hex(sha1(string(contract_urn, "|", urn)))
    return string("moos-", digest[1:24])
end

function node_title(node)
    title = string_value(object_value(node, :title, ""))
    if !isempty(title)
        return title
    end
    props = object_value(node, :properties, Dict())
    for field in (:title, :name, :summary)
        value = object_value(props, field, nothing)
        if value !== nothing
            value = value isa AbstractDict ? object_value(value, :value, nothing) : value
            text = string_value(value)
            !isempty(text) && return text
        end
    end
    return string_value(object_value(node, :urn, "<unknown>"), "<unknown>")
end

function short_title(text::AbstractString; limit::Integer=86)
    clean = replace(strip(text), r"\s+" => " ")
    ncodeunits(clean) <= limit && return clean
    return string(first(clean, limit - 3), "...")
end

function node_status(node)
    status = string_value(object_value(node, :status, ""))
    if !isempty(status)
        return status
    end
    props = object_value(node, :properties, Dict())
    value = object_value(props, :status, nothing)
    value = value isa AbstractDict ? object_value(value, :value, nothing) : value
    return string_value(value, "<none>")
end

function node_property_value(node, field::Symbol, default=nothing)
    props = object_value(node, :properties, Dict())
    value = object_value(props, field, nothing)
    value = value isa AbstractDict ? object_value(value, :value, nothing) : value
    return value === nothing ? default : value
end

function node_t_value(node, fields::Vector{Symbol})
    value, _ = node_t_value_detail(node, fields)
    return value
end

function node_t_value_detail(node, fields::Vector{Symbol})
    props = object_value(node, :properties, Dict())
    for field in fields
        value = object_value(props, field, nothing)
        value = value isa AbstractDict ? object_value(value, :value, nothing) : value
        parsed = optional_t(value)
        parsed !== nothing && return parsed, string(field)
    end
    return nothing, ""
end

function relation_context(relations, urn::AbstractString)
    incoming = []
    outgoing = []
    for rel in relations
        src = string_value(object_value(rel, :src_urn, ""))
        tgt = string_value(object_value(rel, :tgt_urn, ""))
        if src == urn
            push!(outgoing, rel)
        elseif tgt == urn
            push!(incoming, rel)
        end
    end
    return incoming, outgoing
end

function relation_line(rel)
    src_port = string_value(object_value(rel, :src_port, ""))
    tgt_port = string_value(object_value(rel, :tgt_port, ""))
    other = string_value(object_value(rel, :src_urn, ""))
    return string(src_port, " / ", tgt_port, " :: ", other)
end

function summarize_relations(incoming, outgoing; limit::Integer=4)
    lines = String[]
    if !isempty(incoming)
        push!(lines, "Incoming relations:")
        for rel in incoming[1:min(end, limit)]
            src = string_value(object_value(rel, :src_urn, ""))
            port = string_value(object_value(rel, :tgt_port, ""))
            wf = string_value(object_value(rel, :rewrite_category, ""))
            push!(lines, string("- ", wf, " ", port, " <- ", src))
        end
    end
    if !isempty(outgoing)
        push!(lines, "Outgoing relations:")
        for rel in outgoing[1:min(end, limit)]
            tgt = string_value(object_value(rel, :tgt_urn, ""))
            port = string_value(object_value(rel, :src_port, ""))
            wf = string_value(object_value(rel, :rewrite_category, ""))
            push!(lines, string("- ", wf, " ", port, " -> ", tgt))
        end
    end
    return lines
end

function event_date_for_node(node, index::Integer; anchor_t::Integer, t0_date::Date)
    explicit_t, field = node_t_value_detail(node, TEMPORAL_FIELDS)
    if explicit_t !== nothing
        return t_day_date(explicit_t; t0_date=t0_date), Dict(
            "kind" => "explicit_temporal_property",
            "field" => field,
            "t_day" => explicit_t,
            "note" => string("explicit T", explicit_t),
            "strength" => "high",
        )
    end
    offset = fld(index - 1, 5)
    return t_day_date(anchor_t + offset; t0_date=t0_date), Dict(
        "kind" => "lens_order_placement",
        "field" => "<none>",
        "t_day" => anchor_t + offset,
        "note" => string("lens-order placement from active T", anchor_t),
        "strength" => "low",
    )
end

function surface_role(type_id::AbstractString)
    type_id == "calendar_event" && return "G-observation-temporal-anchor"
    type_id in Set(["program", "purpose", "session", "view_filter", "channel", "clock"]) && return "F-control-and-scope-carrier"
    type_id in Set(["derivation", "claim", "knowledge_item"]) && return "evidence-lineage"
    type_id in Set(["external_op", "tool_call"]) && return "actuator-boundary"
    return "context-node"
end

function reliability_for(type_id::AbstractString, temporal_basis)
    if type_id == "calendar_event"
        return Dict(
            "level" => "high",
            "reason" => "calendar_event nodes are G-observations already typed back into HG with date/t_day identity",
        )
    elseif string(object_value(temporal_basis, :kind, "")) == "written_calendar_observation_lock"
        return Dict(
            "level" => "high",
            "reason" => "event date is locked to an existing HG calendar_event observation anchored to this source",
        )
    elseif string(object_value(temporal_basis, :kind, "")) == "explicit_temporal_property"
        return Dict(
            "level" => "medium_high",
            "reason" => "event date comes from an explicit HG temporal property; Calendar is a readable projection of graph time",
        )
    else
        return Dict(
            "level" => "low",
            "reason" => "event date is lens-order placement; useful as a dashboard reminder, not a reliable schedule claim",
        )
    end
end

function relation_category_counts(incoming, outgoing)
    counts = Dict{String, Int}()
    for rel in vcat(incoming, outgoing)
        category = string_value(object_value(rel, :rewrite_category, "<none>"), "<none>")
        counts[category] = get(counts, category, 0) + 1
    end
    return counts
end

function locked_calendar_date(lock, fallback_t::Integer; t0_date::Date)
    date_value = object_value(lock, :date, nothing)
    if date_value isa Date
        return date_value
    end
    date_text = string_value(date_value)
    if !isempty(date_text)
        try
            return Date(date_text)
        catch
        end
    end
    t_value = optional_t(object_value(lock, :t_day, nothing))
    return t_day_date(t_value === nothing ? fallback_t : t_value; t0_date=t0_date)
end

function calendar_payload(node, index::Integer, relations; contract_urn::String, anchor_t::Integer, t0_date::Date, written_observation_locks=Dict{String, Any}())
    urn = string_value(object_value(node, :urn, ""))
    isempty(urn) && return nothing
    type_id = string_value(object_value(node, :type_id, "unknown"), "unknown")
    title = short_title(node_title(node))
    status = node_status(node)
    date, temporal_basis = event_date_for_node(node, index; anchor_t=anchor_t, t0_date=t0_date)
    observation_lock = get(written_observation_locks, urn, nothing)
    if observation_lock !== nothing
        date = locked_calendar_date(observation_lock, anchor_t; t0_date=t0_date)
        lock_t = optional_t(object_value(observation_lock, :t_day, nothing))
        temporal_basis = Dict(
            "kind" => "written_calendar_observation_lock",
            "field" => "calendar_event.date",
            "t_day" => lock_t === nothing ? anchor_t : lock_t,
            "note" => string("stored Calendar observation ", string_value(object_value(observation_lock, :calendar_event_urn, "<unknown>"))),
            "strength" => "high",
        )
    end
    timing_note = string(temporal_basis["note"])
    incoming, outgoing = relation_context(relations, urn)
    reliability = reliability_for(type_id, temporal_basis)
    projection = projection_id(urn, contract_urn)
    summary = short_title(string("mo:os ", type_id, " :: ", title); limit=96)
    description = String[
        string("HG URN: ", urn),
        string("Type: ", type_id),
        string("Status: ", status),
        string("Projection contract: ", contract_urn),
        string("Moos T anchor: T", anchor_t),
        string("IRL calendar date: ", date),
        string("Temporal interpretation: ", timing_note),
        string("Surface role: ", surface_role(type_id)),
        string("Calendar reliability: ", reliability["level"], " - ", reliability["reason"]),
        string("Relation counts: incoming=", length(incoming), ", outgoing=", length(outgoing)),
    ]
    relation_lines = summarize_relations(incoming, outgoing)
    if !isempty(relation_lines)
        push!(description, "")
        append!(description, relation_lines)
    end
    push!(description, "")
    push!(description, "Generated by mo:os Calendar time-fabric projection. Calendar is a projection surface; HG remains source of truth.")

    return Dict(
        "operation" => "upsert",
        "projection_id" => projection,
        "source_urn" => urn,
        "source_type" => type_id,
        "event_kind" => "recent_time_fabric_node",
        "surface_role" => surface_role(type_id),
        "temporal_basis" => temporal_basis,
        "calendar_reliability" => reliability,
        "relation_context" => Dict(
            "incoming_count" => length(incoming),
            "outgoing_count" => length(outgoing),
            "category_counts" => relation_category_counts(incoming, outgoing),
        ),
        "locked_calendar_event_urn" => observation_lock === nothing ? "" : string_value(object_value(observation_lock, :calendar_event_urn, "")),
        "calendar_label" => get(TYPE_LABELS, type_id, "gray"),
        "google_event" => Dict(
            "summary" => summary,
            "description" => join(description, "\n"),
            "start" => Dict("date" => string(date)),
            "end" => Dict("date" => string(date + Day(1))),
            "extendedProperties" => Dict(
                "private" => Dict(
                    "moos_urn" => urn,
                    "moos_type" => type_id,
                    "moos_contract_urn" => contract_urn,
                    "moos_projection_id" => projection,
                    "moos_event_kind" => "recent_time_fabric_node",
                ),
            ),
        ),
    )
end

function sorted_recent_nodes(nodes)
    pairs = collect(enumerate(nodes))
    sort!(pairs; by = pair -> begin
        node = pair[2]
        type_id = string_value(object_value(node, :type_id, "unknown"), "unknown")
        (get(TYPE_ORDER, type_id, 99), string_value(object_value(node, :urn, "")))
    end)
    return [pair[2] for pair in pairs]
end

function safe_read_json(path::AbstractString)
    isempty(strip(path)) && return nothing
    isfile(path) || return nothing
    try
        return JSON3.read(read(path, String))
    catch
        return nothing
    end
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

function write_result_source_urns(path::AbstractString)
    result = safe_read_json(path)
    result === nothing && return Set{String}()
    sources = Set{String}()
    for row in object_value(result, :results, Any[])
        source_urn = string_value(object_value(row, :source_urn, ""))
        !isempty(source_urn) && push!(sources, source_urn)
    end
    return sources
end

function calendar_date_from_urn(calendar_urn::AbstractString)
    matched = match(r"^urn:moos:cal:(\d{4}-\d{2}-\d{2})\.", calendar_urn)
    matched === nothing && return nothing
    try
        return Date(matched.captures[1])
    catch
        return nothing
    end
end

function calendar_observation_locks_from_graph(nodes, relations; t0_date::Date=DEFAULT_T0_DATE)
    nodes_by_urn = Dict{String, Any}()
    for node in nodes
        urn = string_value(object_value(node, :urn, ""))
        !isempty(urn) && (nodes_by_urn[urn] = node)
    end

    locks = Dict{String, Any}()
    for rel in relations
        string_value(object_value(rel, :rewrite_category, "")) == "WF07" || continue
        string_value(object_value(rel, :src_port, "")) == "anchors" || continue
        string_value(object_value(rel, :tgt_port, "")) == "anchor" || continue
        calendar_urn = string_value(object_value(rel, :src_urn, ""))
        source_urn = string_value(object_value(rel, :tgt_urn, ""))
        startswith(calendar_urn, "urn:moos:cal:") || continue
        isempty(source_urn) && continue
        node = get(nodes_by_urn, calendar_urn, nothing)
        node === nothing && continue
        parsed_urn_date = calendar_date_from_urn(calendar_urn)
        date_value = node_property_value(node, :date, "")
        date_text = string_value(date_value)
        if isempty(date_text) && parsed_urn_date !== nothing
            date_text = string(parsed_urn_date)
        end
        isempty(date_text) && continue
        t_day_value = node_property_value(node, :t_day, nothing)
        if t_day_value === nothing && parsed_urn_date !== nothing
            t_day_value = Dates.value(parsed_urn_date - t0_date)
        end
        locks[source_urn] = Dict(
            "calendar_event_urn" => calendar_urn,
            "date" => date_text,
            "t_day" => t_day_value,
        )
    end
    return locks
end

function calendar_observation_locks(scope_artifact_path::AbstractString; t0_date::Date=DEFAULT_T0_DATE)
    artifact = safe_read_json(scope_artifact_path)
    artifact === nothing && return Dict{String, Any}()
    return calendar_observation_locks_from_graph(
        object_value(artifact, :nodes, Any[]),
        object_value(artifact, :relations, Any[]);
        t0_date=t0_date,
    )
end

function live_calendar_observation_locks(base_url::AbstractString; t0_date::Date=DEFAULT_T0_DATE)
    isempty(strip(base_url)) && return Dict{String, Any}()
    try
        nodes = fetch_json(base_url, "/state/nodes")
        relations = fetch_json(base_url, "/state/relations")
        return calendar_observation_locks_from_graph(nodes, relations; t0_date=t0_date)
    catch err
        println(stderr, "Warning: could not read live calendar observation locks from ", base_url, ": ", sprint(showerror, err))
        return Dict{String, Any}()
    end
end

function scope_diagnostics(path::AbstractString)
    artifact = safe_read_json(path)
    artifact === nothing && return Dict(
        "path" => path,
        "exists" => false,
        "summary" => "No Calendar-scope graph artifact was available for this run.",
    )
    analysis = object_value(artifact, :analysis, Dict())
    root_coverage = object_value(analysis, :root_coverage, Any[])
    disconnected = [entry for entry in root_coverage if !Bool(object_value(entry, :connected, false))]
    return Dict(
        "path" => path,
        "exists" => true,
        "node_count" => Int(object_value(artifact, :node_count, 0)),
        "relation_count" => Int(object_value(artifact, :relation_count, 0)),
        "state_node_count" => Int(object_value(analysis, :state_node_count, 0)),
        "state_relation_count" => Int(object_value(analysis, :state_relation_count, 0)),
        "component_count" => Int(object_value(analysis, :component_count, 0)),
        "largest_component_size" => Int(object_value(analysis, :largest_component_size, 0)),
        "root_count" => length(root_coverage),
        "disconnected_root_count" => length(disconnected),
        "disconnected_roots" => [string_value(object_value(entry, :urn, "")) for entry in disconnected],
    )
end

function slice_policy(max_events::Integer; written_source_lock::Bool=false)
    return Dict(
        "event_source" => "session_occasion_graph_artifact_nodes",
        "event_order" => "type-priority, then URN, then projected date",
        "max_events" => max_events,
        "default_depth" => 2,
        "calendar_scope_depth" => 3,
        "include_wfs" => ["WF01", "WF07", "WF12", "WF18", "WF19", "WF21"],
        "written_source_lock" => written_source_lock,
        "interpretation" => written_source_lock ? "Only graph nodes whose source_urn appears in the stored Calendar writer result become Calendar event candidates; widened visual context remains inspectable but does not create new G-readback rows." : "Only nodes admitted by the selected lens become Calendar events; the broader Calendar-scope artifact reports nearby graph availability and disconnected roots.",
    )
end

function temporal_property_policy()
    return Dict(
        "explicit_fields" => [string(field) for field in TEMPORAL_FIELDS],
        "strong_basis" => "calendar_event.date/t_day or program temporal fields such as starts_t, target_t, deadline_t, completed_t",
        "weak_basis" => "lens-order placement from active T when a node has no explicit temporal property",
        "dependency_relations" => Dict(
            "WF18" => "program/purpose composition and known-node dependency DAG",
            "WF21" => "causal lineage across derivation, claim, knowledge_item, program, channel, and clock",
            "WF19" => "session scope, host, occupant, purpose, pins, and view filters",
        ),
    )
end

function ontological_patterns()
    return [
        Dict("name" => "evidence", "shape" => "channel -> knowledge_item -> claim, with derivation as inference carrier", "relations" => ["WF12", "WF21"]),
        Dict("name" => "work", "shape" => "purpose/session/program: purpose colors the session, program carries temporal work", "relations" => ["WF18", "WF19"]),
        Dict("name" => "actuator", "shape" => "external_op/tool_call/writer result: explicit boundary, never hidden inside a planner", "relations" => ["WF18", "WF21"]),
        Dict("name" => "condition", "shape" => "t_hook/watchers/external_op conditions unblock programs; status is observed and gated", "relations" => ["WF17", "WF18"]),
        Dict("name" => "argument", "shape" => "tool_call.arguments and pattern/workflow schemas are carriers, while topology stays in relations", "relations" => ["WF05", "WF18"]),
        Dict("name" => "branchless-FP", "shape" => "project from folded state with pure planners; writers and rewrites are separate actuator/apply steps", "relations" => ["fold", "F", "G"]),
    ]
end

function plan_time_fabric_projection(artifact; contract_urn::String=DEFAULT_CONTRACT_URN, channel_urn::String=DEFAULT_CHANNEL_URN, anchor_t::Integer=188, t0_date::Date=DEFAULT_T0_DATE, max_events::Integer=64, scope_artifact_path::String=DEFAULT_SCOPE_ARTIFACT, written_source_urns::Set{String}=Set{String}(), write_result_path::String="", base_url::String="")
    all_nodes = sorted_recent_nodes(collect(object_value(artifact, :nodes, [])))
    written_source_lock = !isempty(written_source_urns)
    artifact_locks = written_source_lock ? calendar_observation_locks(scope_artifact_path; t0_date=t0_date) : Dict{String, Any}()
    live_locks = written_source_lock ? live_calendar_observation_locks(base_url; t0_date=t0_date) : Dict{String, Any}()
    written_observation_locks = merge(artifact_locks, live_locks)
    nodes = written_source_lock ? [node for node in all_nodes if string_value(object_value(node, :urn, "")) in written_source_urns] : all_nodes
    relations = collect(object_value(artifact, :relations, []))
    if max_events > 0 && length(nodes) > max_events
        nodes = nodes[1:max_events]
    end
    events = Dict{String, Any}[]
    for (index, node) in enumerate(nodes)
        payload = calendar_payload(node, index, relations; contract_urn=contract_urn, anchor_t=anchor_t, t0_date=t0_date, written_observation_locks=written_observation_locks)
        payload !== nothing && push!(events, payload)
    end
    sort!(events; by = event -> (event["google_event"]["start"]["date"], event["source_type"], event["source_urn"]))
    explicit_count = count(event -> string(object_value(event["temporal_basis"], :kind, "")) == "explicit_temporal_property", events)
    lens_order_count = length(events) - explicit_count
    return Dict(
        "mode" => "plan",
        "source" => "hg_graph_artifact",
        "projection_kind" => "calendar_time_fabric_recent_nodes",
        "contract_urn" => contract_urn,
        "channel_urn" => channel_urn,
        "anchor_t" => anchor_t,
        "anchor_date" => string(t_day_date(anchor_t; t0_date=t0_date)),
        "t0_date" => string(t0_date),
        "node_count" => length(nodes),
        "source_node_count" => length(all_nodes),
        "relation_count" => length(relations),
        "event_count" => length(events),
        "slice_policy" => slice_policy(max_events; written_source_lock=written_source_lock),
        "temporal_property_policy" => temporal_property_policy(),
        "scope_diagnostics" => scope_diagnostics(scope_artifact_path),
        "calendar_surface_assessment" => Dict(
            "reliable_as" => ["readable F-projection index", "operator reminder surface", "G-observation carrier when calendar_event nodes are reconciled back into HG"],
            "not_reliable_as" => ["source of truth", "complete task scheduler", "proof that unlinked nodes are in session scope"],
            "explicit_temporal_event_count" => explicit_count,
            "lens_order_event_count" => lens_order_count,
            "written_source_lock" => Dict(
                "enabled" => written_source_lock,
                "write_result_path" => write_result_path,
                "source_urn_count" => length(written_source_urns),
                "calendar_observation_lock_count" => length(written_observation_locks),
                "artifact_observation_lock_count" => length(artifact_locks),
                "live_observation_lock_count" => length(live_locks),
                "live_base_url" => base_url,
                "excluded_node_count" => max(length(all_nodes) - length(nodes), 0),
            ),
            "writer_boundary" => "google_calendar_writer.jl is the explicit actuator; this planner is dry and side-effect free",
        ),
        "ontological_patterns" => ontological_patterns(),
        "events" => events,
    )
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function write_markdown(path::AbstractString, plan)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Calendar Time-Fabric Projection")
        println(io)
        println(io, "- Projection kind: `", plan["projection_kind"], "`")
        println(io, "- Contract URN: `", plan["contract_urn"], "`")
        println(io, "- Anchor: T", plan["anchor_t"], " / ", plan["anchor_date"])
        println(io, "- Events: ", plan["event_count"])
        lock = plan["calendar_surface_assessment"]["written_source_lock"]
        observation_count = get(lock, "calendar_observation_lock_count", 0)
        println(io, "- Written-source lock: ", lock["enabled"], " (", lock["source_urn_count"], " source URNs; ", observation_count, " existing observation dates; ", lock["excluded_node_count"], " nodes excluded)")
        println(io, "- Slice: ", plan["slice_policy"]["event_source"], "; depth ", plan["slice_policy"]["default_depth"], " for event candidates, depth ", plan["slice_policy"]["calendar_scope_depth"], " for Calendar-scope diagnostics")
        println(io, "- Temporal basis: ", plan["calendar_surface_assessment"]["explicit_temporal_event_count"], " explicit, ", plan["calendar_surface_assessment"]["lens_order_event_count"], " lens-order")
        println(io)
        println(io, "## Calendar Surface Reliability")
        println(io, "Calendar is reliable here as a readable F-projection index and as a G-observation carrier after Calendar events are reconciled into HG. It is not the source of truth, not a complete scheduler, and not proof that disconnected nodes are in session scope.")
        println(io, "Writer boundary: ", plan["calendar_surface_assessment"]["writer_boundary"])
        println(io)
        println(io, "## Calendar Scope Diagnostics")
        scope = plan["scope_diagnostics"]
        if Bool(object_value(scope, :exists, false))
            println(io, "- Artifact: `", scope["path"], "`")
            println(io, "- Selected: ", scope["node_count"], "/", scope["state_node_count"], " nodes; ", scope["relation_count"], "/", scope["state_relation_count"], " relations")
            println(io, "- Components: ", scope["component_count"], " (largest ", scope["largest_component_size"], " nodes)")
            println(io, "- Roots: ", scope["root_count"], "; disconnected: ", scope["disconnected_root_count"])
        else
            println(io, "- ", scope["summary"])
        end
        println(io)
        println(io, "## Ontological Pattern Reading")
        for pattern in plan["ontological_patterns"]
            println(io, "- ", pattern["name"], ": ", pattern["shape"])
        end
        println(io)
        println(io, "| Date | Type | Source URN | Summary |")
        println(io, "| --- | --- | --- | --- |")
        for event in plan["events"]
            date = event["google_event"]["start"]["date"]
            println(io, "| ", date, " | `", event["source_type"], "` | `", event["source_urn"], "` | ", replace(event["google_event"]["summary"], "|" => "\\|"), " |")
        end
    end
end

function parse_args(argv)
    options = Dict(
        "graph-artifact" => DEFAULT_GRAPH_ARTIFACT,
        "base-url" => DEFAULT_BASE_URL,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "contract-urn" => DEFAULT_CONTRACT_URN,
        "channel-urn" => DEFAULT_CHANNEL_URN,
        "scope-artifact" => DEFAULT_SCOPE_ARTIFACT,
        "write-result-path" => "",
        "lock-written-sources" => "false",
        "anchor-t" => "188",
        "t0-date" => string(DEFAULT_T0_DATE),
        "max-events" => "64",
    )
    i = 1
    while i <= length(argv)
        arg = argv[i]
        if !startswith(arg, "--")
            error("unexpected argument: ", arg)
        end
        key = arg[3:end]
        if !haskey(options, key)
            error("unknown option: ", arg)
        end
        if i == length(argv)
            error("missing value for ", arg)
        end
        options[key] = argv[i + 1]
        i += 2
    end
    return options
end

parse_bool(value::AbstractString) = lowercase(strip(value)) in Set(["1", "true", "yes", "on"])

function main(argv=ARGS)
    options = parse_args(argv)
    artifact = JSON3.read(read(options["graph-artifact"], String))
    lock_written_sources = parse_bool(options["lock-written-sources"])
    write_result_path = isempty(options["write-result-path"]) ? DEFAULT_WRITE_RESULT : options["write-result-path"]
    written_sources = lock_written_sources ? write_result_source_urns(write_result_path) : Set{String}()
    plan = plan_time_fabric_projection(
        artifact;
        contract_urn=options["contract-urn"],
        channel_urn=options["channel-urn"],
        anchor_t=parse(Int, options["anchor-t"]),
        t0_date=Date(options["t0-date"]),
        max_events=parse(Int, options["max-events"]),
        scope_artifact_path=options["scope-artifact"],
        written_source_urns=written_sources,
        write_result_path=write_result_path,
        base_url=options["base-url"],
    )
    write_json(options["out"], plan)
    write_markdown(options["markdown-out"], plan)
    println("Wrote Calendar time-fabric plan: ", options["out"])
    println("Wrote Calendar time-fabric report: ", options["markdown-out"])
    println("Events: ", plan["event_count"])
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(CalendarTimeFabricProjection.main())
end
