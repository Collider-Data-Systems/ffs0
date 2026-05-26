#!/usr/bin/env julia

module T206KeepMVPDelivery

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_OUT = "tmp/projections/session_pipeline/keep_t206/t206_keep_mvp_delivery.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/keep_t206/t206_keep_mvp_delivery.md"
const DEFAULT_PROGRAM_OUT = "dev/scripts/ops/t206-keep-api-mvp-delivery.program.json"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:vscode.hp-laptop.copilot"
const DEFAULT_KERNEL_URN = "urn:moos:kernel:hp-laptop.primary"
const CREATED_AT = "2026-05-26T19:15:00Z"

const KEEP_CHANNEL = "urn:moos:channel:google.keep.sam"
const BIG_PROGRAM = "urn:moos:program:sam.t194-t300.big-sprint-session-topology"
const S0_STAGING_SESSION = "urn:moos:session:sam.t200plus-s0-staging"
const CALENDAR_READBACK_SESSION = "urn:moos:session:sam.t200plus-calendar-readback"

const T206_PROGRAM = "urn:moos:program:sam.t206.keep-api-mvp-delivery"
const T206_KI = "urn:moos:ki:gdrive.t206-keep-api-mvp-status"
const T206_DERIVATION = "urn:moos:derivation:guido.t206-keep-api-mvp-readback"
const T206_EXTERNAL_OP = "urn:moos:external_op:sam.t206-google-keep-oauth-scope-approval"

const T206_CLAIMS = [
    Dict(
        "urn" => "urn:moos:claim:t206-keep.oauth-scope-blocked",
        "text" => "Google rejected the requested Keep readonly OAuth scope for the current OAuth client with invalid_scope, even though the public Keep discovery document lists the scope.",
        "confidence" => 0.95,
    ),
    Dict(
        "urn" => "urn:moos:claim:t206-keep.raw-notes-not-yet-ingested",
        "text" => "The T195-T206 raw Keep and loose-thought notes are not yet fetched into local reviewable source files; durable ingestion must remain staged until OAuth succeeds or Sam supplies a structured export.",
        "confidence" => 0.93,
    ),
    Dict(
        "urn" => "urn:moos:claim:t206-keep.mvp-carrier-safe-boundary",
        "text" => "A safe T206 MVP can land graph carriers for the Keep API boundary, S0 staging result, projection dashboard, and Google Calendar handoff without asserting raw Keep-note contents.",
        "confidence" => 0.88,
    ),
    Dict(
        "urn" => "urn:moos:claim:t206-keep.macrohard-theme-staged",
        "text" => "Sam's T206 loose-thought theme request points toward manifold compute, Rust, assembly, hardware, distributed hyperware compute, and Macrohard as classification buckets, but those buckets should classify retrieved notes rather than substitute for the source notes.",
        "confidence" => 0.82,
    ),
    Dict(
        "urn" => "urn:moos:claim:t206-keep.wf07-stays-deferred",
        "text" => "The T206 Keep MVP carrier must not apply Calendar source anchors unless anchors/anchor is explicitly declared and runtime-validated as a WF07 port pair.",
        "confidence" => 0.96,
    ),
]

function object_value(obj, name::Symbol, default=nothing)
    if obj isa AbstractDict
        haskey(obj, name) && return obj[name]
        key = string(name)
        return haskey(obj, key) ? obj[key] : default
    end
    try
        haskey(obj, name) && return getproperty(obj, name)
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

function mutable_copy(value)
    if value isa AbstractDict
        return Dict{String, Any}(string(key) => mutable_copy(val) for (key, val) in pairs(value))
    elseif value isa AbstractVector
        return Any[mutable_copy(item) for item in value]
    else
        return value
    end
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function prop(value, mutability::AbstractString="immutable", authority::AbstractString=""; stratum::Integer=2)
    return Dict("value" => value, "mutability" => mutability, "authority_scope" => authority, "stratum_origin" => stratum)
end

