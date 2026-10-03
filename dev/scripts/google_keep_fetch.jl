#!/usr/bin/env julia

module GoogleKeepFetch

using Dates
using Downloads
using JSON3
using Sockets

include(joinpath(@__DIR__, "google_calendar_writer.jl"))
include(joinpath(@__DIR__, "keep_t195_t206_ingest_stage.jl"))

const OAuth = GoogleCalendarWriter
const Stage = KeepT195T206IngestStage

const DEFAULT_CLIENT_PATH = "secrets/google_keep_oauth_client.json"
const DEFAULT_TOKEN_PATH = "secrets/google_keep_token.json"
const DEFAULT_REDIRECT_URI = "http://127.0.0.1:53683/"
const DEFAULT_SCOPES = ["https://www.googleapis.com/auth/keep.readonly"]
const CALENDAR_CLIENT_PATH = "secrets/google_calendar_oauth_client.json"
const GOOGLE_KEEP_API = "https://keep.googleapis.com"
const GOOGLE_OAUTH_V2_AUTH_URI = "https://accounts.google.com/o/oauth2/v2/auth"
const GOOGLE_KEEP_SCOPES = Set(["https://www.googleapis.com/auth/keep", "https://www.googleapis.com/auth/keep.readonly"])
const DEFAULT_OUT_DIR = "scratch/keep/t195-t206/api"
const DEFAULT_RESULT_PATH = "tmp/projections/session_pipeline/keep_t206/google_keep_fetch_result.json"
const DEFAULT_CREDENTIAL_CHECK_PATH = "tmp/projections/session_pipeline/keep_t206/google_keep_credential_check.json"

object_value(obj, name::Symbol, default=nothing) = OAuth.object_value(obj, name, default)

function parse_bool(value::AbstractString)
    lowered = lowercase(strip(value))
    lowered in ["1", "true", "yes", "y"] && return true
    lowered in ["0", "false", "no", "n"] && return false
    error("expected boolean value, got ", value)
end

parse_scopes(scope_text::AbstractString) = OAuth.parse_scopes(scope_text)

function scope_diagnostics(scopes=DEFAULT_SCOPES)
    requested = collect(string.(scopes))
    return Dict{String, Any}(
        "requested_scopes" => requested,
        "all_requested_scopes_in_keep_discovery" => all(scope -> scope in GOOGLE_KEEP_SCOPES, requested),
        "observed_blocker" => "Google OAuth returned Error 400 invalid_scope and Google Auth Platform refused to add https://www.googleapis.com/auth/keep.readonly for the current OAuth client, even after the existing project was moved into an organization.",
        "probable_cause" => "The local request is well-formed, but the Google Keep API is Workspace/enterprise oriented and expects admin-approved domain-wide delegation rather than a normal installed-app OAuth consent flow for this project.",
        "operator_action" => [
            "Enable Google Keep API in the Google Cloud project that owns the OAuth client.",
            "Create a service account with domain-wide delegation enabled in that project.",
            "Download its JSON key to secrets/gcp-service-account.json without committing it.",
            "In Google Admin Console > Security > API controls > Domain-wide delegation, authorize the service account client ID for https://www.googleapis.com/auth/keep.readonly.",
            "Run Invoke-KeepIngestHarness.ps1 -Mode ApiDelegatedFetch to mint secrets/google_keep_token.json, call Keep API, export normalized notes, and stage the real API output.",
        ],
    )
end

function authorization_url(credentials; scopes=DEFAULT_SCOPES, redirect_uri::String=DEFAULT_REDIRECT_URI, state::String=OAuth.random_state())
    config = OAuth.client_config(credentials)
    params = [
        "client_id" => config["client_id"],
        "redirect_uri" => redirect_uri,
        "response_type" => "code",
        "scope" => join(scopes, " "),
        "access_type" => "offline",
        "prompt" => "consent",
        "include_granted_scopes" => "true",
        "state" => state,
    ]
    return string(GOOGLE_OAUTH_V2_AUTH_URI, "?", OAuth.form_encode(params))
end

