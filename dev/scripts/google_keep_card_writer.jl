#!/usr/bin/env julia

# F-direction Keep actuator: projects the folded seat table into Google Keep
# workspace cards for the recipients in dev/config/keep-card-recipients.json.
# Z440-only actuator: the slug->apiName index is machine-local (scratch/).
# Keep API v1 has no notes.update, so refresh = create-new-then-delete-old;
# ALL deletes funnel through delete_generated_note! (sentinel hard guard).
# check/plan are pure-local; only write/cleanup touch the network.

module GoogleKeepCardWriter

using Dates
using JSON3

include(joinpath(@__DIR__, "google_keep_fetch.jl"))

const Fetch = GoogleKeepFetch
const OAuth = GoogleKeepFetch.OAuth
const Stage = GoogleKeepFetch.Stage

const DEFAULT_RECIPIENTS_PATH = "dev/config/keep-card-recipients.json"
const DEFAULT_SEAT_TABLE_PATH = "tmp/projections/session_pipeline/config/seat-table.folded.json"
const DEFAULT_SESSION_CONTEXT_PATH = "tmp/projections/session_pipeline/session_context/current_session.json"
const DEFAULT_GATE_PATH = "tmp/projections/session_pipeline/mvp/session_pipeline_gate.json"
const DEFAULT_SEAT_DISPLAY_PATH = "dev/config/seat-display.json"
const DEFAULT_AFFORDANCE_MAP_PATH = "dev/config/session-affordance-map.json"
const DEFAULT_DESKTOPS_PATH = "dev/config/z440-session-desktops.json"
const DEFAULT_ONTOLOGY_PATH = "kb/superset/ontology.json"
const DEFAULT_INDEX_PATH = "scratch/keep/cards/keep_card_index.json"
const DEFAULT_PLAN_DIR = "tmp/projections/session_pipeline/keep_cards"
const DEFAULT_RESULT_PATH = "tmp/projections/google_keep_card_write_result.json"
const CONFIG_PROJECTION_SCRIPT = joinpath("dev", "scripts", "projections", "config_projection.py")

const CARD_TITLE_PREFIX = Stage.MOOS_CARD_TITLE_PREFIX
const FLEET_SLUG = "fleet"
const CARD_CHAR_LIMIT = 1500
const MAX_SKILLS = 5
const FOOTER_SEPARATOR = "---"
const CARDS_CHOICES = ["fleet", "per-workspace", "both"]

object_value(obj, name::Symbol, default=nothing) = OAuth.object_value(obj, name, default)
parse_bool(value::AbstractString) = Fetch.parse_bool(value)

row_string(row, name::Symbol) = Stage.as_string(object_value(row, name, ""), "")

# ---------------------------------------------------------------------------
# Recipient map
# ---------------------------------------------------------------------------

function recipient_record(recipient)
    card_query = object_value(recipient, :card_query, nothing)
    record = Dict{String, Any}(
        "user_urn" => Stage.as_string(object_value(recipient, :user_urn, ""), ""),
        "subject" => Stage.as_string(object_value(recipient, :subject, ""), ""),
        "devices" => [string(device) for device in Stage.as_array(object_value(recipient, :devices, nothing))],
        "card_query" => Dict{String, Any}(
            "fleet" => object_value(card_query, :fleet, true) == true,
            "per_workspace" => Stage.as_string(object_value(card_query, :per_workspace, "occupied-active"), "occupied-active"),
            "include_birth" => object_value(card_query, :include_birth, false) == true,
        ),
    )
    isempty(record["user_urn"]) && error("recipient is missing user_urn")
    isempty(record["subject"]) && error("recipient is missing subject")
    return record
end

function load_recipients(path::AbstractString)
    isfile(path) || error(string("Keep card recipient map not found: ", path))
    parsed = OAuth.read_json(path)
    recipients = [recipient_record(recipient) for recipient in Stage.as_array(object_value(parsed, :recipients, nothing))]
    isempty(recipients) && error(string("Keep card recipient map has no recipients: ", path))
    return recipients
end

# ---------------------------------------------------------------------------
# Fold sources (all local; only the seat-table render fallback may read the
# router/kernel, and that is a read-only fold)
# ---------------------------------------------------------------------------

