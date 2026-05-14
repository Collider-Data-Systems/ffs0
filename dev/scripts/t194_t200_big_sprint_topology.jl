#!/usr/bin/env julia

module T194T200BigSprintTopology

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_RECOMMENDATION_PLAN = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json"
const DEFAULT_RECONCILIATION = "tmp/projections/session_pipeline/recommendations/t189_recommendation_reconciliation.json"
const DEFAULT_OUT = "tmp/projections/session_pipeline/topology/t194_t200_big_sprint_topology_audit.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/topology/t194_t200_big_sprint_topology_audit.md"
const DEFAULT_PROGRAM_OUT = "dev/scripts/ops/t194-t200-big-sprint-session-topology.program.json"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:vscode.hp-laptop.copilot"
const DEFAULT_KERNEL_URN = "urn:moos:kernel:hp-laptop.primary"
const CREATED_AT = "2026-05-14T21:45:00Z"

const BIG_PURPOSE = "urn:moos:purpose:sam.t194-t300-hg-topology-solidification"
const BIG_PROGRAM = "urn:moos:program:sam.t194-t300.big-sprint-session-topology"
const BIG_DERIVATION = "urn:moos:derivation:guido.t194-big-sprint-topology-audit"
const BIG_FILTER = "urn:moos:view_filter:sam.t194-t300-big-sprint-session-lens"
const S0_STAGING_PROGRAM = "urn:moos:program:sam.t195.ide-conversation-staging-gate"

const SESSION_LANES = [
    Dict(
        "key" => "calendar-readback",
        "session_urn" => "urn:moos:session:sam.t200plus-calendar-readback",
        "purpose_urn" => "urn:moos:purpose:sam.t200plus-calendar-readback-and-wf07-cleanup",
        "title" => "T200+ Calendar readback and WF07 cleanup",
        "target_state" => "Calendar write results are observed back as dated calendar_event nodes, pinned into the correct review session, with WF07 source anchors held until the operad port pair is repaired.",
        "host_kernel" => DEFAULT_KERNEL_URN,
        "pins" => [
            "urn:moos:channel:google.calendar.sam",
            "urn:moos:program:sam.t189.calendar-event-g-ingest-shape",
            "urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision",
            "urn:moos:view_filter:sam.t189-time-fabric-session-lens",
        ],
        "mounts" => ["urn:moos:agent:claude-cowork.hp-laptop"],
    ),
    Dict(
        "key" => "project-bridge",
        "session_urn" => "urn:moos:session:sam.t200plus-project-bridge",
        "purpose_urn" => "urn:moos:purpose:sam.t200plus-github-project-bridge",
        "title" => "T200+ GitHub Project identity bridge",
        "target_state" => "Project #4 is repaired as an HG-identity control surface before any board status becomes a candidate HG MUTATE.",
        "host_kernel" => DEFAULT_KERNEL_URN,
        "pins" => [
            "urn:moos:channel:github.collider-data-systems",
            "urn:moos:channel:github.project.mo-os",
            "urn:moos:program:sam.t189.github-project-urn-refresh",
            "urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence",
        ],
        "mounts" => ["urn:moos:agent:vscode.hp-laptop.copilot"],
    ),
    Dict(
        "key" => "s0-staging",
        "session_urn" => "urn:moos:session:sam.t200plus-s0-staging",
        "purpose_urn" => "urn:moos:purpose:sam.t200plus-s0-conversation-staging",
        "title" => "T200+ S0 conversation staging gate",
        "target_state" => "Pinned IDE conversations and debug logs are staged with stable keys, compared to folded HG, and promoted only as reviewed knowledge_item, claim, derivation, purpose, program, or view_filter nodes.",
        "host_kernel" => DEFAULT_KERNEL_URN,
        "pins" => [
            DEFAULT_SESSION_URN,
            DEFAULT_ACTOR_URN,
            S0_STAGING_PROGRAM,
            BIG_PROGRAM,
        ],
        "mounts" => ["urn:moos:agent:vscode.hp-laptop.copilot"],
    ),
    Dict(
        "key" => "application-surface-map",
        "session_urn" => "urn:moos:session:sam.t200plus-application-surface-map",
        "purpose_urn" => "urn:moos:purpose:sam.t200plus-application-surface-map",
        "title" => "T200+ application surface map",
        "target_state" => "my-tiny-data-collider is modeled as an HG application group with websites, DNS, GitHub, Calendar, Workspace, and server surfaces separated from runtime repos.",
        "host_kernel" => DEFAULT_KERNEL_URN,
        "pins" => [
            "urn:moos:group:my-tiny-data-collider",
            "urn:moos:purpose:sam.my-tiny-data-collider-application",
            "urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider",
            "urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence",
        ],
        "mounts" => ["urn:moos:agent:vscode.hp-laptop.copilot", "urn:moos:agent:vscode.hpprodesk.primary"],
    ),
    Dict(
        "key" => "z440-rejoin",
        "session_urn" => "urn:moos:session:sam.t200plus-z440-rejoin",
        "purpose_urn" => "urn:moos:purpose:sam.t200plus-z440-rejoin-and-delegation",
        "title" => "T200+ Z440 rejoin and delegation",
        "target_state" => "Z440 is rejoined through readback first, then longer-running HDC, GPU, DX, and diary lanes are delegated to the existing workstation/persona sessions with explicit pins and emit-target checks.",
        "host_kernel" => "urn:moos:kernel:hp-z440.primary",
        "pins" => [
            "urn:moos:workflow:z440-session-continuity-reconciliation",
            "urn:moos:session:sam.kernel-proper",
            "urn:moos:session:sam.steinberger-seat",
            "urn:moos:session:sam.karpathy-seat",
            "urn:moos:session:sam.moos-diary",
            "urn:moos:session:sam.z440-cowork-workspace",
        ],
        "mounts" => ["urn:moos:agent:claude-code.hp-z440", "urn:moos:agent:vscode.hp-z440.menno", "urn:moos:agent:vscode.hp-z440.lola", "urn:moos:agent:antigravity.hp-z440"],
    ),
]

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