function google_datetime(value)
    value === nothing && return nothing
    text = strip(string(value))
    isempty(text) && return nothing
    text = replace(text, r"Z$" => "")
    text = replace(text, r"[+-]\d\d:\d\d$" => "")
    matched = match(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})", text)
    matched === nothing && return nothing
    try
        return DateTime(matched.captures[1], dateformat"yyyy-mm-ddTHH:MM:SS")
    catch
        return nothing
    end
end

function timestamp_usec(value)
    dt = google_datetime(value)
    dt === nothing && return nothing
    return Int(round(datetime2unix(dt) * 1_000_000))
end

function note_id(name::AbstractString)
    parts = split(string(name), '/')
    return isempty(parts) ? string(name) : last(parts)
end

function source_url_for_note(name::AbstractString)
    return string(GOOGLE_KEEP_API, "/v1/", name)
end

function source_url_for_attachment(name::AbstractString)
    return string(GOOGLE_KEEP_API, "/v1/", name)
end

function attachment_id(name::AbstractString)
    parts = split(string(name), '/')
    return isempty(parts) ? string(name) : last(parts)
end

function slugify(text::AbstractString; fallback="note")
    return Stage.slugify(text; fallback=fallback)
end

function list_item_text(item; depth::Integer=0)
    text_obj = object_value(item, :text, nothing)
    text = string(object_value(text_obj, :text, ""))
    checked = object_value(item, :checked, false)
    prefix = checked == true || string(checked) == "true" ? "[x] " : "[ ] "
    indent = repeat("  ", max(depth, 0))
    lines = String[]
    !isempty(strip(text)) && push!(lines, string(indent, prefix, text))
    for child in Stage.as_array(object_value(item, :childListItems, nothing))
        child_text = list_item_text(child; depth=depth + 1)
        !isempty(child_text) && push!(lines, child_text)
    end
    return join(lines, "\n")
end

function note_text(note)
    body = object_value(note, :body, nothing)
    body === nothing && return ""
    text_section = object_value(body, :text, nothing)
    if text_section !== nothing
        return string(object_value(text_section, :text, ""))
    end
    list_section = object_value(body, :list, nothing)
    if list_section !== nothing
        lines = [line for line in (list_item_text(item) for item in Stage.as_array(object_value(list_section, :listItems, nothing))) if !isempty(strip(line))]
        return join(lines, "\n")
    end
    return ""
end

function note_list_content(note)
    body = object_value(note, :body, nothing)
    body === nothing && return Any[]
    list_section = object_value(body, :list, nothing)
    list_section === nothing && return Any[]
    records = Any[]
    for item in Stage.as_array(object_value(list_section, :listItems, nothing))
        text_obj = object_value(item, :text, nothing)
        push!(records, Dict(
            "text" => string(object_value(text_obj, :text, "")),
            "isChecked" => object_value(item, :checked, false),
        ))
        for child in Stage.as_array(object_value(item, :childListItems, nothing))
            child_text = object_value(object_value(child, :text, nothing), :text, "")
            push!(records, Dict("text" => string(child_text), "isChecked" => object_value(child, :checked, false)))
        end
    end
    return records
end

function attachment_mime_types(attachment)
    types = String[]
    for mime in Stage.as_array(object_value(attachment, :mimeType, nothing))
        text = strip(string(mime))
        !isempty(text) && push!(types, text)
    end
    return types
end

function normalize_attachments(note)
    attachments = Any[]
    for attachment in Stage.as_array(object_value(note, :attachments, nothing))
        name = strip(string(object_value(attachment, :name, "")))
        isempty(name) && continue
        push!(attachments, Dict(
            "name" => name,
            "attachmentId" => attachment_id(name),
            "mimeTypes" => attachment_mime_types(attachment),
            "sourceUrl" => source_url_for_attachment(name),
        ))
    end
    return attachments
end

function attachment_extension(mime::AbstractString)
    lowered = lowercase(strip(string(mime)))
    lowered == "image/png" && return ".png"
    lowered in ["image/jpeg", "image/jpg"] && return ".jpg"
    lowered == "image/gif" && return ".gif"
    lowered == "image/webp" && return ".webp"
    return ".bin"
