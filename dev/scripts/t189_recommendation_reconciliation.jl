#!/usr/bin/env julia

module T189RecommendationReconciliation

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_RECOMMENDATION_PLAN = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json"
const DEFAULT_OUT = "tmp/projections/session_pipeline/recommendations/t189_recommendation_reconciliation.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/recommendations/t189_recommendation_reconciliation.md"

const GROUPED_SCOPES = Set(["grouped"])
const CALENDAR_SCOPES = Set(["individual-calendar-event"])
const SAFE_GROUPED_WFS = Set(["WF01", "WF18", "WF19", "WF21"])

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

function fetch_json(base_url::AbstractString, path::AbstractString)
    url = string(rstrip(base_url, '/'), "/", lstrip(path, '/'))
    temp_path = Downloads.download(url)
    try
        return JSON3.read(read(temp_path, String))
    finally
        rm(temp_path; force=true)
    end
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
end

function relation_key(relation)
    return join([
        string(object_value(relation, :rewrite_category, "")),
        string(object_value(relation, :src_urn, "")),
        string(object_value(relation, :src_port, "")),
        string(object_value(relation, :tgt_urn, "")),
        string(object_value(relation, :tgt_port, "")),
    ], "|")
end

function node_index(nodes)
    index = Set{String}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        !isempty(urn) && push!(index, urn)
    end
    return index
end

function relation_index(relations)
    index = Set{String}()
    for relation in relations
        push!(index, relation_key(relation))
    end
    return index
end

function classify_node(candidate)
    scope = string(object_value(candidate, :recommendation_scope, ""))
    return scope in GROUPED_SCOPES ? "grouped" : scope in CALENDAR_SCOPES ? "calendar-event" : "other"
end

function classify_relation(candidate)
    status = string(object_value(candidate, :status, "declared"))
    status == "requires-operad-review" && return "deferred"
    target = string(object_value(candidate, :tgt_urn, ""))
    wf = string(object_value(candidate, :rewrite_category, ""))
    startswith(target, "urn:moos:cal:") && return "calendar-event"
    wf in SAFE_GROUPED_WFS && return "grouped-safe"
    return "other"
end

function count_bucket!(counts, bucket::AbstractString, present::Bool)
    total_key = string(bucket, "_total")
    applied_key = string(bucket, "_applied")
    pending_key = string(bucket, "_pending")
    counts[total_key] = get(counts, total_key, 0) + 1
    if present
        counts[applied_key] = get(counts, applied_key, 0) + 1
    else
        counts[pending_key] = get(counts, pending_key, 0) + 1
    end
end

function reconcile(plan, nodes, relations; health=Dict(), generated_at::String=format_utc(now(UTC)), base_url::String=DEFAULT_BASE_URL)
    node_set = node_index(nodes)
    relation_set = relation_index(relations)
    node_rows = Any[]
    relation_rows = Any[]
    counts = Dict{String, Int}()

    for candidate in object_value(plan, :candidate_nodes, Any[])
        urn = string(object_value(candidate, :urn, ""))
        bucket = classify_node(candidate)
        present = urn in node_set
        count_bucket!(counts, string("node_", bucket), present)
        push!(node_rows, Dict(
            "urn" => urn,
            "type_id" => string(object_value(candidate, :type_id, "")),
            "bucket" => bucket,
            "status" => present ? "applied" : "pending",
        ))
    end

    for candidate in object_value(plan, :candidate_relations, Any[])
        bucket = classify_relation(candidate)
        present = relation_key(candidate) in relation_set
        count_bucket!(counts, string("relation_", bucket), present)
        push!(relation_rows, Dict(
            "rewrite_category" => string(object_value(candidate, :rewrite_category, "")),
            "src_urn" => string(object_value(candidate, :src_urn, "")),
            "src_port" => string(object_value(candidate, :src_port, "")),
            "tgt_urn" => string(object_value(candidate, :tgt_urn, "")),
            "tgt_port" => string(object_value(candidate, :tgt_port, "")),
            "bucket" => bucket,
            "status" => present ? "applied" : "pending",
        ))
    end

    deferred_rows = Any[]
    for candidate in object_value(plan, :deferred_relations, Any[])
        push!(deferred_rows, Dict(
            "rewrite_category" => string(object_value(candidate, :rewrite_category, "")),
            "src_urn" => string(object_value(candidate, :src_urn, "")),
            "src_port" => string(object_value(candidate, :src_port, "")),
            "tgt_urn" => string(object_value(candidate, :tgt_urn, "")),
            "tgt_port" => string(object_value(candidate, :tgt_port, "")),
            "status" => "deferred",
            "note" => string(object_value(candidate, :note, "")),
        ))
    end

    counts["deferred_relation_total"] = length(deferred_rows)
    grouped_nodes_ok = get(counts, "node_grouped_total", 0) > 0 && get(counts, "node_grouped_pending", 0) == 0
    grouped_relations_ok = get(counts, "relation_grouped-safe_total", 0) > 0 && get(counts, "relation_grouped-safe_pending", 0) == 0
    calendar_nodes_pending = get(counts, "node_calendar-event_pending", 0)
    deferred_relation_total = get(counts, "deferred_relation_total", 0)

    return Dict(
        "mode" => "plan",
        "projection_kind" => "t189_recommendation_reconciliation",
        "generated_at" => generated_at,
        "base_url" => base_url,
        "health" => health,
        "source_plan" => string(object_value(plan, :projection_kind, "")),
        "summary" => Dict(
            "grouped_nodes_applied" => get(counts, "node_grouped_applied", 0),
            "grouped_nodes_total" => get(counts, "node_grouped_total", 0),
            "grouped_relations_applied" => get(counts, "relation_grouped-safe_applied", 0),
            "grouped_relations_total" => get(counts, "relation_grouped-safe_total", 0),
            "calendar_event_nodes_pending" => calendar_nodes_pending,
            "deferred_relations" => deferred_relation_total,
            "grouped_nodes_ok" => grouped_nodes_ok,
            "grouped_relations_ok" => grouped_relations_ok,
        ),
        "counts" => counts,
        "nodes" => node_rows,
        "relations" => relation_rows,
        "deferred_relations" => deferred_rows,
    )