function as_array(value)
    value === nothing && return Any[]
    value isa AbstractString && return Any[value]
    try
        return collect(value)
    catch
        return Any[]
    end
end

function prop_value(node, name::Symbol, default=nothing)
    props = object_value(node, :properties, nothing)
    props === nothing && return default
    record = object_value(props, name, nothing)
    record === nothing && return default
    value = object_value(record, :value, nothing)
    return value === nothing ? default : value
end

function node_title(node)
    for field in (:title, :name, :summary, :target_state, :description, :status)
        value = prop_value(node, field, nothing)
        if value !== nothing && !isempty(strip(string(value)))
            text = string(value)
            return length(text) > 120 ? string(text[1:120], "...") : text
        end
    end
    return string(object_value(node, :urn, "<unknown>"))
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

read_json(path::AbstractString) = JSON3.read(read(path, String))

function safe_read_json(path::AbstractString)
    isfile(path) || return Dict{String, Any}()
    try
        return read_json(path)
    catch
        return Dict{String, Any}()
    end
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function nodes_by_urn(nodes)
    result = Dict{String, Any}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        !isempty(urn) && (result[urn] = node)
    end
    return result
end

function relation_key(rel)
    return join([
        string(object_value(rel, :rewrite_category, "")),
        string(object_value(rel, :src_urn, "")),
        string(object_value(rel, :src_port, "")),
        string(object_value(rel, :tgt_urn, "")),
        string(object_value(rel, :tgt_port, "")),
    ], "|")
end

function relation_indexes(relations)
    by_urn = Set{String}()
    by_key = Set{String}()
    for rel in relations
        urn = string(object_value(rel, :urn, ""))
        !isempty(urn) && push!(by_urn, urn)
        push!(by_key, relation_key(rel))
    end
    return by_urn, by_key
end