end

function download_attachment_media!(attachment, access_token::AbstractString, out_dir::AbstractString, index::Integer)
    mime_types = Stage.as_array(object_value(attachment, :mimeTypes, nothing))
    isempty(mime_types) && return attachment
    mime = strip(string(first(mime_types)))
    isempty(mime) && return attachment
    name = strip(string(object_value(attachment, :name, "")))
    isempty(name) && return attachment

    mkpath(out_dir)
    file_name = string(lpad(index, 2, '0'), "-", attachment_id(name), attachment_extension(mime))
    out_path = joinpath(out_dir, file_name)
    url = keep_url(string("v1/", name); params=["alt" => "media", "mimeType" => mime])
    headers = ["Authorization" => string("Bearer ", access_token), "Accept" => mime]

    response = open(out_path, "w") do io
        Downloads.request(url; headers=headers, output=io, throw=false)
    end
    if response.status < 200 || response.status >= 300
        rm(out_path; force=true)
        attachment["downloadError"] = string("HTTP ", response.status, " from Keep media download: ", response.message)
        return attachment
    end

    attachment["localPath"] = abspath(out_path)
    attachment["bytes"] = filesize(out_path)
    return attachment
end

function download_note_attachments!(normalized, access_token::AbstractString, out_dir::AbstractString)
    isempty(strip(access_token)) && return normalized
    attachments = object_value(normalized, :attachments, nothing)
    attachments === nothing && return normalized
    for (index, attachment) in enumerate(Stage.as_array(attachments))
        download_attachment_media!(attachment, access_token, out_dir, index)
    end
    return normalized
end

function normalize_note(note)
    name = string(object_value(note, :name, ""))
    title = string(object_value(note, :title, ""))
    isempty(strip(title)) && (title = note_id(name))
    text = note_text(note)
    create_time = object_value(note, :createTime, nothing)
    update_time = object_value(note, :updateTime, nothing)
    normalized = Dict{String, Any}(
        "title" => title,
        "textContent" => text,
        "sourceUrl" => source_url_for_note(name),
        "apiName" => name,
        "apiCreateTime" => create_time,
        "apiUpdateTime" => update_time,
        "apiTrashed" => object_value(note, :trashed, false),
        "labels" => Any[],
    )
    created = timestamp_usec(create_time)
    updated = timestamp_usec(update_time)
    created !== nothing && (normalized["createdTimestampUsec"] = created)
    updated !== nothing && (normalized["userEditedTimestampUsec"] = updated)
    list_content = note_list_content(note)
    !isempty(list_content) && (normalized["listContent"] = list_content)
    attachments = normalize_attachments(note)
    !isempty(attachments) && (normalized["attachments"] = attachments)
    return normalized
end

function keep_url(path::AbstractString; params=Pair{String, String}[])
    query = isempty(params) ? "" : string("?", OAuth.form_encode(params))
    return string(rstrip(GOOGLE_KEEP_API, '/'), "/", lstrip(path, '/'), query)
end

function fetch_note_detail(name::AbstractString, access_token::AbstractString; request_json_fn=OAuth.request_json)
    return request_json_fn(keep_url(string("v1/", name)); bearer=access_token)
end