function ensure_seat_table!(seat_table_path::AbstractString, python_exe::AbstractString, warnings)
    isfile(seat_table_path) && return
    push!(warnings, string("seat table missing; running config_projection.py --mode render (read-only fold): ", seat_table_path))
    try
        run(Cmd([python_exe, CONFIG_PROJECTION_SCRIPT, "--mode", "render"]))
    catch err
        error(string("seat table missing at ", seat_table_path, " and config_projection.py --mode render failed (router/kernel down?): ", sprint(showerror, err)))
    end
    isfile(seat_table_path) || error(string("config_projection.py --mode render completed but did not produce ", seat_table_path))
end

function read_json_source(path::AbstractString, label::AbstractString, warnings)
    if !isfile(path)
        push!(warnings, string(label, " missing: ", path))
        return nothing
    end
    try
        return OAuth.read_json(path)
    catch err
        push!(warnings, string(label, " unreadable: ", path, ": ", sprint(showerror, err)))
        return nothing
    end
end

function skills_by_session(affordance_map)
    result = Dict{String, Vector{String}}()
    affordance_map === nothing && return result
    for session in Stage.as_array(object_value(affordance_map, :sessions, nothing))
        urn = Stage.as_string(object_value(session, :session_urn, ""), "")
        isempty(urn) && continue
        haskey(result, urn) && continue
        result[urn] = [string(skill) for skill in Stage.as_array(object_value(session, :skills, nothing))]
    end
    return result
end

function desktops_by_session(desktops_config)
    result = Dict{String, Int}()
    desktops_config === nothing && return result
    for desktop in Stage.as_array(object_value(desktops_config, :desktops, nothing))
        urn = Stage.as_string(object_value(desktop, :session_urn, ""), "")
        index = object_value(desktop, :index, nothing)
        (isempty(urn) || index === nothing) && continue
        haskey(result, urn) && continue
        result[urn] = Int(index)
    end
    return result
end

function gate_evidence_value(gate, name::Symbol)
    gate === nothing && return nothing
    for entry in Stage.as_array(object_value(gate, :gates, nothing))
        evidence = object_value(entry, :evidence, nothing)
        evidence === nothing && continue
        value = object_value(evidence, name, nothing)
        value === nothing && continue
        value isa AbstractString && isempty(strip(value)) && continue
        return value
    end
    return nothing
end

function gate_summary_record(gate)
    gate === nothing && return nothing
    summary = object_value(gate, :summary, nothing)
    summary === nothing && return nothing
    return Dict{String, Any}(
        "pass" => Int(object_value(summary, :pass, 0)),
        "warn" => Int(object_value(summary, :warn, 0)),
        "fail" => Int(object_value(summary, :fail, 0)),
    )
end

function ontology_version_from(gate, ontology, warnings)
    gate_version = gate_evidence_value(gate, :ontology_version)
    gate_version !== nothing && return string(gate_version)
    version = Stage.as_string(object_value(ontology, :version, ""), "")
    if isempty(version)
        push!(warnings, "ontology version unavailable (gate evidence empty and ontology.json unreadable)")
        return ""
    end
    return version
end

function file_mtime_utc(path::AbstractString)
    isfile(path) || return ""
    return OAuth.format_utc(unix2datetime(mtime(path)))
end

function artifact_generated_at(session_context, gate, seat_table_path, warnings)
    for source in (session_context, gate)
        value = Stage.as_string(object_value(source, :generated_at, ""), "")
        !isempty(value) && return value
    end
    stamp = file_mtime_utc(seat_table_path)
    if isempty(stamp)
        push!(warnings, "no artifact generated_at found; footer will read unknown")
        return "unknown"
    end
    push!(warnings, "session-context/gate generated_at missing; footer uses seat-table mtime")
    return stamp
end

function resolve_t_day(options, gate, generated_at, warnings)
    override = strip(options["t-day"])
    isempty(override) || return parse(Int, override)
    gate_t = gate_evidence_value(gate, :t_day)
    gate_t !== nothing && return Int(gate_t)
    dt = Fetch.google_datetime(generated_at)
    dt !== nothing && return Stage.t_day_for_date(Date(dt))
    push!(warnings, "artifact generated_at unparsable; T-day falls back to today")
    return Stage.t_day_for_date(today())
end