function node_summary(node)
    return Dict(
        "urn" => string(object_value(node, :urn, "")),
        "type_id" => string(object_value(node, :type_id, "")),
        "title" => node_title(node),
        "status" => string(prop_value(node, :status, "")),
        "local_t" => prop_value(node, :local_t, nothing),
    )
end

function compact_relation(rel)
    return Dict(
        "urn" => string(object_value(rel, :urn, "")),
        "rewrite_category" => string(object_value(rel, :rewrite_category, "")),
        "src_urn" => string(object_value(rel, :src_urn, "")),
        "src_port" => string(object_value(rel, :src_port, "")),
        "tgt_urn" => string(object_value(rel, :tgt_urn, "")),
        "tgt_port" => string(object_value(rel, :tgt_port, "")),
    )
end

function incident_relations(relations, urn::AbstractString)
    [rel for rel in relations if string(object_value(rel, :src_urn, "")) == urn || string(object_value(rel, :tgt_urn, "")) == urn]
end

function relation_targets(relations, urn::AbstractString, port::AbstractString)
    [string(object_value(rel, :tgt_urn, "")) for rel in relations if string(object_value(rel, :src_urn, "")) == urn && string(object_value(rel, :src_port, "")) == port]
end

function relation_sources(relations, urn::AbstractString, port::AbstractString)
    [string(object_value(rel, :src_urn, "")) for rel in relations if string(object_value(rel, :tgt_urn, "")) == urn && string(object_value(rel, :tgt_port, "")) == port]
end

function session_summary(session, relations)
    urn = string(object_value(session, :urn, ""))
    opens_on = relation_targets(relations, urn, "opens-on")
    occupants = relation_targets(relations, urn, "has-occupant")
    purposes = relation_targets(relations, urn, "has-purpose")
    pins = relation_targets(relations, urn, "pins-urn")
    filters = relation_targets(relations, urn, "filtered-by")
    mounts = relation_targets(relations, urn, "mounts-tool")
    owners = relation_sources(relations, urn, "owned-by")
    status = string(prop_value(session, :status, ""))
    issues = String[]
    isempty(opens_on) && push!(issues, "missing opens-on")
    isempty(purposes) && push!(issues, "missing has-purpose")
    if status == "abandoned" && (!isempty(occupants) || !isempty(pins) || !isempty(purposes))
        push!(issues, "deprecated scalar status conflicts with relation-derived liveness")
    end
    return Dict(
        "urn" => urn,
        "status" => status,
        "local_t" => prop_value(session, :local_t, nothing),
        "opens_on" => opens_on,
        "occupants" => occupants,
        "purposes" => purposes,
        "pin_count" => length(pins),
        "pins" => pins,
        "filters" => filters,
        "mounts" => mounts,
        "owners" => owners,
        "issues" => issues,
    )
end

function matching_nodes(nodes, type_ids::Vector{String}, pattern::Regex)
    result = Any[]
    for node in nodes
        type_id = string(object_value(node, :type_id, ""))
        type_id in type_ids || continue
        urn = string(object_value(node, :urn, ""))
        text = string(urn, " ", node_title(node), " ", prop_value(node, :scope, ""), " ", prop_value(node, :target_state, ""))
        occursin(pattern, text) && push!(result, node_summary(node))
    end
    sort!(result; by=row -> (row["type_id"], row["urn"]))
    return result
end

function relation_neighborhood(nodes, relations, pattern::Regex; limit::Integer=180)
    focus = Set{String}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        text = string(urn, " ", node_title(node), " ", prop_value(node, :scope, ""), " ", prop_value(node, :target_state, ""))
        occursin(pattern, text) && push!(focus, urn)
    end
    rows = [compact_relation(rel) for rel in relations if string(object_value(rel, :src_urn, "")) in focus || string(object_value(rel, :tgt_urn, "")) in focus]
    sort!(rows; by=row -> (row["rewrite_category"], row["src_urn"], row["tgt_urn"], row["src_port"]))
    return rows[1:min(length(rows), limit)]
end

