#!/usr/bin/env julia

module KeepT195T206IngestStage

using Dates
using Downloads
using JSON3
using SHA

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_SOURCE = "scratch/keep/t195-t206"
const DEFAULT_OUT = "tmp/projections/session_pipeline/keep_t206/keep_t195_t206_stage.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/keep_t206/keep_t195_t206_stage.md"
const DEFAULT_T0_DATE = Date("2025-11-01")
const DEFAULT_T_START = 195
const DEFAULT_T_END = 206
const DEFAULT_CHANNEL_URN = "urn:moos:channel:google.keep.sam"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:vscode.hp-laptop.copilot"
const DEFAULT_OWNER_URN = "urn:moos:user:sam"
const INGEST_PROGRAM_URN = "urn:moos:program:sam.t206.keep-loose-thought-ingest-stage"
const INGEST_DERIVATION_URN = "urn:moos:derivation:guido.t206-keep-loose-thought-classification"

const SUPPORTED_EXTENSIONS = Set([".json", ".html", ".htm", ".txt", ".md"])

const THEME_KEYWORDS = [
    "manifold_compute" => ["manifold", "surface", "projection", "hyperware", "distributed compute", "distributed", "object operations", "macrohard"],
    "runtime_substrate" => ["rust", "assembly", "assembler", "kernel", "os", "operating system", "go runtime", "hardware", "memory hierarchy"],
    "accelerator_cache" => ["gpu", "cuda", "hdc", "vsa", "vector", "embedding", "cache", "preset", "index", "tensor", "simd"],
    "hg_ontology" => ["ontology", "hypergraph", " hg ", "add", "link", "mutate", "unlink", "relation", "node", "rewrite", "operad", "wf"],
    "session_surface" => ["session", "keep", "loose", "thought", "chat", "conversation", "ide", "vscode", "staging", "cowork"],
    "application_surface" => ["application", "app", "website", "dns", "github", "calendar", "surface", "my-tiny-data-collider", "mtdc"],
]

const ACCESS_PATHS = [
    Dict(
        "id" => "google-takeout",
        "status" => "preferred",
        "summary" => "Export Google Keep through Google Takeout, then point this stager at the Takeout/Keep folder. This avoids local OAuth secrets and works offline after export.",
        "source" => "Google Account Help: How to download your Google data",
    ),
    Dict(
        "id" => "keep-api",
        "status" => "available-but-deferred",
        "summary" => "Google publishes a Keep API, but it requires an explicit OAuth/client setup. Keep this behind the same reviewed writer boundary as Calendar, never inside the staging parser.",
        "source" => "Google Keep API reference",
    ),
    Dict(
        "id" => "manual-export",
        "status" => "fallback",
        "summary" => "A copied note, PDF-to-text extraction, or Drive document can be staged as plain text when Takeout is not ready. Undated notes are marked for review.",
        "source" => "Local operator workflow",
    ),
]

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
end

function t_day_for_date(date::Date; t0_date::Date=DEFAULT_T0_DATE)
    return Dates.value(date - t0_date)
end

function date_for_t_day(t_day::Integer; t0_date::Date=DEFAULT_T0_DATE)
    return t0_date + Day(t_day)
end

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

function as_string(value, default="")
    value === nothing && return default
    text = strip(string(value))
    return isempty(text) ? default : text
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

function html_unescape(text::AbstractString)
    replacements = Dict(
        "&nbsp;" => " ",
        "&amp;" => "&",
        "&lt;" => "<",
        "&gt;" => ">",
        "&quot;" => "\"",
        "&#39;" => "'",
        "&apos;" => "'",
    )
    result = String(text)
    for (src, tgt) in replacements
        result = replace(result, src => tgt)
    end
    while true
        entity = match(r"&#(\d+);", result)
        entity === nothing && break
        result = replace(result, entity.match => string(Char(parse(Int, entity.captures[1]))); count=1)
    end
    while true
        entity = match(r"&#x([0-9A-Fa-f]+);", result)
        entity === nothing && break
        result = replace(result, entity.match => string(Char(parse(Int, entity.captures[1], base=16))); count=1)
    end
    return result