function fold_sources(options)
    warnings = String[]
    seat_table_path = options["seat-table"]
    ensure_seat_table!(seat_table_path, options["python"], warnings)
    rows = collect(OAuth.read_json(seat_table_path))

    session_context = read_json_source(options["session-context"], "session context artifact", warnings)
    gate = read_json_source(options["gate"], "MVP gate artifact", warnings)
    seat_display = read_json_source(options["seat-display"], "seat-display config", warnings)
    affordance_map = read_json_source(options["affordance-map"], "session-affordance-map config", warnings)
    desktops_config = read_json_source(options["desktops"], "z440-session-desktops config", warnings)
    ontology = read_json_source(options["ontology"], "ontology.json", warnings)

    generated_at = artifact_generated_at(session_context, gate, seat_table_path, warnings)
    t_day = resolve_t_day(options, gate, generated_at, warnings)
    workstation_order = [string(name) for name in Stage.as_array(object_value(seat_display, :workstation_order, nothing))]

    return Dict{String, Any}(
        "rows" => rows,
        "generated_at" => generated_at,
        "t_day" => t_day,
        "date" => string(Stage.date_for_t_day(t_day)),
        "ontology_version" => ontology_version_from(gate, ontology, warnings),
        "gate_status" => Stage.as_string(object_value(gate, :overall_status, ""), "unknown"),
        "gate_summary" => gate_summary_record(gate),
        "workstation_order" => workstation_order,
        "skills_by_session" => skills_by_session(affordance_map),
        "desktops_by_session" => desktops_by_session(desktops_config),
        "warnings" => warnings,
    )
end

# ---------------------------------------------------------------------------
# Card builders (pure; fixtures welcome)
# ---------------------------------------------------------------------------

function workspace_slug(workspace)
    text = string(workspace)
    startswith(text, "sam.") && (text = text[5:end])
    return Stage.slugify(text; fallback="workspace")
end

session_urn_for(workspace) = string("urn:moos:session:", workspace)

is_birth_workspace(row) = endswith(row_string(row, :workspace), ".birth-workspace")

occupied_active(row) = !isempty(row_string(row, :agent)) && !isempty(row_string(row, :emit))

function per_workspace_rows(rows; include_birth::Bool=false)
    seen = Set{String}()
    selected = Any[]
    for row in rows
        workspace = row_string(row, :workspace)
        isempty(workspace) && continue
        !include_birth && is_birth_workspace(row) && continue
        occupied_active(row) || continue
        slug = workspace_slug(workspace)
        slug in seen && continue
        push!(seen, slug)
        push!(selected, row)
    end
    return selected
end

function clean_display(text)
    cleaned = replace(string(text), "`" => "")
    cleaned = replace(cleaned, "*" => "")
    return strip(replace(cleaned, r"\s+" => " "))
end

card_footer(generated_at) = string("Refreshed ", generated_at, " - do not edit, regenerated by mo:os")

function card_record(slug::AbstractString, title::AbstractString, core_lines, generated_at)
    core = join(core_lines, "\n")
    footer = card_footer(generated_at)
    body = string(core, "\n", FOOTER_SEPARATOR, "\n", footer)
    return Dict{String, Any}(
        "slug" => string(slug),
        "title" => string(title),
        "body" => body,
        "body_core" => core,
        "footer" => footer,
        "text_sha1" => Stage.text_hash(string(title, "\n", core)),
        "char_count" => length(body),
        "over_limit" => length(body) > CARD_CHAR_LIMIT,
    )
end

function build_workspace_card(row; t_day::Integer, date::AbstractString, skills=String[], desktop=nothing, generated_at::AbstractString="unknown")
    workspace = row_string(row, :workspace)
    isempty(workspace) && error("seat row is missing workspace")
    slug = workspace_slug(workspace)
    persona = row_string(row, :persona)
    engine = row_string(row, :engine)
    engine_port = row_string(row, :engine_port)
    emit = row_string(row, :emit)
    surface = clean_display(row_string(row, :surface))
    mcp = clean_display(row_string(row, :mcp))
    purpose = row_string(row, :purpose)

    lines = String[]
    push!(lines, isempty(persona) ? slug : persona)
    push!(lines, string("T=", t_day, " (", date, ")"))
    agent = row_string(row, :agent)
    !isempty(agent) && push!(lines, string("Agent: ", agent))
    if !isempty(engine)
        engine_line = string("Engine: ", engine)
        !isempty(engine_port) && (engine_line = string(engine_line, " ", engine_port))
        !isempty(emit) && emit != engine && (engine_line = string(engine_line, " (emit ", emit, ")"))
        push!(lines, engine_line)
    end
    !isempty(surface) && surface != "—" && push!(lines, string("Surface: ", surface))
    desktop !== nothing && push!(lines, string("Desktop: ", desktop))
    !isempty(mcp) && push!(lines, string("MCP: ", mcp))
    !isempty(purpose) && push!(lines, string("Purpose: ", purpose))
    if !isempty(skills)
        shown = [string(skill) for skill in skills[1:min(end, MAX_SKILLS)]]
        push!(lines, string("Skills: ", join(shown, ", ")))
    end
    return card_record(slug, string(CARD_TITLE_PREFIX, slug), lines, generated_at)