function fetch_notes(access_token::AbstractString; page_size::Integer=100, max_pages::Integer=20, hydrate_details::Bool=true, request_json_fn=OAuth.request_json)
    notes = Any[]
    page_token = ""
    pages = 0
    while true
        pages += 1
        params = Pair{String, String}["pageSize" => string(page_size)]
        !isempty(page_token) && push!(params, "pageToken" => page_token)
        response = request_json_fn(keep_url("v1/notes"; params=params); bearer=access_token)
        for note in Stage.as_array(object_value(response, :notes, nothing))
            if hydrate_details
                name = string(object_value(note, :name, ""))
                if !isempty(name)
                    sleep(0.7); note = fetch_note_detail(name, access_token; request_json_fn=request_json_fn)
                end
            end
            push!(notes, note)
        end
        page_token = string(object_value(response, :nextPageToken, ""))
        if isempty(page_token) || (max_pages > 0 && pages >= max_pages)
            return notes, pages, !isempty(page_token)
        end
    end
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function export_notes(notes, out_dir::AbstractString; include_trashed::Bool=false, access_token::AbstractString="")
    raw_dir = joinpath(out_dir, "raw")
    notes_dir = joinpath(out_dir, "notes")
    attachment_dir = joinpath(out_dir, "attachments")
    mkpath(raw_dir)
    mkpath(notes_dir)
    raw_files = String[]
    normalized_files = String[]
    skipped = Any[]
    for note in notes
        name = string(object_value(note, :name, ""))
        if Stage.is_generated_card_title(string(object_value(note, :title, "")))
            # Generated mo:os workspace cards (google_keep_card_writer.jl) are
            # ingest-invisible: single choke point covering all ApiFetch modes
            # and the keep-anywhere Drive mirror.
            push!(skipped, Dict("name" => name, "reason" => "moos-generated-card"))
            continue
        end
        trashed = object_value(note, :trashed, false)
        if !include_trashed && (trashed == true || string(trashed) == "true")
            push!(skipped, Dict("name" => name, "reason" => "trashed"))
            continue
        end
        normalized = normalize_note(note)
        id = note_id(name)
        update = string(get(normalized, "apiUpdateTime", ""))
        date_prefix = isempty(update) ? "undated" : replace(update[1:min(end, 10)], '-' => "")
        stem = slugify(string(date_prefix, "-", normalized["title"], "-", id); fallback="keep-note")
        raw_path = joinpath(raw_dir, string(stem, ".raw.json"))
        normalized_path = joinpath(notes_dir, string(stem, ".json"))
        if haskey(normalized, "attachments")
            download_note_attachments!(normalized, access_token, joinpath(attachment_dir, stem))
        end
        write_json(raw_path, note)
        write_json(normalized_path, normalized)
        push!(raw_files, raw_path)
        push!(normalized_files, normalized_path)
    end
    return Dict(
        "out_dir" => out_dir,
        "raw_dir" => raw_dir,
        "notes_dir" => notes_dir,
        "attachment_dir" => attachment_dir,
        "raw_files" => raw_files,
        "normalized_files" => normalized_files,
        "skipped" => skipped,
        "written_count" => length(normalized_files),
    )
end

function stage_export(notes_dir::AbstractString; base_url::String=Stage.DEFAULT_BASE_URL, t_start::Integer=Stage.DEFAULT_T_START, t_end::Integer=Stage.DEFAULT_T_END, include_undated::Bool=true, stage_out::String=Stage.DEFAULT_OUT, stage_markdown_out::String=Stage.DEFAULT_MARKDOWN_OUT)
    existing_urls = Set{String}()
    try
        existing_urls = Stage.load_existing_source_urls(base_url=base_url)
    catch err
        println(stderr, "Warning: could not read live knowledge_item source URLs: ", sprint(showerror, err))
    end
    plan = Stage.plan_stage(notes_dir; existing_source_urls=existing_urls, t_start=t_start, t_end=t_end, include_undated=include_undated)
    Stage.write_json(stage_out, plan)
    Stage.write_markdown(stage_markdown_out, plan)
    return Dict("stage_out" => stage_out, "stage_markdown_out" => stage_markdown_out, "selected_note_count" => plan["selected_note_count"], "notes_total" => plan["notes_total"], "apply_ready" => plan["candidate_hg"]["apply_ready"])
end

function credential_status(credentials_path::AbstractString, token_path::AbstractString)
    return OAuth.credential_status(credentials_path, token_path)
end