end

function strip_html(text::AbstractString)
    cleaned = replace(String(text), r"(?is)<script.*?</script>" => " ")
    cleaned = replace(cleaned, r"(?is)<style.*?</style>" => " ")
    cleaned = replace(cleaned, r"(?i)<br\s*/?>" => "\n")
    cleaned = replace(cleaned, r"(?i)</(p|div|li|h[1-6])>" => "\n")
    cleaned = replace(cleaned, r"(?s)<[^>]+>" => " ")
    cleaned = html_unescape(cleaned)
    cleaned = replace(cleaned, r"[ \t\r\f]+" => " ")
    cleaned = replace(cleaned, r"\n\s+" => "\n")
    cleaned = replace(cleaned, r"\n{3,}" => "\n\n")
    return strip(cleaned)
end

function slugify(text::AbstractString; fallback="note")
    slug = replace(lowercase(String(text)), r"[^a-z0-9]+" => "-")
    slug = strip(slug, ['-'])
    isempty(slug) && (slug = fallback)
    return length(slug) > 64 ? slug[1:64] : slug
end

function source_url(path::AbstractString)
    normalized = replace(abspath(path), "\\" => "/")
    return string("file://", normalized)
end

function text_hash(text::AbstractString)
    return bytes2hex(sha1(codeunits(String(text))))
end

function preview(text::AbstractString; limit::Integer=360)
    compact = replace(strip(String(text)), r"\s+" => " ")
    return length(compact) > limit ? string(compact[1:limit], "...") : compact
end

function first_nonempty_line(text::AbstractString, fallback::AbstractString)
    for line in split(String(text), '\n')
        stripped = strip(line)
        !isempty(stripped) && return length(stripped) > 96 ? stripped[1:96] : stripped
    end
    return fallback
end

function parse_timestamp(value)
    value === nothing && return nothing
    raw = strip(string(value))
    isempty(raw) && return nothing
    if occursin(r"^\d+(\.\d+)?$", raw)
        numeric = parse(Float64, raw)
        seconds = numeric > 1.0e14 ? numeric / 1.0e6 : (numeric > 1.0e11 ? numeric / 1.0e3 : numeric)
        return unix2datetime(seconds)
    end
    for fmt in (dateformat"yyyy-mm-ddTHH:MM:SS.sZ", dateformat"yyyy-mm-ddTHH:MM:SSZ", dateformat"yyyy-mm-ddTHH:MM:SS", dateformat"yyyy-mm-dd HH:MM:SS")
        try
            return DateTime(raw, fmt)
        catch
        end
    end
    return nothing
end

function explicit_t_day(text::AbstractString)
    found = match(r"(?i)\bT\s*[=:]?\s*(\d{2,4})\b", text)
    found === nothing && return nothing
    return parse(Int, found.captures[1])
end

function date_from_filename(path::AbstractString)
    name = basename(path)
    found = match(r"(20\d\d)[-_ ]?(\d\d)[-_ ]?(\d\d)", name)
    found === nothing && return nothing
    try
        return Date(string(found.captures[1], "-", found.captures[2], "-", found.captures[3]))
    catch
        return nothing
    end
end

function note_temporal(title::AbstractString, text::AbstractString, path::AbstractString, created_at, edited_at; t0_date::Date=DEFAULT_T0_DATE)
    combined = string(title, "\n", text, "\n", basename(path))
    explicit = explicit_t_day(combined)
    if explicit !== nothing
        return Dict("t_day" => explicit, "date" => string(date_for_t_day(explicit; t0_date=t0_date)), "source" => "explicit_t_day")
    end
    timestamp = edited_at !== nothing ? edited_at : created_at
    if timestamp !== nothing
        date = Date(timestamp)
        return Dict("t_day" => t_day_for_date(date; t0_date=t0_date), "date" => string(date), "source" => edited_at !== nothing ? "edited_timestamp" : "created_timestamp")
    end
    filename_date = date_from_filename(path)
    if filename_date !== nothing
        return Dict("t_day" => t_day_for_date(filename_date; t0_date=t0_date), "date" => string(filename_date), "source" => "filename")
    end
    return Dict("t_day" => nothing, "date" => nothing, "source" => "undated")