end

row_workstation(row) = first(split(row_string(row, :engine), '.'))

function ordered_workstations(rows, workstation_order)
    present = unique([row_workstation(row) for row in rows if !isempty(row_workstation(row))])
    ordered = [name for name in workstation_order if name in present]
    append!(ordered, sort([name for name in present if !(name in ordered)]))
    return ordered
end

function build_fleet_card(rows; t_day::Integer, date::AbstractString, ontology_version::AbstractString="", gate_status::AbstractString="unknown", gate_summary=nothing, workstation_order=String[], generated_at::AbstractString="unknown")
    isempty(rows) && error("fleet card needs at least one seat row")
    lines = String[]
    push!(lines, "mo:os fleet")
    push!(lines, string("T=", t_day, " (", date, ")"))
    push!(lines, isempty(ontology_version) ? "Ontology: unknown" : string("Ontology: v", ontology_version))
    if gate_summary === nothing
        push!(lines, string("Gate: ", gate_status))
    else
        push!(lines, string("Gate: ", gate_status, " (pass ", gate_summary["pass"], " / warn ", gate_summary["warn"], " / fail ", gate_summary["fail"], ")"))
    end
    for workstation in ordered_workstations(rows, workstation_order)
        push!(lines, string(workstation, ":"))
        for row in rows
            row_workstation(row) == workstation || continue
            slug = workspace_slug(row_string(row, :workspace))
            persona = row_string(row, :persona)
            push!(lines, isempty(persona) ? string("- ", slug) : string("- ", slug, " (", persona, ")"))
        end
    end
    return card_record(FLEET_SLUG, string(CARD_TITLE_PREFIX, FLEET_SLUG), lines, generated_at)
end

function assert_card_titles(cards)
    for card in cards
        title = string(card["title"])
        startswith(title, CARD_TITLE_PREFIX) || error(string("card title lacks the ", CARD_TITLE_PREFIX, "sentinel: ", title))
        if Stage.explicit_t_day(title) !== nothing
            error(string("card title parses as an explicit T-day (timestamps never belong in titles): ", title))
        end
    end
    return true
end

function build_cards(rows; card_query, cards_mode::AbstractString="both", card_slug::AbstractString="", t_day::Integer, date::AbstractString, ontology_version::AbstractString="", gate_status::AbstractString="unknown", gate_summary=nothing, workstation_order=String[], skills_by_session=Dict{String, Vector{String}}(), desktops_by_session=Dict{String, Int}(), generated_at::AbstractString="unknown")
    cards_mode in CARDS_CHOICES || error(string("unknown --cards value: ", cards_mode, " (expected ", join(CARDS_CHOICES, " | "), ")"))
    per_workspace = string(card_query["per_workspace"])
    per_workspace == "occupied-active" || error(string("unsupported card_query.per_workspace selector: ", per_workspace))
    selected = per_workspace_rows(rows; include_birth=card_query["include_birth"] == true)
    # Hard guard: an empty seat table must never look like "all cards vanished"
    # downstream — error out before any write/delete path can run.
    isempty(selected) && error("seat table produced no occupied-active workspace rows; refusing to build cards")

    cards = Any[]
    if cards_mode in ["both", "fleet"] && card_query["fleet"] == true
        push!(cards, build_fleet_card(selected; t_day=t_day, date=date, ontology_version=ontology_version, gate_status=gate_status, gate_summary=gate_summary, workstation_order=workstation_order, generated_at=generated_at))
    end
    if cards_mode in ["both", "per-workspace"]
        for row in selected
            session_urn = session_urn_for(row_string(row, :workspace))
            push!(cards, build_workspace_card(
                row;
                t_day=t_day,
                date=date,
                skills=get(skills_by_session, session_urn, String[]),
                desktop=get(desktops_by_session, session_urn, nothing),
                generated_at=generated_at,
            ))
        end
    end
    slug_filter = strip(card_slug)
    if !isempty(slug_filter)
        cards = [card for card in cards if card["slug"] == slug_filter]
        isempty(cards) && error(string("no generated card matches --card-slug ", slug_filter))
    end
    assert_card_titles(cards)
    return cards
end