end

function write_markdown(path::AbstractString, report)
    mkpath(dirname(path))
    summary = report["summary"]
    open(path, "w") do io
        println(io, "# T189 Recommendation Reconciliation")
        println(io)
        println(io, "Generated: ", report["generated_at"])
        println(io, "Base URL: ", report["base_url"])
        println(io)
        println(io, "This is a dry comparison between the T189 recommendation plan and folded HG state. It emits no rewrites.")
        println(io)
        println(io, "## Summary")
        println(io, "- Grouped nodes: ", summary["grouped_nodes_applied"], "/", summary["grouped_nodes_total"], " applied")
        println(io, "- Grouped safe relations: ", summary["grouped_relations_applied"], "/", summary["grouped_relations_total"], " applied")
        println(io, "- Calendar event nodes pending: ", summary["calendar_event_nodes_pending"])
        println(io, "- Deferred relations: ", summary["deferred_relations"])
        println(io)
        println(io, "## Pending Calendar Event Nodes")
        pending = [row for row in report["nodes"] if row["bucket"] == "calendar-event" && row["status"] == "pending"]
        if isempty(pending)
            println(io, "- <none>")
        else
            for row in pending
                println(io, "- `", row["urn"], "`")
            end
        end
        println(io)
        println(io, "## Deferred Relations")
        if isempty(report["deferred_relations"])
            println(io, "- <none>")
        else
            for row in report["deferred_relations"]
                println(io, "- `", row["rewrite_category"], "` ", row["src_port"], " -> ", row["tgt_port"], ": `", row["src_urn"], "` -> `", row["tgt_urn"], "`")
            end
        end
    end
end

function parse_args(argv)
    options = Dict(
        "base-url" => DEFAULT_BASE_URL,
        "recommendation-plan" => DEFAULT_RECOMMENDATION_PLAN,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
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

function load_state(options)
    nodes = isempty(options["nodes-file"]) ? fetch_json(options["base-url"], "/state/nodes") : read_json(options["nodes-file"])
    relations = isempty(options["relations-file"]) ? fetch_json(options["base-url"], "/state/relations") : read_json(options["relations-file"])
    health = isempty(options["health-file"]) ? fetch_json(options["base-url"], "/healthz") : read_json(options["health-file"])
    return nodes, relations, health
end

function main(argv=ARGS)
    options = parse_args(argv)
    plan = read_json(options["recommendation-plan"])
    nodes, relations, health = load_state(options)
    report = reconcile(plan, nodes, relations; health=health, base_url=options["base-url"])
    write_json(options["out"], report)
    write_markdown(options["markdown-out"], report)
    println("Wrote T189 recommendation reconciliation: ", options["out"])
    println("Wrote T189 recommendation reconciliation report: ", options["markdown-out"])
    println("Grouped nodes: ", report["summary"]["grouped_nodes_applied"], "/", report["summary"]["grouped_nodes_total"], " Grouped relations: ", report["summary"]["grouped_relations_applied"], "/", report["summary"]["grouped_relations_total"])
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(T189RecommendationReconciliation.main())
end