end

function classify_note(title::AbstractString, text::AbstractString)
    haystack = string(" ", lowercase(title), "\n", lowercase(text), " ")
    scores = Dict{String, Int}()
    for (theme, keywords) in THEME_KEYWORDS
        count = 0
        for keyword in keywords
            occursin(lowercase(keyword), haystack) && (count += 1)
        end
        count > 0 && (scores[theme] = count)
    end
    if isempty(scores)
        scores["loose_thought"] = 1
    end
    themes = sort(collect(keys(scores)); by = key -> (-scores[key], key))
    return Dict("themes" => themes, "scores" => scores)
end

function label_list(value)
    labels = String[]
    for item in as_array(value)
        label = as_string(object_value(item, :name, item), "")
        !isempty(label) && push!(labels, label)
    end
    return labels
end

function note_from_json_object(obj, path::AbstractString; index::Integer=1, t0_date::Date=DEFAULT_T0_DATE)
    title = as_string(object_value(obj, :title, ""), splitext(basename(path))[1])
    text_parts = String[]
    text_content = as_string(object_value(obj, :textContent, ""), "")
    !isempty(text_content) && push!(text_parts, text_content)
    for item in as_array(object_value(obj, :listContent, nothing))
        item_text = as_string(object_value(item, :text, ""), "")
        isempty(item_text) && continue
        checked = object_value(item, :isChecked, false)
        prefix = checked == true || string(checked) == "true" ? "[x]" : "[ ]"
        push!(text_parts, string(prefix, " ", item_text))
    end
    body = strip(join(text_parts, "\n"))
    isempty(body) && (body = title)
    created_at = parse_timestamp(object_value(obj, :createdTimestampUsec, object_value(obj, :createdTimestamp, nothing)))
    edited_at = parse_timestamp(object_value(obj, :userEditedTimestampUsec, object_value(obj, :userEditedTimestamp, nothing)))
    temporal = note_temporal(title, body, path, created_at, edited_at; t0_date=t0_date)
    hash = text_hash(string(title, "\n", body))
    classification = classify_note(title, body)
    source = as_string(object_value(obj, :sourceUrl, object_value(obj, :source_url, "")), "")
    isempty(source) && (source = source_url(path))
    return Dict(
        "id" => string("json-", hash[1:12], "-", index),
        "format" => "json",
        "title" => title,
        "text" => body,
        "text_sha1" => hash,
        "source_path" => abspath(path),
        "source_url" => source,
        "created_at" => created_at === nothing ? nothing : format_utc(created_at),
        "edited_at" => edited_at === nothing ? nothing : format_utc(edited_at),
        "t_day" => temporal["t_day"],
        "date" => temporal["date"],
        "temporal_source" => temporal["source"],
        "labels" => label_list(object_value(obj, :labels, nothing)),
        "themes" => classification["themes"],
        "theme_scores" => classification["scores"],
        "text_preview" => preview(body),
    )
end

function notes_from_json(path::AbstractString; t0_date::Date=DEFAULT_T0_DATE)
    parsed = JSON3.read(read(path, String))
    values = parsed isa AbstractArray ? collect(parsed) : Any[parsed]
    notes = Any[]
    for (index, obj) in enumerate(values)
        push!(notes, note_from_json_object(obj, path; index=index, t0_date=t0_date))
    end
    return notes
end