function ensure_keep_access_token(credentials_path::AbstractString, token_path::AbstractString; request_json_fn=OAuth.request_json)
    if !isfile(token_path)
        error(string("Google Keep token file not found: ", token_path, "; run OAuth auth-listen or mint a delegated service-account token"))
    end

    token = OAuth.read_json(token_path)
    if !OAuth.token_needs_refresh(token)
        access_token = object_value(token, :access_token, nothing)
        if access_token === nothing || isempty(string(access_token))
            error("Google Keep token is missing access_token")
        end
        return string(access_token)
    end

    refresh = object_value(token, :refresh_token, nothing)
    if refresh !== nothing && !isempty(string(refresh))
        if !isfile(credentials_path)
            error(string("Google Keep token is expired and OAuth client file is missing: ", credentials_path))
        end
        credentials = OAuth.read_json(credentials_path)
        token = OAuth.refresh_token(credentials, token; request_json_fn=request_json_fn)
        write_json(token_path, token)
        access_token = object_value(token, :access_token, nothing)
        if access_token === nothing || isempty(string(access_token))
            error("Google Keep refreshed token is missing access_token")
        end
        return string(access_token)
    end

    delegated_subject = object_value(token, :delegated_subject, nothing)
    if delegated_subject !== nothing
        error(string("Delegated Google Keep token is expired for ", delegated_subject, "; rerun google_keep_service_account_token.mjs before ApiFetch"))
    end
    error("Google Keep token is expired and has no refresh_token; rerun auth-listen or mint a delegated service-account token")
end

function maybe_open_browser(url::AbstractString; enabled::Bool=false)
    enabled || return false
    try
        if Sys.iswindows()
            run(Cmd(["rundll32.exe", "url.dll,FileProtocolHandler", string(url)]))
        elseif Sys.isapple()
            run(`open $url`)
        else
            run(`xdg-open $url`)
        end
        return true
    catch err
        println(stderr, "Warning: could not open browser automatically: ", sprint(showerror, err))
        return false
    end
end

function authorize_with_loopback(credentials, token_path::AbstractString; scopes=DEFAULT_SCOPES, redirect_uri::String=DEFAULT_REDIRECT_URI, state=nothing, open_browser::Bool=false, request_json_fn=OAuth.request_json)
    port = OAuth.redirect_port(redirect_uri)
    server = listen(ip"127.0.0.1", port)
    client = nothing
    state_value = state === nothing || isempty(strip(string(state))) ? OAuth.random_state() : string(state)
    try
        url = authorization_url(credentials; scopes=scopes, redirect_uri=redirect_uri, state=state_value)
        println("Listening for Google OAuth redirect on ", redirect_uri)
        println("Open this URL to approve Google Keep access:")
        println(url)
        maybe_open_browser(url; enabled=open_browser)
        flush(stdout)

        code = nothing
        while code === nothing
            client = accept(server)
            request_line = OAuth.read_http_request_line(client)
            code = OAuth.maybe_callback_code_from_request_line(request_line; expected_state=state_value)
            if code === nothing
                OAuth.write_oauth_response(client, "Waiting for Google Keep authorization", "This local callback is waiting for Google's OAuth redirect. Keep the consent tab open.")
                close(client)
                client = nothing
            else
                OAuth.write_oauth_response(client, "Google Keep code captured", "The authorization code was received. Return to VS Code while the token is written locally.")
                close(client)
                client = nothing
            end
        end
        token = OAuth.exchange_code(credentials, code; redirect_uri=redirect_uri, request_json_fn=request_json_fn)
        write_json(token_path, token)
        return token
    catch err
        if client !== nothing
            try
                OAuth.write_oauth_response(client, "Google Keep authorization failed", "Return to VS Code for the error details.")
            catch
            end
        end
        rethrow(err)
    finally
        if client !== nothing
            close(client)
        end
        close(server)
    end
end