function prop(value, mutability::AbstractString="immutable", authority::AbstractString=""; stratum::Integer=2)
    return Dict("value" => value, "mutability" => mutability, "authority_scope" => authority, "stratum_origin" => stratum)
end

function slug(text::AbstractString; limit::Integer=72)
    raw = lowercase(replace(text, r"[^a-zA-Z0-9]+" => "-"))
    raw = strip(raw, ['-'])
    isempty(raw) && (raw = "node")
    return length(raw) > limit ? raw[1:limit] : raw
end

function relation_urn(src::AbstractString, port::AbstractString, tgt::AbstractString; prefix::AbstractString="t194-t200")
    return string("urn:moos:rel:", prefix, ".", slug(src; limit=42), ".", slug(port; limit=20), ".", slug(tgt; limit=54))
end

function add_node(actor::AbstractString, session_urn::AbstractString, urn::AbstractString, type_id::AbstractString, properties::AbstractDict)
    return Dict(
        "rewrite_type" => "ADD",
        "actor" => actor,
        "session_urn" => session_urn,
        "node_urn" => urn,
        "type_id" => type_id,
        "properties" => properties,
    )
end

function link(actor::AbstractString, relation_urn_value::AbstractString, wf::AbstractString, src::AbstractString, src_port::AbstractString, tgt::AbstractString, tgt_port::AbstractString)
    return Dict(
        "rewrite_type" => "LINK",
        "actor" => actor,
        "relation_urn" => relation_urn_value,
        "rewrite_category" => wf,
        "src_urn" => src,
        "src_port" => src_port,
        "tgt_urn" => tgt,
        "tgt_port" => tgt_port,
    )
end

function link_if_needed!(envelopes, existing_rel_keys::Set{String}, planned_rel_keys::Set{String}, node_index::Dict{String, Any}, planned_nodes::Set{String}, actor::AbstractString, wf::AbstractString, src::AbstractString, src_port::AbstractString, tgt::AbstractString, tgt_port::AbstractString; prefix::AbstractString="t194-t200")
    (haskey(node_index, src) || src in planned_nodes) || return false
    (haskey(node_index, tgt) || tgt in planned_nodes) || return false
    probe = Dict("rewrite_category" => wf, "src_urn" => src, "src_port" => src_port, "tgt_urn" => tgt, "tgt_port" => tgt_port)
    key = relation_key(probe)
    key in existing_rel_keys && return false
    key in planned_rel_keys && return false
    push!(planned_rel_keys, key)
    push!(envelopes, link(actor, relation_urn(src, src_port, tgt; prefix=prefix), wf, src, src_port, tgt, tgt_port))
    return true
end

function calendar_node_properties(candidate)
    props = object_value(candidate, :properties, Dict())
    return Dict(
        "summary" => prop(string(object_value(props, :summary, ""))),
        "date" => prop(string(object_value(props, :date, ""))),
        "t_day" => prop(Int(object_value(props, :t_day, 0))),
        "gcal_id" => prop(string(object_value(props, :gcal_id, ""))),
        "color_label" => prop(string(object_value(props, :color_label, "gray"))),
        "status" => prop(string(object_value(props, :status, "tentative")), "mutable", "kernel"),
        "created_at" => prop(CREATED_AT),
    )
end