function notes_from_html(path::AbstractString; t0_date::Date=DEFAULT_T0_DATE)
    raw = read(path, String)
    title_match = match(r"(?is)<title[^>]*>(.*?)</title>", raw)
    h1_match = match(r"(?is)<h1[^>]*>(.*?)</h1>", raw)
    title = title_match !== nothing ? strip_html(title_match.captures[1]) : (h1_match !== nothing ? strip_html(h1_match.captures[1]) : splitext(basename(path))[1])
    body = strip_html(raw)
    isempty(body) && (body = title)
    temporal = note_temporal(title, body, path, nothing, nothing; t0_date=t0_date)
    hash = text_hash(string(title, "\n", body))
    classification = classify_note(title, body)
    return Any[Dict(
        "id" => string("html-", hash[1:12]),
        "format" => "html",
        "title" => title,
        "text" => body,
        "text_sha1" => hash,
        "source_path" => abspath(path),
        "source_url" => source_url(path),
        "created_at" => nothing,
        "edited_at" => nothing,
        "t_day" => temporal["t_day"],
        "date" => temporal["date"],
        "temporal_source" => temporal["source"],
        "labels" => String[],
        "themes" => classification["themes"],
        "theme_scores" => classification["scores"],
        "text_preview" => preview(body),
    )]
end

function notes_from_text(path::AbstractString; t0_date::Date=DEFAULT_T0_DATE)
    body = read(path, String)
    title = first_nonempty_line(body, splitext(basename(path))[1])
    temporal = note_temporal(title, body, path, nothing, nothing; t0_date=t0_date)
    hash = text_hash(string(title, "\n", body))
    classification = classify_note(title, body)
    return Any[Dict(
        "id" => string("text-", hash[1:12]),
        "format" => lowercase(splitext(path)[2]) == ".md" ? "markdown" : "text",
        "title" => title,
        "text" => body,
        "text_sha1" => hash,
        "source_path" => abspath(path),
        "source_url" => source_url(path),
        "created_at" => nothing,
        "edited_at" => nothing,
        "t_day" => temporal["t_day"],
        "date" => temporal["date"],
        "temporal_source" => temporal["source"],
        "labels" => String[],
        "themes" => classification["themes"],
        "theme_scores" => classification["scores"],
        "text_preview" => preview(body),
    )]
end

function discover_files(source::AbstractString)
    ispath(source) || return String[]
    files = isfile(source) ? [source] : [joinpath(root, file) for (root, _, names) in walkdir(source) for file in names]
    supported = String[]
    for path in files
        ext = lowercase(splitext(path)[2])
        ext in SUPPORTED_EXTENSIONS && push!(supported, path)
    end
    return sort(supported)
end

function load_notes(source::AbstractString; t0_date::Date=DEFAULT_T0_DATE)
    notes = Any[]
    skipped = Any[]
    for path in discover_files(source)
        ext = lowercase(splitext(path)[2])
        try
            if ext == ".json"
                append!(notes, notes_from_json(path; t0_date=t0_date))
            elseif ext in [".html", ".htm"]
                append!(notes, notes_from_html(path; t0_date=t0_date))
            elseif ext in [".txt", ".md"]
                append!(notes, notes_from_text(path; t0_date=t0_date))
            end
        catch err
            push!(skipped, Dict("path" => abspath(path), "reason" => sprint(showerror, err)))
        end
    end
    return notes, skipped
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

function load_existing_source_urls(; base_url::AbstractString=DEFAULT_BASE_URL, nodes_file::AbstractString="")
    nodes = isempty(nodes_file) ? fetch_json(base_url, "/state/nodes") : JSON3.read(read(nodes_file, String))
    urls = Set{String}()
    for node in nodes
        string(object_value(node, :type_id, "")) == "knowledge_item" || continue
        url = as_string(prop_value(node, :source_url, ""), "")
        !isempty(url) && push!(urls, url)
    end
    return urls
end

function relation_urn(prefix::AbstractString, src::AbstractString, port::AbstractString, tgt::AbstractString)
    raw = string(prefix, ".", src, ".", port, ".", tgt)
    return string("urn:moos:rel:", slugify(raw; fallback="relation"))
end

function prop(value; mutability="immutable", authority="", stratum=2)
    result = Dict("value" => value, "mutability" => mutability, "stratum_origin" => stratum)
    !isempty(authority) && (result["authority_scope"] = authority)
    return result
end