function parse_args(argv)
    options = Dict(
        "mode" => "check",
        "credentials" => DEFAULT_CLIENT_PATH,
        "token" => DEFAULT_TOKEN_PATH,
        "redirect-uri" => DEFAULT_REDIRECT_URI,
        "scope" => join(DEFAULT_SCOPES, " "),
        "open-browser" => "false",
        "code" => "",
        "state" => "",
        "out-dir" => DEFAULT_OUT_DIR,
        "out" => DEFAULT_RESULT_PATH,
        "page-size" => "100",
        "max-pages" => "20",
        "hydrate-details" => "true",
        "include-trashed" => "false",
        "stage" => "true",
        "stage-out" => Stage.DEFAULT_OUT,
        "stage-markdown-out" => Stage.DEFAULT_MARKDOWN_OUT,
        "base-url" => Stage.DEFAULT_BASE_URL,
        "t-start" => string(Stage.DEFAULT_T_START),
        "t-end" => string(Stage.DEFAULT_T_END),
        "include-undated" => "true",
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
    mode = options["mode"]

    if mode == "check"
        result = credential_status(options["credentials"], options["token"])
        result["calendar_oauth_client_present"] = isfile(CALENDAR_CLIENT_PATH)
        result["fallback_credentials_hint"] = result["credentials_present"] ? "default Keep client present" : (isfile(CALENDAR_CLIENT_PATH) ? string("Keep client missing; you may pass --credentials ", CALENDAR_CLIENT_PATH, " to reuse the existing Google OAuth app and write a separate Keep token") : "no local Google OAuth client file found")
        result["scope_diagnostics"] = scope_diagnostics(parse_scopes(options["scope"]))
        write_json(options["out"] == DEFAULT_RESULT_PATH ? DEFAULT_CREDENTIAL_CHECK_PATH : options["out"], result)
        println("Credentials present: ", result["credentials_present"])
        println("Token present: ", result["token_present"])
        println("Refresh token present: ", result["refresh_token_present"])
        println("Keep scope in discovery: ", result["scope_diagnostics"]["all_requested_scopes_in_keep_discovery"])
        return 0
    elseif mode == "auth-url"
        credentials = OAuth.read_json(options["credentials"])
        url = authorization_url(credentials; scopes=parse_scopes(options["scope"]), redirect_uri=options["redirect-uri"])
        println(url)
        return 0
    elseif mode == "auth-listen"
        credentials = OAuth.read_json(options["credentials"])
        authorize_with_loopback(credentials, options["token"]; scopes=parse_scopes(options["scope"]), redirect_uri=options["redirect-uri"], state=options["state"], open_browser=parse_bool(options["open-browser"]))
        println("Wrote OAuth token: ", options["token"])
        return 0
    elseif mode == "exchange-code"
        if isempty(strip(options["code"]))
            error("--code is required for --mode exchange-code")
        end
        credentials = OAuth.read_json(options["credentials"])
        token = OAuth.exchange_code(credentials, options["code"]; redirect_uri=options["redirect-uri"])
        write_json(options["token"], token)
        println("Wrote OAuth token: ", options["token"])
        return 0
    elseif mode == "fetch"
        access_token = ensure_keep_access_token(options["credentials"], options["token"])
        notes, pages, truncated = fetch_notes(
            access_token;
            page_size=parse(Int, options["page-size"]),
            max_pages=parse(Int, options["max-pages"]),
            hydrate_details=parse_bool(options["hydrate-details"]),
        )
        export_record = export_notes(notes, options["out-dir"]; include_trashed=parse_bool(options["include-trashed"]), access_token=access_token)
        result = Dict(
            "mode" => "fetch",
            "api" => "google_keep_v1",
            "scope" => options["scope"],
            "fetched_count" => length(notes),
            "pages" => pages,
            "truncated" => truncated,
            "export" => export_record,
            "stage" => nothing,
        )
        if parse_bool(options["stage"])
            result["stage"] = stage_export(
                export_record["notes_dir"];
                base_url=options["base-url"],
                t_start=parse(Int, options["t-start"]),
                t_end=parse(Int, options["t-end"]),
                include_undated=parse_bool(options["include-undated"]),
                stage_out=options["stage-out"],
                stage_markdown_out=options["stage-markdown-out"],
            )
        end
        write_json(options["out"], result)
        println("Wrote Google Keep fetch result: ", options["out"])
        println("Fetched notes: ", result["fetched_count"])
        println("Exported notes: ", export_record["written_count"])
        if result["stage"] !== nothing
            println("Staged selected notes: ", result["stage"]["selected_note_count"], " / ", result["stage"]["notes_total"])
        end
        return 0
    end

    error("unknown mode: ", mode)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(GoogleKeepFetch.main())
end