function slug(text::AbstractString; limit::Integer=64)
    raw = lowercase(replace(text, r"[^a-zA-Z0-9]+" => "-"))
    raw = strip(raw, ['-'])
    isempty(raw) && (raw = "node")
    return length(raw) > limit ? raw[1:limit] : raw
end

function relation_urn(src::AbstractString, port::AbstractString, tgt::AbstractString; prefix::AbstractString="t206-keep-mvp")
    return string("urn:moos:rel:", prefix, ".", slug(src; limit=38), ".", slug(port; limit=18), ".", slug(tgt; limit=50))
end

function nodes_by_urn(nodes)
    index = Dict{String, Any}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        !isempty(urn) && (index[urn] = node)
    end
    return index
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

function relation_keys(relations)
    keys = Set{String}()
    for rel in relations
        push!(keys, relation_key(rel))
    end
    return keys
end

function add_node(actor::AbstractString, session_urn::AbstractString, urn::AbstractString, type_id::AbstractString, properties)
    return Dict(
        "rewrite_type" => "ADD",
        "actor" => actor,
        "session_urn" => session_urn,
        "node_urn" => urn,
        "type_id" => type_id,
        "properties" => properties,
    )
end

function link(actor::AbstractString, session_urn::AbstractString, wf::AbstractString, src::AbstractString, src_port::AbstractString, tgt::AbstractString, tgt_port::AbstractString; prefix::AbstractString="t206-keep-mvp")
    return Dict(
        "rewrite_type" => "LINK",
        "actor" => actor,
        "session_urn" => session_urn,
        "relation_urn" => relation_urn(src, src_port, tgt; prefix=prefix),
        "rewrite_category" => wf,
        "src_urn" => src,
        "src_port" => src_port,
        "tgt_urn" => tgt,
        "tgt_port" => tgt_port,
    )
end

function node_specs()
    specs = Any[]
    push!(specs, Dict("urn" => T206_PROGRAM, "type_id" => "program", "properties" => Dict(
        "title" => prop("T206 Keep API MVP delivery"),
        "owner_urn" => prop("urn:moos:user:sam"),
        "status" => prop("active", "mutable", "owner"),
        "scope" => prop("Land the reviewed Keep API/OAuth boundary and S0 staging result as HG carriers, regenerate dashboard/visual/Calendar projections, and keep WF07 source anchors deferred until repaired.", "mutable", "owner"),
        "starts_t" => prop(206, "mutable", "owner"),
        "target_t" => prop(206, "mutable", "owner"),
        "created_at" => prop(CREATED_AT),
    )))
    push!(specs, Dict("urn" => T206_KI, "type_id" => "knowledge_item", "properties" => Dict(
        "title" => prop("T206 Keep API MVP status and loose-thought staging boundary"),
        "source_url" => prop("vscode-copilot://session/t206-keep-api-mvp-delivery"),
        "source_type" => prop("gdrive"),
        "language" => prop("en"),
        "retrieved_at" => prop(CREATED_AT),
        "summary" => prop("Reviewed T206 operator evidence: Google Keep API fetcher and dry stager are implemented and tested; Google OAuth currently rejects keep.readonly for the active OAuth project; raw T195-T206 Keep notes are not fetched; MVP delivery proceeds by landing the boundary, staging claims, projections, and Calendar handoff without asserting raw note content.", "mutable", "kernel"),
        "status" => prop("summarized", "mutable", "kernel"),
        "created_at" => prop(CREATED_AT),
        "substrate" => prop("external-channel"),
        "substrate_anchor_urn" => prop(KEEP_CHANNEL),
        "stage_artifact" => prop("tmp/projections/session_pipeline/keep_t206/keep_t195_t206_stage.json"),
        "credential_check_artifact" => prop("tmp/projections/session_pipeline/keep_t206/google_keep_credential_check.json"),
    )))
    push!(specs, Dict("urn" => T206_DERIVATION, "type_id" => "derivation", "properties" => Dict(
        "name" => prop("T206 Keep API MVP readback"),
        "inference_kind" => prop("hand_authored", "mutable", "owner"),
        "stochastic_weights" => prop(Dict("source" => "operator-readback", "temperature" => 0), "mutable", "owner"),
        "confidence" => prop(0.9, "mutable", "owner"),
        "status" => prop("closed", "mutable", "kernel"),
        "owner_urn" => prop("urn:moos:user:sam"),
        "created_at" => prop(CREATED_AT),
    )))
    for claim in T206_CLAIMS
        push!(specs, Dict("urn" => claim["urn"], "type_id" => "claim", "properties" => Dict(
            "text" => prop(claim["text"]),
            "confidence" => prop(claim["confidence"], "mutable", "kernel"),
            "source_ki_urn" => prop(T206_KI),
            "created_at" => prop(CREATED_AT),
        )))
    end
    push!(specs, Dict("urn" => T206_EXTERNAL_OP, "type_id" => "external_op", "properties" => Dict(
        "title" => prop("Approve Google Keep OAuth readonly scope"),
        "owner_urn" => prop("urn:moos:user:sam"),
        "created_at" => prop(CREATED_AT),
        "status" => prop("pending", "mutable", "kernel"),
        "deadline_t" => prop(207, "mutable", "owner"),
        "command_hint" => prop("In Google Cloud Console, enable Google Keep API, add https://www.googleapis.com/auth/keep.readonly to OAuth consent scopes, add Sam as test user or verify/publish as required, then rerun google_keep_fetch.jl --mode auth-listen.", "mutable", "owner"),
        "responsible_urn" => prop("urn:moos:user:sam", "mutable", "owner"),
        "automates_via_urn" => prop(T206_PROGRAM, "mutable", "owner"),
        "note" => prop("Blocks direct Google Keep API fetch; does not block the reviewed T206 MVP carrier/projection delivery.", "mutable", "owner"),
    )))
    return specs