function candidate_ki(note; channel_urn::String=DEFAULT_CHANNEL_URN, retrieved_at::String=format_utc(now(UTC)))
    t_day = note["t_day"] === nothing ? "undated" : string("t", note["t_day"])
    slug = slugify(string(t_day, "-", note["title"], "-", note["text_sha1"][1:8]))
    return Dict(
        "urn" => string("urn:moos:ki:gdrive.", slug),
        "type_id" => "knowledge_item",
        "properties" => Dict(
            "title" => prop(string("T195-T206 Keep/loose thought :: ", note["title"])),
            "source_url" => prop(note["source_url"]),
            "source_type" => prop("gdrive"),
            "language" => prop("en"),
            "retrieved_at" => prop(retrieved_at),
            "summary" => prop(note["text_preview"]; mutability="mutable", authority="kernel"),
            "status" => prop("raw"; mutability="mutable", authority="kernel"),
            "created_at" => prop(retrieved_at),
            "substrate" => prop("external-channel"; authority="kernel"),
            "substrate_anchor_urn" => prop(channel_urn; authority="kernel"),
        ),
        "source_note_id" => note["id"],
        "review_status" => note["t_day"] === nothing ? "needs_date_review" : "source_structured",
    )
end

function candidate_claims(selected_notes; retrieved_at::String=format_utc(now(UTC)))
    isempty(selected_notes) && return Any[]
    theme_set = Set{String}()
    for note in selected_notes
        for theme in note["themes"]
            push!(theme_set, string(theme))
        end
    end
    claim_specs = [
        ("manifold-compute-surface", "T195-T206 loose thoughts frame mo:os as a manifold object-operations surface: folded HG state remains the durable object, while IDE, Calendar, GitHub, application, and hardware surfaces are projections."),
        ("runtime-substrate-boundary", "Rust, assembly, and host hardware work should be staged as substrate and host-extension design around the current log/fold boundary, not as a blind replacement of graph truth."),
        ("accelerator-cache-contract", "GPU, CUDA, HDC, vector, and preset work belongs in rebuildable derived caches keyed by ontology version, log length, encoder version, and scoped graph identity."),
        ("s0-review-gate", "Keep notes and IDE conversations stay S0 source material until reviewed into knowledge_item, claim, derivation, program, or view_filter candidates."),
    ]
    source_ki = isempty(selected_notes) ? "" : string("urn:moos:ki:gdrive.t195-t206-", selected_notes[1]["text_sha1"][1:8], "-umbrella")
    claims = Any[]
    for (index, (slug, text)) in enumerate(claim_specs)
        push!(claims, Dict(
            "urn" => string("urn:moos:claim:t206.keep-loose-thought.", lpad(index, 2, '0'), ".", slug),
            "type_id" => "claim",
            "properties" => Dict(
                "text" => prop(text),
                "confidence" => prop(0.62; mutability="mutable", authority="kernel"),
                "source_ki_urn" => prop(source_ki),
                "created_at" => prop(retrieved_at),
            ),
            "review_status" => "conceptual_candidate",
            "theme_support" => sort(collect(theme_set)),
        ))
    end
    return claims
end

function candidate_program(retrieved_at::String)
    return Dict(
        "urn" => INGEST_PROGRAM_URN,
        "type_id" => "program",
        "properties" => Dict(
            "title" => prop("T206 Keep/loose-thought ingest and manifold-compute staging"),
            "owner_urn" => prop(DEFAULT_OWNER_URN),
            "status" => prop("draft"; mutability="mutable", authority="owner"),
            "scope" => prop("Structure Sam's T195-T206 Keep notes and loose thoughts into reviewable HG evidence, with hardware/software lingo held as candidate claims until approved."; mutability="mutable", authority="owner"),
            "starts_t" => prop(206; mutability="mutable", authority="owner"),
            "target_t" => prop(206; mutability="mutable", authority="owner"),
            "created_at" => prop(retrieved_at),
        ),
        "review_status" => "candidate_program",
    )
end