function base_node_specs()
    specs = Any[]
    push!(specs, Dict("urn" => BIG_PURPOSE, "type_id" => "purpose", "properties" => Dict(
        "subject_urn" => prop("urn:moos:user:sam"),
        "target_state" => prop("Solidify the T187/T189/T200+ projection family into scoped sessions, applied Calendar observations, S0 staging gates, and delegable workstation lanes while preserving the rule that chat and external surfaces are evidence, not truth."),
        "status" => prop("open", "mutable", "owner"),
        "started_at" => prop(CREATED_AT),
    )))
    push!(specs, Dict("urn" => BIG_PROGRAM, "type_id" => "program", "properties" => Dict(
        "title" => prop("T194-T300 big sprint session topology"),
        "owner_urn" => prop("urn:moos:user:sam"),
        "status" => prop("active", "mutable", "owner"),
        "scope" => prop("Read moos-diary/program/session/derivation/KI/claim neighborhoods, apply safe Calendar readback pins, and split the T200+ continuation into scoped delegable session lanes.", "mutable", "owner"),
        "starts_t" => prop(194, "mutable", "owner"),
        "target_t" => prop(200, "mutable", "owner"),
        "created_at" => prop(CREATED_AT),
    )))
    push!(specs, Dict("urn" => BIG_DERIVATION, "type_id" => "derivation", "properties" => Dict(
        "name" => prop("T194 big sprint topology audit"),
        "inference_kind" => prop("hand_authored", "mutable", "owner"),
        "confidence" => prop(0.9, "mutable", "owner"),
        "status" => prop("closed", "mutable", "kernel"),
        "owner_urn" => prop("urn:moos:user:sam"),
        "created_at" => prop(CREATED_AT),
    )))
    push!(specs, Dict("urn" => BIG_FILTER, "type_id" => "view_filter", "properties" => Dict(
        "name" => prop("T194-T300 big sprint session lens"),
        "owner_urn" => prop("urn:moos:user:sam"),
        "predicate" => prop(Dict(
            "filter_type" => "any_of",
            "predicates" => [
                Dict("predicate_type" => "on_type", "type_ids" => ["session", "purpose", "program", "derivation", "knowledge_item", "claim", "calendar_event", "channel", "agent", "group", "view_filter"]),
                Dict("predicate_type" => "on_relation", "rewrite_categories" => ["WF01", "WF02", "WF12", "WF18", "WF19", "WF21"]),
            ],
        ), "mutable", "owner"),
        "status" => prop("active", "mutable", "owner"),
        "created_at" => prop(CREATED_AT),
    )))
    push!(specs, Dict("urn" => S0_STAGING_PROGRAM, "type_id" => "program", "properties" => Dict(
        "title" => prop("IDE conversation staging gate"),
        "owner_urn" => prop("urn:moos:user:sam"),
        "status" => prop("draft", "mutable", "owner"),
        "scope" => prop("Generate ignored staging keys for VS Code/Copilot transcripts and promote only reviewed chunks into HG carriers after comparing against folded state.", "mutable", "owner"),
        "starts_t" => prop(195, "mutable", "owner"),
        "target_t" => prop(200, "mutable", "owner"),
        "created_at" => prop(CREATED_AT),
    )))
    for lane in SESSION_LANES
        push!(specs, Dict("urn" => lane["purpose_urn"], "type_id" => "purpose", "properties" => Dict(
            "subject_urn" => prop("urn:moos:user:sam"),
            "target_state" => prop(lane["target_state"]),
            "status" => prop("open", "mutable", "owner"),
            "started_at" => prop(CREATED_AT),
        )))
        push!(specs, Dict("urn" => lane["session_urn"], "type_id" => "session", "properties" => Dict(
            "started_at" => prop(CREATED_AT),
            "status" => prop("active", "mutable", "kernel"),
            "local_t" => prop(0, "mutable", "kernel"),
            "owner_urn" => prop("urn:moos:user:sam"),
        )))
    end
    return specs
end

function pending_calendar_nodes(recommendation_plan, reconciliation, node_index::Dict{String, Any})
    statuses = Dict{String, String}()
    for row in as_array(object_value(reconciliation, :nodes, Any[]))
        statuses[string(object_value(row, :urn, ""))] = string(object_value(row, :status, ""))
    end
    result = Any[]
    for node in as_array(object_value(recommendation_plan, :candidate_nodes, Any[]))
        string(object_value(node, :type_id, "")) == "calendar_event" || continue
        urn = string(object_value(node, :urn, ""))
        haskey(node_index, urn) && continue
        if get(statuses, urn, "pending") == "pending"
            push!(result, node)
        end
    end
    sort!(result; by=node -> string(object_value(node, :urn, "")))
    return result
end