function cards_from_fold(fold, recipient, options)
    return build_cards(
        fold["rows"];
        card_query=recipient["card_query"],
        cards_mode=options["cards"],
        card_slug=options["card-slug"],
        t_day=fold["t_day"],
        date=fold["date"],
        ontology_version=fold["ontology_version"],
        gate_status=fold["gate_status"],
        gate_summary=fold["gate_summary"],
        workstation_order=fold["workstation_order"],
        skills_by_session=fold["skills_by_session"],
        desktops_by_session=fold["desktops_by_session"],
        generated_at=fold["generated_at"],
    )
end

# ---------------------------------------------------------------------------
# Local index (machine-local; slug => {apiName, title, text_sha1, written_at})
# ---------------------------------------------------------------------------

function load_index(path::AbstractString)
    index = Dict{String, Any}("pending_deletes" => Any[])
    isfile(path) || return index
    parsed = OAuth.read_json(path)
    for key in keys(parsed)
        name = string(key)
        if name == "pending_deletes"
            index[name] = Any[entry for entry in Stage.as_array(parsed[key])]
        else
            index[name] = Dict{String, Any}(string(k) => v for (k, v) in pairs(parsed[key]))
        end
    end
    return index
end

save_index(path::AbstractString, index) = Fetch.write_json(path, index)

card_entries(index) = sort([(slug, entry) for (slug, entry) in index if slug != "pending_deletes"]; by=first)

function planned_action(card, index)
    entry = get(index, card["slug"], nothing)
    entry === nothing && return "create"
    return string(object_value(entry, :text_sha1, "")) == card["text_sha1"] ? "skip" : "rotate"
end

# ---------------------------------------------------------------------------
# Keep API write flow (only reached from --mode write / cleanup)
# ---------------------------------------------------------------------------

function is_http_404(err)
    return occursin("HTTP 404", sprint(showerror, err))
end

function note_exists(name::AbstractString, access_token::AbstractString; request_json_fn=OAuth.request_json)
    try
        note = request_json_fn(Fetch.keep_url(string("v1/", name)); bearer=access_token)
        # A trashed note still resolves via notes.get; for rotation purposes it is
        # gone from the user's Notes view, so treat it as missing and recreate.
        trashed = object_value(note, :trashed, false)
        return !(trashed == true || string(trashed) == "true")
    catch err
        is_http_404(err) && return false
        rethrow(err)
    end
end

"""
    delete_generated_note!(name, access_token; request_json_fn)

The single choke point for EVERY Keep delete this writer performs. Reads the
live note first and refuses unless the live title carries the sentinel, so a
corrupt index can never delete a real note. 404 => already gone.
"""
function delete_generated_note!(name::AbstractString, access_token::AbstractString; request_json_fn=OAuth.request_json)
    isempty(strip(name)) && error("delete_generated_note! called with an empty note name")
    note = nothing
    try
        note = request_json_fn(Fetch.keep_url(string("v1/", name)); bearer=access_token)
    catch err
        is_http_404(err) && return Dict{String, Any}("name" => string(name), "action" => "already-gone")
        rethrow(err)
    end
    title = string(object_value(note, :title, ""))
    if !Stage.is_generated_card_title(title)
        error(string("refusing to delete Keep note ", name, ": live title lacks the ", CARD_TITLE_PREFIX, "sentinel (", title, ")"))
    end
    request_json_fn(Fetch.keep_url(string("v1/", name)); method="DELETE", bearer=access_token)
    return Dict{String, Any}("name" => string(name), "action" => "deleted")
end

function create_card_note!(card, access_token::AbstractString; request_json_fn=OAuth.request_json)
    body = Dict("title" => card["title"], "body" => Dict("text" => Dict("text" => card["body"])))
    response = request_json_fn(Fetch.keep_url("v1/notes"); method="POST", bearer=access_token, json_body=body)
    name = string(object_value(response, :name, ""))
    isempty(name) && error(string("Keep notes.create returned no name for card ", card["slug"]))
    return name
end

