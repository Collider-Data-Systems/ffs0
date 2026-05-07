#!/usr/bin/env julia

module GoogleCalendarWriter

using Dates
using Downloads
using JSON3
using Random
using Sockets

const DEFAULT_PLAN_PATH = "tmp/projections/google_calendar_projection_plan.json"
const DEFAULT_CLIENT_PATH = "secrets/google_calendar_oauth_client.json"
const DEFAULT_TOKEN_PATH = "secrets/google_calendar_token.json"
const DEFAULT_CALENDAR_ID = "primary"
const DEFAULT_REDIRECT_URI = "http://127.0.0.1:53682/"
const DEFAULT_SCOPES = ["https://www.googleapis.com/auth/calendar.events"]
const GOOGLE_CALENDAR_API = "https://www.googleapis.com/calendar/v3"

const COLOR_IDS = Dict(
    "purple" => "3",
    "red" => "11",
    "blue" => "9",
    "green" => "10",
    "yellow" => "5",
    "orange" => "6",
    "gray" => "8",
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

function urlencode(value)
    io = IOBuffer()
    for byte in codeunits(string(value))
        if (byte >= UInt8('A') && byte <= UInt8('Z')) ||
           (byte >= UInt8('a') && byte <= UInt8('z')) ||
           (byte >= UInt8('0') && byte <= UInt8('9')) ||
           byte in UInt8.(['-', '.', '_', '~'])
            write(io, byte)
        else
            print(io, '%')
            print(io, uppercase(string(byte; base=16, pad=2)))
        end
    end
    return String(take!(io))
end

function urldecode(value::AbstractString)
    io = IOBuffer()
    bytes = codeunits(value)
    i = 1
    while i <= length(bytes)
        byte = bytes[i]
        if byte == UInt8('+')
            write(io, UInt8(' '))
            i += 1
        elseif byte == UInt8('%') && i + 2 <= length(bytes)
            hex = String(bytes[i + 1:i + 2])
            write(io, UInt8(parse(Int, hex; base=16)))
            i += 3
        else
            write(io, byte)
            i += 1
        end
    end
    return String(take!(io))
end

form_encode(pairs) = join([string(urlencode(k), "=", urlencode(v)) for (k, v) in pairs], "&")

function query_value(url_or_code::AbstractString, key::AbstractString)
    marker = string(key, "=")
    text = string(url_or_code)
    index = findfirst(marker, text)
    if index === nothing
        return text
    end
    start = last(index) + 1
    stop = findnext('&', text, start)
    raw = stop === nothing ? text[start:end] : text[start:stop - 1]
    return urldecode(raw)
end

query_has_key(url_or_code::AbstractString, key::AbstractString) = findfirst(string(key, "="), string(url_or_code)) !== nothing

function redirect_port(redirect_uri::AbstractString)
    matched = match(r"^http://(?:127\.0\.0\.1|localhost):(\d+)/", string(redirect_uri))
    if matched === nothing
        error("auth-listen requires an http://127.0.0.1:<port>/ or http://localhost:<port>/ redirect URI")
    end
    return parse(Int, matched.captures[1])
end

function callback_code_from_request_line(request_line::AbstractString; expected_state=nothing)
    parts = split(request_line)
    target = length(parts) >= 2 ? parts[2] : ""
    if query_has_key(target, "error")
        error(string("Google OAuth error: ", query_value(target, "error")))
    end
    if expected_state !== nothing
        if !query_has_key(target, "state")
            error("OAuth redirect did not include state")
        end
        if query_value(target, "state") != expected_state
            error("OAuth redirect state did not match")
        end
    end
    if !query_has_key(target, "code")
        error("OAuth redirect did not include code")
    end
    return query_value(target, "code")
end

function maybe_callback_code_from_request_line(request_line::AbstractString; expected_state=nothing)
    parts = split(request_line)
    target = length(parts) >= 2 ? parts[2] : ""
    if query_has_key(target, "error") || query_has_key(target, "code") || query_has_key(target, "state")
        return callback_code_from_request_line(request_line; expected_state=expected_state)
    end
    return nothing
end

function read_http_request_line(client)
    request_line = readline(client)
    while !eof(client)
        line = readline(client)
        isempty(strip(line)) && break
    end
    return request_line
end

function write_oauth_response(client, title::AbstractString, message::AbstractString)
    body = string(
        "<!doctype html><html><head><meta charset=\"utf-8\"><title>", title,
        "</title><style>body{font-family:Segoe UI,Arial,sans-serif;margin:48px;line-height:1.5;color:#1f2937}main{max-width:620px}</style></head>",
        "<body><main><h1>", title, "</h1><p>", message, "</p></main></body></html>",
    )
    response = string(
        "HTTP/1.1 200 OK\r\n",
        "Content-Type: text/html; charset=utf-8\r\n",
        "Content-Length: ", ncodeunits(body), "\r\n",
        "Connection: close\r\n\r\n",
        body,
    )
    try
        write(client, response)
        flush(client)
    catch
        return false
    end
    return true
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

function utc_now()
    return now(UTC)
end

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
end

function parse_utc(value)
    text = replace(string(value), r"Z$" => "")
    return DateTime(text, dateformat"yyyy-mm-ddTHH:MM:SS")
end

function client_config(credentials)
    record = object_value(credentials, :installed, nothing)
    if record === nothing
        record = object_value(credentials, :web, nothing)
    end
    if record === nothing
        record = credentials
    end

    config = Dict(
        "client_id" => string(object_value(record, :client_id, "")),
        "client_secret" => string(object_value(record, :client_secret, "")),
        "auth_uri" => string(object_value(record, :auth_uri, "https://accounts.google.com/o/oauth2/v2/auth")),
        "token_uri" => string(object_value(record, :token_uri, "https://oauth2.googleapis.com/token")),
        "redirect_uris" => object_value(record, :redirect_uris, [DEFAULT_REDIRECT_URI]),
    )

    if isempty(config["client_id"])
        error("OAuth client credentials are missing client_id")
    end
    if isempty(config["client_secret"])
        error("OAuth client credentials are missing client_secret")
    end
    return config
end

function parse_scopes(scope_text::AbstractString)
    stripped = strip(scope_text)
    if isempty(stripped)
        return DEFAULT_SCOPES
    end
    return split(replace(stripped, ',' => ' '))
end

function random_state()
    alphabet = collect("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    return join(rand(alphabet, 24))
end

function authorization_url(credentials; scopes=DEFAULT_SCOPES, redirect_uri::String=DEFAULT_REDIRECT_URI, state::String=random_state())
    config = client_config(credentials)
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
    return string(config["auth_uri"], "?", form_encode(params))
end

function authorize_with_loopback(credentials, token_path::AbstractString; scopes=DEFAULT_SCOPES, redirect_uri::String=DEFAULT_REDIRECT_URI, state=nothing, request_json_fn=request_json)
    port = redirect_port(redirect_uri)
    server = listen(ip"127.0.0.1", port)
    client = nothing
    state_value = state === nothing || isempty(strip(string(state))) ? random_state() : string(state)
    try
        url = authorization_url(credentials; scopes=scopes, redirect_uri=redirect_uri, state=state_value)
        println("Listening for Google OAuth redirect on ", redirect_uri)
        println("Open this URL to approve Calendar access:")
        println(url)
        flush(stdout)

        code = nothing
        while code === nothing
            client = accept(server)
            request_line = read_http_request_line(client)
            code = maybe_callback_code_from_request_line(request_line; expected_state=state_value)
            if code === nothing
                write_oauth_response(client, "Waiting for Google Calendar authorization", "This local callback is waiting for Google's OAuth redirect. Keep the consent tab open.")
                close(client)
                client = nothing
            else
                write_oauth_response(client, "Google Calendar code captured", "The authorization code was received. Return to VS Code while the token is written locally.")
                close(client)
                client = nothing
            end
        end
        token = exchange_code(credentials, code; redirect_uri=redirect_uri, request_json_fn=request_json_fn)
        write_json(token_path, token)
        return token
    catch err
        if client !== nothing
            try
                write_oauth_response(client, "Google Calendar authorization failed", "Return to VS Code for the error details.")
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

function request_json(url::AbstractString; method::AbstractString="GET", bearer::AbstractString="", form=nothing, json_body=nothing, timeout::Real=30)
    headers = Pair{String, String}[]
    if !isempty(bearer)
        push!(headers, "Authorization" => string("Bearer ", bearer))
    end

    input_body = nothing
    if form !== nothing
        input_body = form_encode(form)
        push!(headers, "Content-Type" => "application/x-www-form-urlencoded")
    elseif json_body !== nothing
        input_body = JSON3.write(json_body)
        push!(headers, "Content-Type" => "application/json")
    end

    output = IOBuffer()
    response = if input_body === nothing
        Downloads.request(url; method=method, headers=headers, output=output, throw=false, timeout=timeout)
    else
        Downloads.request(url; input=IOBuffer(input_body), method=method, headers=headers, output=output, throw=false, timeout=timeout)
    end
    body = String(take!(output))
    parsed = isempty(strip(body)) ? Dict{String, Any}() : JSON3.read(body)

    if response.status < 200 || response.status >= 300
        message = object_value(parsed, :error_description, object_value(parsed, :error, response.message))
        error(string("HTTP ", response.status, " from ", url, ": ", message))
    end
    return parsed
end

function normalize_token(response; existing=nothing, now_utc::DateTime=utc_now())
    token = Dict{String, Any}()
    for key in ("access_token", "refresh_token", "scope", "token_type", "id_token")
        value = object_value(response, Symbol(key), nothing)
        if value !== nothing
            token[key] = value
        end
    end
    if !haskey(token, "refresh_token") && existing !== nothing
        refresh = object_value(existing, :refresh_token, nothing)
        if refresh !== nothing
            token["refresh_token"] = refresh
        end
    end
    expires_in = object_value(response, :expires_in, nothing)
    if expires_in !== nothing
        token["expires_at"] = format_utc(now_utc + Second(parse(Int, string(expires_in))))
    end
    token["obtained_at"] = format_utc(now_utc)
    return token
end

function token_needs_refresh(token; margin_seconds::Integer=120, now_utc::DateTime=utc_now())
    expires_at = object_value(token, :expires_at, nothing)
    if expires_at === nothing
        return true
    end
    return parse_utc(expires_at) <= now_utc + Second(margin_seconds)
end

function exchange_code(credentials, code::AbstractString; redirect_uri::String=DEFAULT_REDIRECT_URI, request_json_fn=request_json, now_utc::DateTime=utc_now())
    config = client_config(credentials)
    response = request_json_fn(
        config["token_uri"];
        method="POST",
        form=[
            "client_id" => config["client_id"],
            "client_secret" => config["client_secret"],
            "code" => query_value(code, "code"),
            "grant_type" => "authorization_code",
            "redirect_uri" => redirect_uri,
        ],
    )
    return normalize_token(response; now_utc=now_utc)
end

function refresh_token(credentials, token; request_json_fn=request_json, now_utc::DateTime=utc_now())
    refresh = object_value(token, :refresh_token, nothing)
    if refresh === nothing || isempty(string(refresh))
        error("OAuth token is missing refresh_token; run --mode auth-url, then --mode exchange-code")
    end
    config = client_config(credentials)
    response = request_json_fn(
        config["token_uri"];
        method="POST",
        form=[
            "client_id" => config["client_id"],
            "client_secret" => config["client_secret"],
            "refresh_token" => refresh,
            "grant_type" => "refresh_token",
        ],
    )
    return normalize_token(response; existing=token, now_utc=now_utc)
end

function ensure_access_token(credentials_path::AbstractString, token_path::AbstractString; request_json_fn=request_json)
    if !isfile(credentials_path)
        error(string("OAuth client file not found: ", credentials_path))
    end
    if !isfile(token_path)
        error(string("OAuth token file not found: ", token_path, "; run --mode auth-url and --mode exchange-code"))
    end
    credentials = read_json(credentials_path)
    token = read_json(token_path)
    if token_needs_refresh(token)
        token = refresh_token(credentials, token; request_json_fn=request_json_fn)
        write_json(token_path, token)
    end
    access_token = object_value(token, :access_token, nothing)
    if access_token === nothing || isempty(string(access_token))
        error("OAuth token is missing access_token")
    end
    return string(access_token)
end

function calendar_event_body(event)
    body = Dict{String, Any}(string(k) => v for (k, v) in event["google_event"])
    label = string(get(event, "calendar_label", ""))
    if !isempty(label) && haskey(COLOR_IDS, label) && !haskey(body, "colorId")
        body["colorId"] = COLOR_IDS[label]
    end
    return body
end

calendar_base(calendar_id::AbstractString) = string(GOOGLE_CALENDAR_API, "/calendars/", urlencode(calendar_id), "/events")

function find_existing_event(calendar_id::AbstractString, projection_id::AbstractString, access_token::AbstractString; request_json_fn=request_json)
    url = string(
        calendar_base(calendar_id),
        "?singleEvents=true&maxResults=1&privateExtendedProperty=",
        urlencode(string("moos_projection_id=", projection_id)),
    )
    response = request_json_fn(url; bearer=access_token)
    items = object_value(response, :items, [])
    return isempty(items) ? nothing : first(items)
end

function upsert_event(calendar_id::AbstractString, event, access_token::AbstractString; dry_run::Bool=false, request_json_fn=request_json)
    projection_id = string(event["projection_id"])
    body = calendar_event_body(event)
    source_urn = string(event["source_urn"])

    if dry_run
        return Dict(
            "source_urn" => source_urn,
            "projection_id" => projection_id,
            "action" => "dry-run",
            "summary" => body["summary"],
        )
    end

    existing = find_existing_event(calendar_id, projection_id, access_token; request_json_fn=request_json_fn)
    if existing === nothing
        response = request_json_fn(calendar_base(calendar_id); method="POST", bearer=access_token, json_body=body)
        return Dict(
            "source_urn" => source_urn,
            "projection_id" => projection_id,
            "action" => "insert",
            "google_event_id" => string(object_value(response, :id, "")),
        )
    end

    event_id = string(object_value(existing, :id, ""))
    if isempty(event_id)
        error("Google Calendar lookup returned an item without id")
    end
    url = string(calendar_base(calendar_id), "/", urlencode(event_id))
    response = request_json_fn(url; method="PATCH", bearer=access_token, json_body=body)
    return Dict(
        "source_urn" => source_urn,
        "projection_id" => projection_id,
        "action" => "patch",
        "google_event_id" => string(object_value(response, :id, event_id)),
    )
end

function write_plan(plan, calendar_id::AbstractString, access_token::AbstractString; dry_run::Bool=false, request_json_fn=request_json)
    events = object_value(plan, :events, [])
    results = Vector{Dict{String, Any}}()
    for event in events
        push!(results, upsert_event(calendar_id, event, access_token; dry_run=dry_run, request_json_fn=request_json_fn))
    end
    return Dict(
        "mode" => dry_run ? "dry-run" : "write",
        "calendar_id" => calendar_id,
        "event_count" => length(results),
        "results" => results,
    )
end

function parse_args(argv)
    options = Dict(
        "mode" => "dry-run",
        "plan" => DEFAULT_PLAN_PATH,
        "credentials" => DEFAULT_CLIENT_PATH,
        "token" => DEFAULT_TOKEN_PATH,
        "calendar-id" => DEFAULT_CALENDAR_ID,
        "redirect-uri" => DEFAULT_REDIRECT_URI,
        "scope" => join(DEFAULT_SCOPES, " "),
        "code" => "",
        "state" => "",
        "out" => "tmp/projections/google_calendar_write_result.json",
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

function credential_status(credentials_path::AbstractString, token_path::AbstractString)
    token_present = isfile(token_path)
    refresh_present = false
    expires_at = nothing
    if token_present
        token = read_json(token_path)
        refresh_present = object_value(token, :refresh_token, nothing) !== nothing
        expires_at = object_value(token, :expires_at, nothing)
    end
    return Dict(
        "credentials_path" => credentials_path,
        "credentials_present" => isfile(credentials_path),
        "token_path" => token_path,
        "token_present" => token_present,
        "refresh_token_present" => refresh_present,
        "expires_at" => expires_at,
    )
end

function main(argv=ARGS)
    options = parse_args(argv)
    mode = options["mode"]

    if mode == "check"
        result = credential_status(options["credentials"], options["token"])
        write_json(options["out"], result)
        println("Wrote credential check: ", options["out"])
        println("Credentials present: ", result["credentials_present"])
        println("Token present: ", result["token_present"])
        return 0
    elseif mode == "auth-url"
        credentials = read_json(options["credentials"])
        url = authorization_url(credentials; scopes=parse_scopes(options["scope"]), redirect_uri=options["redirect-uri"])
        println(url)
        return 0
    elseif mode == "auth-listen"
        credentials = read_json(options["credentials"])
        authorize_with_loopback(credentials, options["token"]; scopes=parse_scopes(options["scope"]), redirect_uri=options["redirect-uri"], state=options["state"])
        println("Wrote OAuth token: ", options["token"])
        return 0
    elseif mode == "exchange-code"
        if isempty(strip(options["code"]))
            error("--code is required for --mode exchange-code")
        end
        credentials = read_json(options["credentials"])
        token = exchange_code(credentials, options["code"]; redirect_uri=options["redirect-uri"])
        write_json(options["token"], token)
        println("Wrote OAuth token: ", options["token"])
        return 0
    elseif mode == "dry-run"
        plan = read_json(options["plan"])
        result = write_plan(plan, options["calendar-id"], ""; dry_run=true)
        write_json(options["out"], result)
        println("Wrote Google Calendar write dry-run: ", options["out"])
        println("Events: ", result["event_count"])
        return 0
    elseif mode == "write"
        plan = read_json(options["plan"])
        access_token = ensure_access_token(options["credentials"], options["token"])
        result = write_plan(plan, options["calendar-id"], access_token; dry_run=false)
        write_json(options["out"], result)
        println("Wrote Google Calendar write result: ", options["out"])
        println("Events: ", result["event_count"])
        return 0
    end

    error("unknown mode: ", mode)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(GoogleCalendarWriter.main())
end