end

function link_if_needed!(envelopes, existing_keys::Set{String}, planned_keys::Set{String}, node_index, planned_nodes::Set{String}, actor::AbstractString, session_urn::AbstractString, wf::AbstractString, src::AbstractString, src_port::AbstractString, tgt::AbstractString, tgt_port::AbstractString; prefix::AbstractString="t206-keep-mvp")
    (haskey(node_index, src) || src in planned_nodes) || return false
    (haskey(node_index, tgt) || tgt in planned_nodes) || return false
    probe = Dict("rewrite_category" => wf, "src_urn" => src, "src_port" => src_port, "tgt_urn" => tgt, "tgt_port" => tgt_port)
    key = relation_key(probe)
    key in existing_keys && return false
    key in planned_keys && return false
    push!(planned_keys, key)
    push!(envelopes, link(actor, session_urn, wf, src, src_port, tgt, tgt_port; prefix=prefix))
    return true
end

function build_envelopes(nodes, relations; actor_urn::AbstractString=DEFAULT_ACTOR_URN, session_urn::AbstractString=DEFAULT_SESSION_URN, kernel_urn::AbstractString=DEFAULT_KERNEL_URN)
    node_index = nodes_by_urn(nodes)
    existing_keys = relation_keys(relations)
    planned_keys = Set{String}()
    planned_nodes = Set{String}()
    envelopes = Any[]
    skipped_nodes = Any[]

    for spec in node_specs()
        urn = string(spec["urn"])
        if haskey(node_index, urn)
            push!(skipped_nodes, Dict("urn" => urn, "reason" => "already exists"))
            continue
        end
        push!(planned_nodes, urn)
        push!(envelopes, add_node(actor_urn, session_urn, urn, string(spec["type_id"]), spec["properties"]))
    end

    link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, actor_urn, session_urn, "WF12", KEEP_CHANNEL, "provides-kb", T206_KI, "kb-source")
    link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, actor_urn, session_urn, "WF18", BIG_PROGRAM, "composes", T206_PROGRAM, "composed-by")
    link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, actor_urn, session_urn, "WF18", T206_PROGRAM, "composes", T206_KI, "composed-by")
    link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, actor_urn, session_urn, "WF21", T206_KI, "causes", T206_DERIVATION, "caused-by")
    link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, actor_urn, session_urn, "WF21", T206_DERIVATION, "causes", T206_PROGRAM, "caused-by")

    for claim in T206_CLAIMS
        claim_urn = claim["urn"]
        link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, actor_urn, session_urn, "WF12", T206_KI, "provides-kb", claim_urn, "kb-source")
        link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, actor_urn, session_urn, "WF21", T206_DERIVATION, "causes", claim_urn, "caused-by")
    end

    for urn in vcat([T206_PROGRAM, T206_DERIVATION, T206_KI, T206_EXTERNAL_OP], [claim["urn"] for claim in T206_CLAIMS])
        link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, kernel_urn, session_urn, "WF19", session_urn, "pins-urn", urn, "pinned-by-session")
    end
    for pin_session in [S0_STAGING_SESSION, CALENDAR_READBACK_SESSION]
        for urn in [T206_PROGRAM, T206_KI, T206_EXTERNAL_OP]
            link_if_needed!(envelopes, existing_keys, planned_keys, node_index, planned_nodes, kernel_urn, session_urn, "WF19", pin_session, "pins-urn", urn, "pinned-by-session")
        end
    end

    return envelopes, skipped_nodes