function sync_card!(card, index, access_token::AbstractString; index_path::AbstractString, now_utc::DateTime=OAuth.utc_now(), request_json_fn=OAuth.request_json)
    slug = string(card["slug"])
    entry = get(index, slug, nothing)
    old_name = entry === nothing ? "" : string(object_value(entry, :apiName, ""))
    if entry !== nothing && string(object_value(entry, :text_sha1, "")) == card["text_sha1"] && !isempty(old_name) && note_exists(old_name, access_token; request_json_fn=request_json_fn)
        return Dict{String, Any}("slug" => slug, "action" => "skip", "apiName" => old_name)
    end

    new_name = create_card_note!(card, access_token; request_json_fn=request_json_fn)
    index[slug] = Dict{String, Any}(
        "apiName" => new_name,
        "title" => card["title"],
        "text_sha1" => card["text_sha1"],
        "written_at" => OAuth.format_utc(now_utc),
    )
    save_index(index_path, index)

    result = Dict{String, Any}("slug" => slug, "action" => isempty(old_name) ? "create" : "rotate", "apiName" => new_name)
    if !isempty(old_name) && old_name != new_name
        try
            result["old_note"] = delete_generated_note!(old_name, access_token; request_json_fn=request_json_fn)
        catch err
            # Never lose a delete: park it for the next run (worst case is a
            # transient duplicate card, never a lost one).
            push!(index["pending_deletes"], Dict{String, Any}("name" => old_name, "error" => sprint(showerror, err), "at" => OAuth.format_utc(now_utc)))
            save_index(index_path, index)
            result["old_note"] = Dict{String, Any}("name" => old_name, "action" => "pending-delete")
        end
    end
    return result
end

function retry_pending_deletes!(index, access_token::AbstractString; index_path::AbstractString, request_json_fn=OAuth.request_json)
    pending = Stage.as_array(get(index, "pending_deletes", nothing))
    isempty(pending) && return Any[]
    results = Any[]
    remaining = Any[]
    for entry in pending
        name = string(object_value(entry, :name, ""))
        isempty(name) && continue
        try
            push!(results, delete_generated_note!(name, access_token; request_json_fn=request_json_fn))
        catch err
            push!(results, Dict{String, Any}("name" => name, "action" => "still-pending", "error" => sprint(showerror, err)))
            push!(remaining, entry)
        end
    end
    index["pending_deletes"] = remaining
    save_index(index_path, index)
    return results
end

function scan_orphans(index, access_token::AbstractString; page_size::Integer=100, max_pages::Integer=20, request_json_fn=OAuth.request_json)
    notes, pages, truncated = Fetch.fetch_notes(access_token; page_size=page_size, max_pages=max_pages, hydrate_details=false, request_json_fn=request_json_fn)
    if truncated
        # A truncated list cannot prove a card is untracked — skip, never guess.
        return Dict{String, Any}("skipped" => true, "reason" => "notes.list truncated; orphan scan skipped", "pages" => pages, "orphans" => Any[])
    end
    tracked = Set{String}(string(object_value(entry, :apiName, "")) for (_, entry) in card_entries(index))
    orphans = Any[]
    for note in notes
        name = string(object_value(note, :name, ""))
        title = string(object_value(note, :title, ""))
        trashed = object_value(note, :trashed, false)
        (trashed == true || string(trashed) == "true") && continue
        Stage.is_generated_card_title(title) || continue
        name in tracked && continue
        push!(orphans, Dict{String, Any}("name" => name, "title" => title))
    end
    return Dict{String, Any}("skipped" => false, "pages" => pages, "orphans" => orphans)
end

function delete_orphans!(index, access_token::AbstractString; page_size::Integer=100, max_pages::Integer=20, request_json_fn=OAuth.request_json)
    scan = scan_orphans(index, access_token; page_size=page_size, max_pages=max_pages, request_json_fn=request_json_fn)
    scan["skipped"] == true && return scan
    results = Any[]
    for orphan in scan["orphans"]
        push!(results, delete_generated_note!(string(orphan["name"]), access_token; request_json_fn=request_json_fn))
    end
    scan["deleted"] = results
    return scan
end

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------

function plan_record(fold, recipient, cards, options)
    return Dict{String, Any}(
        "projection_kind" => "keep_workspace_card_plan",
        "mode" => options["mode"],
        "generated_at" => OAuth.format_utc(OAuth.utc_now()),
        "artifact_generated_at" => fold["generated_at"],
        "t_day" => fold["t_day"],
        "date" => fold["date"],
        "ontology_version" => fold["ontology_version"],
        "gate" => Dict{String, Any}("status" => fold["gate_status"], "summary" => fold["gate_summary"]),
        "recipient" => recipient,
        "cards_mode" => options["cards"],
        "card_slug" => options["card-slug"],
        "index_path" => options["index"],
        "card_count" => length(cards),
        "over_limit_count" => count(card -> card["over_limit"], cards),
        "char_limit" => CARD_CHAR_LIMIT,
        "cards" => cards,
        "warnings" => fold["warnings"],
        "write_boundary" => "plan is dry: only --mode write / cleanup touch the Keep API, via Invoke-KeepIngestHarness.ps1 card modes",
    )
end