function candidate_derivation(retrieved_at::String)
    return Dict(
        "urn" => INGEST_DERIVATION_URN,
        "type_id" => "derivation",
        "properties" => Dict(
            "name" => prop("T206 Keep/loose thought classification"),
            "inference_kind" => prop("hybrid"; mutability="mutable", authority="owner"),
            "stochastic_weights" => prop(Dict("method" => "keyword buckets plus operator review", "apply_boundary" => "dry review only"); mutability="mutable", authority="owner"),
            "confidence" => prop(0.58; mutability="mutable", authority="owner"),
            "status" => prop("open"; mutability="mutable", authority="kernel"),
            "owner_urn" => prop(DEFAULT_OWNER_URN),
            "created_at" => prop(retrieved_at),
        ),
        "review_status" => "candidate_derivation",
    )
end

function candidate_relation(wf::String, src::String, src_port::String, tgt::String, tgt_port::String; prefix="t206-keep-stage")
    return Dict(
        "urn" => relation_urn(prefix, src, src_port, tgt),
        "rewrite_category" => wf,
        "src_urn" => src,
        "src_port" => src_port,
        "tgt_urn" => tgt,
        "tgt_port" => tgt_port,
    )
end

function candidate_hg(selected_notes; channel_urn::String=DEFAULT_CHANNEL_URN, session_urn::String=DEFAULT_SESSION_URN, retrieved_at::String=format_utc(now(UTC)))
    ki_nodes = [candidate_ki(note; channel_urn=channel_urn, retrieved_at=retrieved_at) for note in selected_notes]
    claim_nodes = candidate_claims(selected_notes; retrieved_at=retrieved_at)
    nodes = Any[candidate_program(retrieved_at), candidate_derivation(retrieved_at)]
    append!(nodes, ki_nodes)
    append!(nodes, claim_nodes)

    relations = Any[]
    push!(relations, candidate_relation("WF19", session_urn, "pins-urn", INGEST_PROGRAM_URN, "pinned-by-session"))
    push!(relations, candidate_relation("WF19", session_urn, "pins-urn", INGEST_DERIVATION_URN, "pinned-by-session"))
    push!(relations, candidate_relation("WF18", INGEST_PROGRAM_URN, "composes", channel_urn, "composed-by"))
    for node in ki_nodes
        ki_urn = node["urn"]
        push!(relations, candidate_relation("WF12", channel_urn, "provides-kb", ki_urn, "kb-source"))
        push!(relations, candidate_relation("WF18", INGEST_PROGRAM_URN, "composes", ki_urn, "composed-by"))
        push!(relations, candidate_relation("WF19", session_urn, "pins-urn", ki_urn, "pinned-by-session"))
        push!(relations, candidate_relation("WF21", INGEST_DERIVATION_URN, "causes", ki_urn, "caused-by"))
    end
    for node in claim_nodes
        claim_urn = node["urn"]
        push!(relations, candidate_relation("WF21", INGEST_DERIVATION_URN, "causes", claim_urn, "caused-by"))
    end

    return Dict(
        "apply_ready" => false,
        "apply_boundary" => "review-only: source notes must be structured and approved before this becomes a dev/scripts/ops apply program",
        "actor_urn" => DEFAULT_ACTOR_URN,
        "session_urn" => session_urn,
        "candidate_nodes" => nodes,
        "candidate_relations" => relations,
        "candidate_node_count" => length(nodes),
        "candidate_relation_count" => length(relations),
    )
end

function note_in_range(note, t_start::Integer, t_end::Integer, include_undated::Bool)
    t_day = note["t_day"]
    t_day === nothing && return include_undated
    return t_start <= Int(t_day) <= t_end
end

function summarize_buckets(notes)
    t_days = Dict{String, Int}()
    themes = Dict{String, Int}()
    formats = Dict{String, Int}()
    for note in notes
        day_key = note["t_day"] === nothing ? "undated" : string("T", note["t_day"])
        t_days[day_key] = get(t_days, day_key, 0) + 1
        formats[string(note["format"])] = get(formats, string(note["format"]), 0) + 1
        for theme in note["themes"]
            themes[string(theme)] = get(themes, string(theme), 0) + 1
        end
    end
    return Dict("t_days" => t_days, "themes" => themes, "formats" => formats)
end