function build_envelopes(nodes, relations, recommendation_plan, reconciliation; actor_urn::AbstractString=DEFAULT_ACTOR_URN, session_urn::AbstractString=DEFAULT_SESSION_URN, kernel_urn::AbstractString=DEFAULT_KERNEL_URN)
    node_index = nodes_by_urn(nodes)
    _, existing_rel_keys = relation_indexes(relations)
    planned_rel_keys = Set{String}()
    envelopes = Any[]
    planned_nodes = Set{String}()
    skipped_nodes = Any[]

    for spec in base_node_specs()
        urn = string(spec["urn"])
        if haskey(node_index, urn)
            push!(skipped_nodes, Dict("urn" => urn, "reason" => "already exists"))
            continue
        end
        push!(planned_nodes, urn)
        push!(envelopes, add_node(actor_urn, session_urn, urn, string(spec["type_id"]), spec["properties"]))
    end

    calendar_nodes = pending_calendar_nodes(recommendation_plan, reconciliation, node_index)
    for candidate in calendar_nodes
        urn = string(object_value(candidate, :urn, ""))
        push!(planned_nodes, urn)
        push!(envelopes, add_node(actor_urn, session_urn, urn, "calendar_event", calendar_node_properties(candidate)))
    end

    # Ownership and governance-scope pins.
    for urn in collect(planned_nodes)
        if startswith(urn, "urn:moos:purpose:") || startswith(urn, "urn:moos:program:") || startswith(urn, "urn:moos:session:")
            link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF01", "urn:moos:group:sam", "owns", urn, "owned-by")
        end
    end
    for urn in [BIG_PURPOSE, BIG_PROGRAM, BIG_DERIVATION, BIG_FILTER]
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", session_urn, "pins-urn", urn, "pinned-by-session")
    end
    link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", session_urn, "filtered-by", BIG_FILTER, "filters-session")
    link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, actor_urn, "WF18", BIG_PURPOSE, "composes", BIG_PROGRAM, "composed-by")
    link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, actor_urn, "WF18", BIG_PROGRAM, "composes", S0_STAGING_PROGRAM, "composed-by")
    link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, actor_urn, "WF21", BIG_DERIVATION, "causes", BIG_PROGRAM, "caused-by")

    for lane in SESSION_LANES
        lane_session = lane["session_urn"]
        lane_purpose = lane["purpose_urn"]
        host_kernel = lane["host_kernel"]
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, actor_urn, "WF18", BIG_PURPOSE, "composes", lane_purpose, "composed-by")
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, actor_urn, "WF18", BIG_PROGRAM, "composes", lane_session, "composed-by")
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", session_urn, "pins-urn", lane_session, "pinned-by-session")
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", lane_session, "opens-on", host_kernel, "occupied-by")
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", lane_session, "has-purpose", lane_purpose, "purpose-of-session")
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", lane_session, "filtered-by", BIG_FILTER, "filters-session")
        for pin in lane["pins"]
            link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", lane_session, "pins-urn", pin, "pinned-by-session")
        end
        for mount in lane["mounts"]
            link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", lane_session, "mounts-tool", mount, "tool-mounted-in-session")
        end
    end

    calendar_session = "urn:moos:session:sam.t200plus-calendar-readback"
    for candidate in calendar_nodes
        urn = string(object_value(candidate, :urn, ""))
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", session_urn, "pins-urn", urn, "pinned-by-session"; prefix="t194-calendar")
        link_if_needed!(envelopes, existing_rel_keys, planned_rel_keys, node_index, planned_nodes, kernel_urn, "WF19", calendar_session, "pins-urn", urn, "pinned-by-session"; prefix="t194-calendar-lane")
    end

    return envelopes, calendar_nodes, skipped_nodes
end