function write_plan_markdown(path::AbstractString, plan)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Keep workspace card plan")
        println(io)
        println(io, "- Mode: `", plan["mode"], "`")
        println(io, "- Generated: `", plan["generated_at"], "`")
        println(io, "- Artifact refreshed: `", plan["artifact_generated_at"], "`")
        println(io, "- T-day: T", plan["t_day"], " (", plan["date"], ")")
        recipient = plan["recipient"]
        println(io, "- Recipient: `", recipient["user_urn"], "` -> ", recipient["subject"], " (", join(recipient["devices"], ", "), ")")
        println(io, "- Cards: ", plan["card_count"], " (over limit: ", plan["over_limit_count"], " of max ", plan["char_limit"], " chars)")
        if !isempty(plan["warnings"])
            println(io)
            println(io, "## Warnings")
            for warning in plan["warnings"]
                println(io, "- ", warning)
            end
        end
        println(io)
        println(io, "## Card previews (verbatim)")
        for card in plan["cards"]
            println(io)
            println(io, "### ", card["title"])
            println(io)
            flags = card["over_limit"] ? " / OVER LIMIT" : ""
            println(io, "- slug: `", card["slug"], "` / chars: ", card["char_count"], " / sha1: `", card["text_sha1"][1:12], "` / planned: `", card["planned_action"], "`", flags)
            println(io)
            println(io, "```text")
            println(io, card["title"])
            println(io, card["body"])
            println(io, "```")
        end
    end
end

function run_check(options)
    warnings = String[]
    recipients = load_recipients(options["recipients"])
    credential = OAuth.credential_status(options["credentials"], options["token"])
    sources = Any[]
    for (label, path) in [
        ("seat_table", options["seat-table"]),
        ("session_context", options["session-context"]),
        ("gate", options["gate"]),
        ("seat_display", options["seat-display"]),
        ("affordance_map", options["affordance-map"]),
        ("desktops", options["desktops"]),
        ("ontology", options["ontology"]),
    ]
        record = Dict{String, Any}("source" => label, "path" => path, "present" => isfile(path))
        if record["present"]
            record["mtime_utc"] = file_mtime_utc(path)
        else
            push!(warnings, string(label, " missing: ", path))
        end
        push!(sources, record)
    end
    index = load_index(options["index"])
    result = Dict{String, Any}(
        "mode" => "check",
        "recipients_path" => options["recipients"],
        "recipient_count" => length(recipients),
        "credential" => credential,
        "sources" => sources,
        "index" => Dict{String, Any}(
            "path" => options["index"],
            "present" => isfile(options["index"]),
            "card_count" => length(card_entries(index)),
            "pending_deletes" => length(Stage.as_array(get(index, "pending_deletes", nothing))),
        ),
        "warnings" => warnings,
    )
    out_path = joinpath(options["plan-dir"], "keep_card_check.json")
    Fetch.write_json(out_path, result)
    println("Wrote Keep card check: ", out_path)
    println("Recipients: ", result["recipient_count"])
    println("Token present: ", credential["token_present"])
    println("Tracked cards: ", result["index"]["card_count"], " (pending deletes: ", result["index"]["pending_deletes"], ")")
    for warning in warnings
        println(stderr, "Warning: ", warning)
    end
    return 0
end

function run_plan(options)
    recipients = load_recipients(options["recipients"])
    recipient = first(recipients)
    fold = fold_sources(options)
    cards = cards_from_fold(fold, recipient, options)
    index = load_index(options["index"])
    for card in cards
        card["planned_action"] = planned_action(card, index)
    end
    plan = plan_record(fold, recipient, cards, options)
    plan_json = joinpath(options["plan-dir"], "keep_card_plan.json")
    plan_markdown = joinpath(options["plan-dir"], "keep_card_plan.md")
    Fetch.write_json(plan_json, plan)
    write_plan_markdown(plan_markdown, plan)
    println("Wrote Keep card plan: ", plan_json)
    println("Wrote Keep card previews: ", plan_markdown)
    println("Cards: ", plan["card_count"], " (over limit: ", plan["over_limit_count"], ")")
    for warning in fold["warnings"]
        println(stderr, "Warning: ", warning)
    end
    return 0
end