end

function plan_delivery(health, nodes, relations; actor_urn::AbstractString=DEFAULT_ACTOR_URN, session_urn::AbstractString=DEFAULT_SESSION_URN, kernel_urn::AbstractString=DEFAULT_KERNEL_URN)
    envelopes, skipped_nodes = build_envelopes(nodes, relations; actor_urn=actor_urn, session_urn=session_urn, kernel_urn=kernel_urn)
    counts = Dict{String, Int}()
    for env in envelopes
        key = string(env["rewrite_type"])
        counts[key] = get(counts, key, 0) + 1
    end
    return Dict(
        "projection_kind" => "t206_keep_mvp_delivery",
        "mode" => "plan",
        "generated_at" => CREATED_AT,
        "base_url" => DEFAULT_BASE_URL,
        "health" => health,
        "actor_urn" => actor_urn,
        "session_urn" => session_urn,
        "state_counts" => Dict("nodes" => length(nodes), "relations" => length(relations)),
        "new_nodes" => [spec["urn"] for spec in node_specs() if !(spec["urn"] in [row["urn"] for row in skipped_nodes])],
        "skipped_existing_nodes" => skipped_nodes,
        "safe_boundaries" => [
            "No WF07 anchors are emitted.",
            "No raw T195-T206 Keep note contents are asserted before OAuth/export retrieval.",
            "Google Calendar remains an explicit writer boundary after dry projection.",
            "Google Keep OAuth scope approval is modeled as a pending external_op.",
        ],
        "theme_buckets" => ["manifold_compute", "rust_assembly_hardware", "distributed_hyperware_compute", "macrohard", "wf07_calendar_cleanup", "s0_conversation_staging"],
        "apply_candidate" => Dict("program_path" => DEFAULT_PROGRAM_OUT, "envelope_count" => length(envelopes), "envelope_counts" => counts),
        "envelopes" => envelopes,
    )
end

function markdown(plan)
    lines = String[]
    push!(lines, "# T206 Keep API MVP Delivery")
    push!(lines, "")
    push!(lines, "Generated: `$(plan["generated_at"])`")
    health = plan["health"]
    push!(lines, "")
    push!(lines, "Runtime: `$(object_value(health, :status, ""))`, ontology `$(object_value(health, :ontology_version, ""))`, T=$(object_value(health, :t_day, "")), log_len=$(object_value(health, :log_len, ""))")
    push!(lines, "")
    push!(lines, "## Apply Candidate")
    push!(lines, "")
    push!(lines, "- Program path: `$(plan["apply_candidate"]["program_path"])`")
    push!(lines, "- Envelopes: $(plan["apply_candidate"]["envelope_count"])")
    for (key, count) in sort(collect(plan["apply_candidate"]["envelope_counts"]); by=first)
        push!(lines, "- `$key`: $count")
    end
    push!(lines, "")
    push!(lines, "## New Carriers")
    push!(lines, "")
    for urn in plan["new_nodes"]
        push!(lines, "- `$urn`")
    end
    push!(lines, "")
    push!(lines, "## Theme Buckets")
    push!(lines, "")
    for bucket in plan["theme_buckets"]
        push!(lines, "- `$bucket`")
    end
    push!(lines, "")
    push!(lines, "## Safe Boundaries")
    push!(lines, "")
    for boundary in plan["safe_boundaries"]
        push!(lines, "- $boundary")
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
        "approval_basis" => "Sam explicitly requested a T206 MVP that can process/ingest/project the Keep/API/S0 staging lane while respecting pending WF07 and raw Keep-note boundaries.",
        "generated_from" => DEFAULT_OUT,
        "envelopes" => plan["envelopes"],
    )