function plan_topology(health, nodes, relations, recommendation_plan, reconciliation; actor_urn::AbstractString=DEFAULT_ACTOR_URN, session_urn::AbstractString=DEFAULT_SESSION_URN, kernel_urn::AbstractString=DEFAULT_KERNEL_URN)
    pattern = r"t187|t188|t189|t190|t193|t194|t195|t200|t300|projection|calendar|surface|github|cytoscape|conversation|session|z440|my-tiny-data-collider"i
    sessions = [session_summary(node, relations) for node in nodes if string(object_value(node, :type_id, "")) == "session"]
    sort!(sessions; by=row -> row["urn"])
    programs = matching_nodes(nodes, ["program"], pattern)
    purposes = matching_nodes(nodes, ["purpose"], pattern)
    carriers = matching_nodes(nodes, ["derivation", "knowledge_item", "claim"], pattern)
    relation_rows = relation_neighborhood(nodes, relations, pattern)
    envelopes, calendar_nodes, skipped_nodes = build_envelopes(nodes, relations, recommendation_plan, reconciliation; actor_urn=actor_urn, session_urn=session_urn, kernel_urn=kernel_urn)
    envelope_counts = Dict{String, Int}()
    for env in envelopes
        key = string(env["rewrite_type"])
        envelope_counts[key] = get(envelope_counts, key, 0) + 1
    end
    return Dict(
        "projection_kind" => "t194_t200_big_sprint_topology_audit",
        "mode" => "plan",
        "generated_at" => CREATED_AT,
        "health" => health,
        "base_url" => DEFAULT_BASE_URL,
        "actor_urn" => actor_urn,
        "session_urn" => session_urn,
        "state_counts" => Dict("nodes" => length(nodes), "relations" => length(relations)),
        "sessions" => sessions,
        "matching_programs" => programs,
        "matching_purposes" => purposes,
        "matching_carriers" => carriers,
        "relation_neighborhood" => relation_rows,
        "pending_calendar_event_count" => length(calendar_nodes),
        "pending_calendar_event_urns" => [string(object_value(node, :urn, "")) for node in calendar_nodes],
        "session_lanes" => SESSION_LANES,
        "apply_candidate" => Dict(
            "program_path" => DEFAULT_PROGRAM_OUT,
            "envelope_count" => length(envelopes),
            "envelope_counts" => envelope_counts,
            "skipped_existing_nodes" => skipped_nodes,
            "safe_boundaries" => [
                "WF07 Calendar source anchors stay deferred.",
                "New delegable sessions are scoped and pinned but intentionally left without has-occupant relations.",
                "Z440 rejoin lane is topology/staging only while the router reports the Z440 peer down.",
            ],
        ),
        "envelopes" => envelopes,
    )
end

function markdown(plan)
    lines = String[]
    push!(lines, "# T194/T200 Big Sprint Topology Audit")
    push!(lines, "")
    push!(lines, "Generated: `$(plan["generated_at"])`")
    health = plan["health"]
    push!(lines, "")
    push!(lines, "Runtime: `$(object_value(health, :status, ""))`, ontology `$(object_value(health, :ontology_version, ""))`, T=$(object_value(health, :t_day, "")), log_len=$(object_value(health, :log_len, ""))")
    push!(lines, "")
    push!(lines, "## Inventory")
    push!(lines, "")
    push!(lines, "- State: $(plan["state_counts"]["nodes"]) nodes / $(plan["state_counts"]["relations"]) relations.")
    push!(lines, "- Sessions: $(length(plan["sessions"])).")
    push!(lines, "- Matching programs: $(length(plan["matching_programs"])).")
    push!(lines, "- Matching derivation/KI/claim carriers: $(length(plan["matching_carriers"])).")
    push!(lines, "- Pending Calendar event observations: $(plan["pending_calendar_event_count"]).")
    push!(lines, "")
    push!(lines, "## Session Lanes")
    push!(lines, "")
    for lane in plan["session_lanes"]
        push!(lines, "- `$(lane["session_urn"])` -> `$(lane["purpose_urn"])`: $(lane["title"])")
    end
    push!(lines, "")
    push!(lines, "## Apply Candidate")
    push!(lines, "")
    candidate = plan["apply_candidate"]
    push!(lines, "- Program path: `$(candidate["program_path"])`")
    push!(lines, "- Envelopes: $(candidate["envelope_count"])")
    for (key, count) in sort(collect(candidate["envelope_counts"]); by=first)
        push!(lines, "- `$key`: $count")
    end
    push!(lines, "")
    push!(lines, "Safe boundaries:")
    for boundary in candidate["safe_boundaries"]
        push!(lines, "- $boundary")
    end
    push!(lines, "")
    push!(lines, "## Session Issues")
    push!(lines, "")
    for session in plan["sessions"]
        issues = session["issues"]
        isempty(issues) && continue
        push!(lines, "- `$(session["urn"])`: $(join(issues, "; "))")
    end
    push!(lines, "")
    push!(lines, "## Pending Calendar Events")
    push!(lines, "")
    for urn in plan["pending_calendar_event_urns"]
        push!(lines, "- `$urn`")
    end
    push!(lines, "")
    return join(lines, "\n")