function run_write(options)
    recipients = load_recipients(options["recipients"])
    recipient = first(recipients)
    fold = fold_sources(options)
    cards = cards_from_fold(fold, recipient, options)
    over = [string(card["slug"]) for card in cards if card["over_limit"]]
    isempty(over) || error(string("refusing to write cards over the ", CARD_CHAR_LIMIT, "-char limit: ", join(over, ", ")))

    index = load_index(options["index"])
    access_token = Fetch.ensure_keep_access_token(options["credentials"], options["token"])
    pending = retry_pending_deletes!(index, access_token; index_path=options["index"])
    results = Any[]
    for card in cards
        push!(results, sync_card!(card, index, access_token; index_path=options["index"]))
    end
    orphans = nothing
    if parse_bool(options["delete-orphans"])
        orphans = delete_orphans!(index, access_token; page_size=parse(Int, options["page-size"]), max_pages=parse(Int, options["max-pages"]))
    end
    result = Dict{String, Any}(
        "mode" => "write",
        "recipient" => recipient,
        "card_count" => length(cards),
        "results" => results,
        "pending_delete_retries" => pending,
        "orphans" => orphans,
        "index_path" => options["index"],
        "warnings" => fold["warnings"],
    )
    Fetch.write_json(options["out"], result)
    println("Wrote Keep card write result: ", options["out"])
    for entry in results
        println("  ", entry["slug"], ": ", entry["action"])
    end
    return 0
end

function run_cleanup(options)
    parse_bool(options["confirm"]) || error("cleanup deletes generated Keep cards; rerun with --confirm true (harness: -ConfirmCleanup)")
    index = load_index(options["index"])
    slug_filter = strip(options["card-slug"])
    entries = card_entries(index)
    if !isempty(slug_filter)
        entries = [(slug, entry) for (slug, entry) in entries if slug == slug_filter]
        isempty(entries) && error(string("no tracked card for --card-slug ", slug_filter))
    end
    access_token = Fetch.ensure_keep_access_token(options["credentials"], options["token"])
    pending = retry_pending_deletes!(index, access_token; index_path=options["index"])
    results = Any[]
    for (slug, entry) in entries
        name = string(object_value(entry, :apiName, ""))
        outcome = isempty(name) ? Dict{String, Any}("name" => "", "action" => "no-api-name") : delete_generated_note!(name, access_token)
        outcome["slug"] = slug
        push!(results, outcome)
        delete!(index, slug)
        save_index(options["index"], index)
    end
    orphans = nothing
    if parse_bool(options["delete-orphans"])
        orphans = delete_orphans!(index, access_token; page_size=parse(Int, options["page-size"]), max_pages=parse(Int, options["max-pages"]))
    end
    result = Dict{String, Any}(
        "mode" => "cleanup",
        "deleted" => results,
        "pending_delete_retries" => pending,
        "orphans" => orphans,
        "index_path" => options["index"],
    )
    Fetch.write_json(options["out"], result)
    println("Wrote Keep card cleanup result: ", options["out"])
    println("Deleted cards: ", length(results))
    return 0
end

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

function parse_args(argv)
    options = Dict(
        "mode" => "plan",
        "cards" => "both",
        "card-slug" => "",
        "recipients" => DEFAULT_RECIPIENTS_PATH,
        "seat-table" => DEFAULT_SEAT_TABLE_PATH,
        "session-context" => DEFAULT_SESSION_CONTEXT_PATH,
        "gate" => DEFAULT_GATE_PATH,
        "seat-display" => DEFAULT_SEAT_DISPLAY_PATH,
        "affordance-map" => DEFAULT_AFFORDANCE_MAP_PATH,
        "desktops" => DEFAULT_DESKTOPS_PATH,
        "ontology" => DEFAULT_ONTOLOGY_PATH,
        "credentials" => Fetch.DEFAULT_CLIENT_PATH,
        "token" => Fetch.DEFAULT_TOKEN_PATH,
        "index" => DEFAULT_INDEX_PATH,
        "plan-dir" => DEFAULT_PLAN_DIR,
        "out" => DEFAULT_RESULT_PATH,
        "python" => "python",
        "t-day" => "",
        "page-size" => "100",
        "max-pages" => "20",
        "delete-orphans" => "false",
        "confirm" => "false",
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
    options["cards"] in CARDS_CHOICES || error("unknown --cards value: ", options["cards"], " (expected ", join(CARDS_CHOICES, " | "), ")")
    return options
end

function main(argv=ARGS)
    options = parse_args(argv)
    mode = options["mode"]

    if mode == "check"
        return run_check(options)
    elseif mode == "plan"
        return run_plan(options)
    elseif mode == "write"
        return run_write(options)
    elseif mode == "cleanup"
        return run_cleanup(options)
    end

    error("unknown mode: ", mode)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(GoogleKeepCardWriter.main())
end