end

function write_outputs(plan; out_path::AbstractString=DEFAULT_OUT, markdown_out::AbstractString=DEFAULT_MARKDOWN_OUT, program_out::AbstractString=DEFAULT_PROGRAM_OUT)
    write_json(out_path, plan)
    mkpath(dirname(markdown_out))
    write(markdown_out, markdown(plan))
    write_json(program_out, program_record(plan))
    return program_out
end

function mark_applied(program_path::AbstractString; applied_at::AbstractString=string(now(UTC)), log_len_before=nothing, log_len_after=nothing)
    record = mutable_copy(safe_read_json(program_path))
    isempty(record) && error("program record not found: ", program_path)
    record["review_only"] = false
    record["applied"] = true
    record["do_not_reapply"] = true
    record["applied_at"] = applied_at
    log_len_before !== nothing && (record["log_len_before"] = log_len_before)
    log_len_after !== nothing && (record["log_len_after"] = log_len_after)
    write_json(program_path, record)
end

function parse_args(args)
    opts = Dict{String, String}(
        "mode" => "plan",
        "base-url" => DEFAULT_BASE_URL,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "program-out" => DEFAULT_PROGRAM_OUT,
        "session-urn" => DEFAULT_SESSION_URN,
        "actor-urn" => DEFAULT_ACTOR_URN,
        "kernel-urn" => DEFAULT_KERNEL_URN,
        "applied-at" => "",
        "log-len-before" => "",
        "log-len-after" => "",
    )
    i = 1
    while i <= length(args)
        arg = args[i]
        startswith(arg, "--") || error("unexpected argument: ", arg)
        key = arg[3:end]
        haskey(opts, key) || error("unknown option: ", arg)
        i < length(args) || error("missing value for --$key")
        opts[key] = args[i + 1]
        i += 2
    end
    return opts
end

function main(args=ARGS)
    opts = parse_args(args)
    if opts["mode"] == "mark-applied"
        mark_applied(
            opts["program-out"];
            applied_at=isempty(opts["applied-at"]) ? string(now(UTC)) : opts["applied-at"],
            log_len_before=isempty(opts["log-len-before"]) ? nothing : parse(Int, opts["log-len-before"]),
            log_len_after=isempty(opts["log-len-after"]) ? nothing : parse(Int, opts["log-len-after"]),
        )
        println("marked applied: ", opts["program-out"])
        return 0
    elseif opts["mode"] != "plan"
        error("unknown mode: ", opts["mode"])
    end
    health = fetch_json(opts["base-url"], "/healthz")
    nodes = as_array(fetch_json(opts["base-url"], "/state/nodes"))
    relations = as_array(fetch_json(opts["base-url"], "/state/relations"))
    plan = plan_delivery(health, nodes, relations; actor_urn=opts["actor-urn"], session_urn=opts["session-urn"], kernel_urn=opts["kernel-urn"])
    program_path = write_outputs(plan; out_path=opts["out"], markdown_out=opts["markdown-out"], program_out=opts["program-out"])
    println("wrote ", opts["out"])
    println("wrote ", opts["markdown-out"])
    println("wrote ", program_path, " (", plan["apply_candidate"]["envelope_count"], " envelopes)")
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(T206KeepMVPDelivery.main())
end