function plan_stage(source::AbstractString; existing_source_urls=Set{String}(), t_start::Integer=DEFAULT_T_START, t_end::Integer=DEFAULT_T_END, t0_date::Date=DEFAULT_T0_DATE, include_undated::Bool=true, generated_at::String=format_utc(now(UTC)), channel_urn::String=DEFAULT_CHANNEL_URN, session_urn::String=DEFAULT_SESSION_URN)
    source_exists = ispath(source)
    notes, skipped = source_exists ? load_notes(source; t0_date=t0_date) : (Any[], Any[])
    for note in notes
        duplicate = note["source_url"] in existing_source_urls
        note["duplicate_existing_source_url"] = duplicate
        note["review_status"] = duplicate ? "duplicate_source" : (note["t_day"] === nothing ? "needs_date_review" : "source_structured")
    end
    selected = [note for note in notes if note_in_range(note, t_start, t_end, include_undated) && !note["duplicate_existing_source_url"]]
    excluded = [Dict("id" => note["id"], "title" => note["title"], "t_day" => note["t_day"], "reason" => note["duplicate_existing_source_url"] ? "duplicate_source" : "outside_t_window") for note in notes if !(note in selected)]
    date_start = string(date_for_t_day(t_start; t0_date=t0_date))
    date_end = string(date_for_t_day(t_end; t0_date=t0_date))
    return Dict(
        "projection_kind" => "t206_keep_loose_thought_ingest_stage",
        "generated_at" => generated_at,
        "mode" => "dry-stage",
        "source" => Dict(
            "path" => source,
            "exists" => source_exists,
            "supported_extensions" => sort(collect(SUPPORTED_EXTENSIONS)),
            "file_count" => source_exists ? length(discover_files(source)) : 0,
            "skipped" => skipped,
        ),
        "t_window" => Dict("t_start" => t_start, "t_end" => t_end, "date_start" => date_start, "date_end" => date_end, "t0_date" => string(t0_date), "include_undated" => include_undated),
        "access_paths" => ACCESS_PATHS,
        "notes_total" => length(notes),
        "selected_note_count" => length(selected),
        "excluded_note_count" => length(excluded),
        "selected_notes" => selected,
        "excluded_notes" => excluded,
        "buckets" => summarize_buckets(selected),
        "candidate_hg" => candidate_hg(selected; channel_urn=channel_urn, session_urn=session_urn, retrieved_at=generated_at),
        "conversation_plan" => Dict(
            "stage_1" => "Acquire or point to a local Keep/Takeout/manual-export source. Do not read credentials or use unofficial APIs.",
            "stage_2" => "Parse notes into source records, filter T195-T206, mark duplicates and undated rows.",
            "stage_3" => "Review theme buckets and candidate KI/claim/derivation/program topology with Sam.",
            "stage_4" => "Only after approval, emit a dev/scripts/ops apply program with explicit actor/session discipline.",
            "stage_5" => "Project accepted HG carriers back into session/dashboard/HDC-cache planning lanes.",
        ),
        "lingo_lifecycle" => Dict(
            "volatile_eval" => "S0 notes, IDE conversation, working memory, GPU scratch, browser/Keep UI.",
            "structured_stage" => "Local review artifact with source IDs, dates, themes, duplicate checks, and candidate URNs.",
            "graph_evidence" => "knowledge_item plus WF12 channel evidence; claims and derivations explain what was extracted.",
            "projection_cache" => "Derived indexes, HDC vectors, presets, dashboards, and FS caches keyed by ontology_version/log_len/encoder_version.",
            "hardware_surface" => "Rust/assembly/GPU/host code remains an actuator or derived compute surface unless promoted by reviewed HG topology.",
        ),
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
        println(io, "# T206 Keep/Loose Thought Ingest Stage")
        println(io)
        println(io, "- Mode: `", plan["mode"], "`")
        println(io, "- Generated: `", plan["generated_at"], "`")
        println(io, "- Source: `", plan["source"]["path"], "` (exists: `", plan["source"]["exists"], "`)")
        println(io, "- T-window: T", plan["t_window"]["t_start"], "-T", plan["t_window"]["t_end"], " / ", plan["t_window"]["date_start"], " to ", plan["t_window"]["date_end"])
        println(io, "- Notes selected: ", plan["selected_note_count"], " of ", plan["notes_total"])
        println(io, "- Candidate HG: ", plan["candidate_hg"]["candidate_node_count"], " nodes, ", plan["candidate_hg"]["candidate_relation_count"], " relations")
        println(io, "- Apply ready: `", plan["candidate_hg"]["apply_ready"], "`")
        println(io)
        println(io, "## Access Path")
        for path_info in plan["access_paths"]
            println(io, "- `", path_info["id"], "` (`", path_info["status"], "`): ", path_info["summary"])
        end
        println(io)
        println(io, "## Conversation Plan")
        for key in sort(collect(keys(plan["conversation_plan"])))
            println(io, "- `", key, "`: ", plan["conversation_plan"][key])
        end
        println(io)
        println(io, "## Lingo Lifecycle")
        for key in ["volatile_eval", "structured_stage", "graph_evidence", "projection_cache", "hardware_surface"]
            println(io, "- `", key, "`: ", plan["lingo_lifecycle"][key])
        end
        println(io)
        println(io, "## Theme Buckets")
        themes = plan["buckets"]["themes"]
        if isempty(themes)
            println(io, "No selected notes yet.")
        else
            for key in sort(collect(keys(themes)))
                println(io, "- `", key, "`: ", themes[key])
            end
        end
        println(io)
        println(io, "## Selected Notes")
        if isempty(plan["selected_notes"])
            println(io, "No selected notes were found. Place a Takeout Keep folder or manual export at the source path, or pass `--source <path>`.")
        else
            for note in plan["selected_notes"]
                day = note["t_day"] === nothing ? "undated" : string("T", note["t_day"])
                println(io, "- `", day, "` ", note["title"], " — themes: `", join(note["themes"], "`, `"), "`; status: `", note["review_status"], "`")
            end
        end
        println(io)
        println(io, "## Apply Boundary")
        println(io, plan["candidate_hg"]["apply_boundary"])
    end
end

function parse_bool(value::AbstractString)
    lowered = lowercase(strip(value))
    lowered in ["1", "true", "yes", "y"] && return true
    lowered in ["0", "false", "no", "n"] && return false
    error("expected boolean value, got ", value)
end

function parse_args(argv)
    options = Dict(
        "source" => DEFAULT_SOURCE,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "base-url" => DEFAULT_BASE_URL,
        "nodes-file" => "",
        "t-start" => string(DEFAULT_T_START),
        "t-end" => string(DEFAULT_T_END),
        "t0-date" => string(DEFAULT_T0_DATE),
        "include-undated" => "true",
        "channel-urn" => DEFAULT_CHANNEL_URN,
        "session-urn" => DEFAULT_SESSION_URN,
        "skip-live-state" => "false",
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

function main(argv=ARGS)
    options = parse_args(argv)
    existing_urls = Set{String}()
    if !parse_bool(options["skip-live-state"])
        try
            existing_urls = load_existing_source_urls(base_url=options["base-url"], nodes_file=options["nodes-file"])
        catch err
            println(stderr, "Warning: could not read live knowledge_item source URLs: ", sprint(showerror, err))
        end
    end
    plan = plan_stage(
        options["source"];
        existing_source_urls=existing_urls,
        t_start=parse(Int, options["t-start"]),
        t_end=parse(Int, options["t-end"]),
        t0_date=Date(options["t0-date"]),
        include_undated=parse_bool(options["include-undated"]),
        channel_urn=options["channel-urn"],
        session_urn=options["session-urn"],
    )
    write_json(options["out"], plan)
    write_markdown(options["markdown-out"], plan)
    println("Wrote Keep ingest stage: ", options["out"])
    println("Wrote Keep ingest report: ", options["markdown-out"])
    println("Selected notes: ", plan["selected_note_count"], " / ", plan["notes_total"])
    println("Apply ready: ", plan["candidate_hg"]["apply_ready"])
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(KeepT195T206IngestStage.main())
end