end

function program_record(plan; applied::Bool=false)
    return Dict(
        "review_only" => !applied,
        "target_url" => "http://localhost:8000/programs",
        "target_kernel" => DEFAULT_KERNEL_URN,
        "persona" => "guido",
        "applied" => applied,
        "do_not_reapply" => applied,
        "approval_basis" => "Sam requested the big sprint to read diary/program/session/derivation/KI/claim state, realize safe pins, and create scoped delegable sessions for the T200+ continuation. This batch applies only safe Calendar observation nodes/pins and idle scoped session topology; WF07 anchors and Z440 live delegation remain deferred.",
        "generated_from" => DEFAULT_OUT,
        "envelopes" => plan["envelopes"],
    )
end

function write_program_record(path::AbstractString, record)
    existing = safe_read_json(path)
    if object_value(existing, :applied, false) == true && object_value(existing, :do_not_reapply, false) == true
        candidate_path = replace(path, ".program.json" => ".candidate.program.json")
        candidate_path == path && (candidate_path = string(path, ".candidate"))
        write_json(candidate_path, record)
        return candidate_path
    end
    write_json(path, record)
    return path
end

function write_outputs(plan; out_path::AbstractString=DEFAULT_OUT, markdown_out::AbstractString=DEFAULT_MARKDOWN_OUT, program_out::AbstractString=DEFAULT_PROGRAM_OUT)
    write_json(out_path, plan)
    mkpath(dirname(markdown_out))
    write(markdown_out, markdown(plan))
    return write_program_record(program_out, program_record(plan))
end

function parse_args(args)
    opts = Dict{String, String}(
        "base-url" => DEFAULT_BASE_URL,
        "recommendation-plan" => DEFAULT_RECOMMENDATION_PLAN,
        "reconciliation" => DEFAULT_RECONCILIATION,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "program-out" => DEFAULT_PROGRAM_OUT,
        "session-urn" => DEFAULT_SESSION_URN,
        "actor-urn" => DEFAULT_ACTOR_URN,
    )
    i = 1
    while i <= length(args)
        arg = args[i]
        if startswith(arg, "--")
            key = arg[3:end]
            i == length(args) && error("missing value for --$key")
            opts[key] = args[i + 1]
            i += 2
        else
            error("unexpected argument: $arg")
        end
    end
    return opts
end

function main(args=ARGS)
    opts = parse_args(args)
    base_url = opts["base-url"]
    health = fetch_json(base_url, "/healthz")
    nodes = as_array(fetch_json(base_url, "/state/nodes"))
    relations = as_array(fetch_json(base_url, "/state/relations"))
    recommendation_plan = safe_read_json(opts["recommendation-plan"])
    reconciliation = safe_read_json(opts["reconciliation"])
    plan = plan_topology(health, nodes, relations, recommendation_plan, reconciliation; actor_urn=opts["actor-urn"], session_urn=opts["session-urn"])
    written_program = write_outputs(plan; out_path=opts["out"], markdown_out=opts["markdown-out"], program_out=opts["program-out"])
    println("wrote ", opts["out"])
    println("wrote ", opts["markdown-out"])
    println("wrote ", written_program, " (", plan["apply_candidate"]["envelope_count"], " envelopes)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end # module