#!/usr/bin/env julia

module SessionContextProjection

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:vscode.hp-laptop.copilot"
const DEFAULT_HARNESS_KIND = "VS Code/Copilot"
const DEFAULT_HARNESS_AGENT_URN = ""
const DEFAULT_HARNESS_EVIDENCE = "VS Code GitHub Copilot chat surface"
const DEFAULT_PATTERN_URN = "urn:moos:pattern:session-affordance-pack"
const DEFAULT_SKILLS_DIR = "dev/claude-skills"
const DEFAULT_EXTENSIONS_DIR = joinpath(homedir(), ".vscode", "extensions")
const DEFAULT_MCP_CONFIGS = ".vscode/mcp.json.example"
const DEFAULT_OUT_BASE = "tmp/projections/session_pipeline/session_context/current_session"
const DEFAULT_SKILL_LIMIT = 5
const DEFAULT_EXTENSION_LIMIT = 8

const CORE_SKILL_WEIGHTS = Dict(
    "moos-state-readback" => 7,
    "moos-tooling-dx" => 6,
    "moos-rewrite-envelope" => 6,
    "moos-categorical-research" => 4,
    "moos-running-state-validator" => 4,
)

const CORE_EXTENSION_WEIGHTS = Dict(
    "anthropic.claude-code" => 9,
    "upstash.context7-mcp" => 8,
    "github.vscode-pull-request-github" => 7,
    "eamodio.gitlens" => 6,
    "github.vscode-github-actions" => 5,
    "google.geminicodeassist" => 5,
    "ms-vscode.vscode-chat-customizations-evaluations" => 5,
    "ms-python.python" => 4,
    "ms-toolsai.jupyter" => 4,
    "golang.go" => 3,
    "ms-vscode.powershell" => 3,
)

const STOP_WORDS = Set([
    "and", "the", "for", "with", "that", "this", "from", "into", "when", "use", "uses",
    "current", "moos", "urn", "agent", "kernel", "session", "context",
])

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

function node_title(node)
    for field in (:title, :name, :display_name, :summary)
        value = prop_value(node, field, nothing)
        if value !== nothing && !isempty(strip(string(value)))
            return string(value)
        end
    end
    return string(object_value(node, :urn, "<unknown>"))
end

function node_summary(node)
    node === nothing && return nothing
    fields = Dict{String, Any}()
    for field in (:status, :seat_role, :local_t, :scope, :summary, :owner_urn, :subject_urn, :target_state)
        value = prop_value(node, field, nothing)
        if value !== nothing && !isempty(strip(string(value)))
            fields[string(field)] = value
        end
    end
    return Dict(
        "urn" => string(object_value(node, :urn, "")),
        "type_id" => string(object_value(node, :type_id, "")),
        "title" => node_title(node),
        "properties" => fields,
    )
end

function relation_summary(rel)
    return Dict(
        "urn" => string(object_value(rel, :urn, "")),
        "rewrite_category" => string(object_value(rel, :rewrite_category, "")),
        "src_urn" => string(object_value(rel, :src_urn, "")),
        "src_port" => string(object_value(rel, :src_port, "")),
        "tgt_urn" => string(object_value(rel, :tgt_urn, "")),
        "tgt_port" => string(object_value(rel, :tgt_port, "")),
    )
end

function nodes_by_urn(nodes)
    result = Dict{String, Any}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        !isempty(urn) && (result[urn] = node)
    end
    return result
end

function node_summaries(index, urns)
    result = Any[]
    for urn in urns
        if haskey(index, urn)
            push!(result, node_summary(index[urn]))
        else
            push!(result, Dict("urn" => urn, "type_id" => "<missing>", "title" => urn, "properties" => Dict()))
        end
    end
    return result
end

function outgoing_relations(relations, urn::AbstractString)
    return [rel for rel in relations if string(object_value(rel, :src_urn, "")) == urn]
end

function incoming_relations(relations, urn::AbstractString)
    return [rel for rel in relations if string(object_value(rel, :tgt_urn, "")) == urn]
end

function targets_by_port(relations, port::AbstractString)
    return sort(unique([
        string(object_value(rel, :tgt_urn, "")) for rel in relations
        if string(object_value(rel, :src_port, "")) == port && !isempty(string(object_value(rel, :tgt_urn, "")))
    ]))
end

function sources_by_port(relations, port::AbstractString)
    return sort(unique([
        string(object_value(rel, :src_urn, "")) for rel in relations
        if string(object_value(rel, :src_port, "")) == port && !isempty(string(object_value(rel, :src_urn, "")))
    ]))
end

function contains_urn(urns, urn::AbstractString)
    needle = strip(string(urn))
    isempty(needle) && return false
    return needle in Set(string(item) for item in urns)
end

function identity_reconciliation(index, occupant_urns;
    actor_urn::String,
    harness_kind::String="",
    harness_agent_urn::String="",
    harness_evidence::String="",
)
    clean_actor = strip(actor_urn)
    clean_harness_agent = strip(harness_agent_urn)
    actor_node_exists = !isempty(clean_actor) && haskey(index, clean_actor)
    actor_is_hg_occupant = contains_urn(occupant_urns, clean_actor)
    harness_agent_node_exists = !isempty(clean_harness_agent) && haskey(index, clean_harness_agent)
    harness_agent_is_hg_occupant = contains_urn(occupant_urns, clean_harness_agent)
    harness_matches_actor = isempty(clean_harness_agent) || clean_harness_agent == clean_actor

    status = "pass"
    reasons = String[]
    next_action = ""
    if isempty(clean_actor)
        status = "fail"
        push!(reasons, "no actor_urn was supplied")
        next_action = "Regenerate with an explicit --actor-urn that is also the WF19 has-occupant target."
    elseif !actor_node_exists
        status = "fail"
        push!(reasons, "actor node is missing from folded HG state")
        next_action = "ADD or select the correct agent node before using this session header."
    elseif !actor_is_hg_occupant
        status = "fail"
        push!(reasons, "actor_urn is not the current WF19 has-occupant target for this session")
        next_action = "Rotate the session occupant or regenerate the pack with the current HG occupant."
    end
    if !harness_matches_actor
        status = status == "fail" ? "fail" : "warn"
        push!(reasons, "harness agent candidate differs from actor_urn")
        isempty(next_action) && (next_action = "Choose whether the live IDE harness should rotate the HG occupant or stay as S0 staging only.")
    end
    if !isempty(clean_harness_agent) && actor_node_exists && !harness_agent_node_exists
        status = status == "fail" ? "fail" : "warn"
        push!(reasons, "harness agent candidate is not an HG node")
        isempty(next_action) && (next_action = "Land the harness agent as HG topology or remove it from the durable handoff header.")
    end
    isempty(reasons) && push!(reasons, "actor_urn, HG occupant, and harness candidate agree")

    return Dict(
        "status" => status,
        "actor_urn" => clean_actor,
        "actor_node_exists" => actor_node_exists,
        "actor_is_hg_occupant" => actor_is_hg_occupant,
        "hg_occupant_urns" => [string(urn) for urn in occupant_urns],
        "harness_kind" => strip(harness_kind),
        "harness_agent_urn" => clean_harness_agent,
        "harness_agent_node_exists" => harness_agent_node_exists,
        "harness_agent_is_hg_occupant" => harness_agent_is_hg_occupant,
        "harness_matches_actor" => harness_matches_actor,
        "harness_evidence" => strip(harness_evidence),
        "reasons" => reasons,
        "next_action" => next_action,
        "rule" => "HG occupant is WF19 topology; IDE harness conversation is S0/G-ingest substrate until reconciled into an agent node and has-occupant relation.",
    )
end

function strip_wrapping_quotes(value::AbstractString)
    text = strip(value)
    if ncodeunits(text) >= 2
        first_char = first(text)
        last_char = last(text)
        if (first_char == '"' && last_char == '"') || (first_char == '\'' && last_char == '\'')
            return text[nextind(text, firstindex(text)):prevind(text, lastindex(text))]
        end
    end
    return text
end

function read_frontmatter(path::AbstractString)
    lines = readlines(path)
    if isempty(lines) || strip(lines[1]) != "---"
        return Dict{String, String}()
    end
    fields = Dict{String, String}()
    for line in lines[2:end]
        strip(line) == "---" && break
        matched = match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        matched === nothing && continue
        fields[matched.captures[1]] = strip_wrapping_quotes(matched.captures[2])
    end
    return fields
end

function string_array(value)
    value === nothing && return String[]
    value isa AbstractString && return [String(value)]
    try
        return [string(item) for item in value]
    catch
        return String[]
    end
end

function load_skill_catalog(skills_dir::AbstractString)
    if isempty(skills_dir) || !isdir(skills_dir)
        return Any[]
    end
    skills = Any[]
    for dir in sort(filter(isdir, readdir(skills_dir; join=true)))
        skill_path = joinpath(dir, "SKILL.md")
        isfile(skill_path) || continue
        frontmatter = read_frontmatter(skill_path)
        name = get(frontmatter, "name", basename(dir))
        description = get(frontmatter, "description", "")
        push!(skills, Dict(
            "name" => name,
            "description" => description,
            "path" => skill_path,
        ))
    end
    return skills
end

function extension_id(package, fallback::AbstractString)
    publisher = lowercase(strip(string(object_value(package, :publisher, ""))))
    name = lowercase(strip(string(object_value(package, :name, ""))))
    if !isempty(publisher) && !isempty(name)
        return string(publisher, ".", name)
    end
    return lowercase(fallback)
end

function load_extension_catalog(extensions_dir::AbstractString)
    if isempty(extensions_dir) || !isdir(extensions_dir)
        return Any[]
    end
    extensions = Any[]
    seen = Set{String}()
    for dir in sort(filter(isdir, readdir(extensions_dir; join=true)))
        package_path = joinpath(dir, "package.json")
        isfile(package_path) || continue
        package = try
            JSON3.read(read(package_path, String))
        catch
            continue
        end
        id = extension_id(package, basename(dir))
        key = string(id, "@", object_value(package, :version, ""))
        key in seen && continue
        push!(seen, key)
        contributes = object_value(package, :contributes, nothing)
        push!(extensions, Dict(
            "id" => id,
            "name" => string(object_value(package, :name, basename(dir))),
            "display_name" => string(object_value(package, :displayName, object_value(package, :name, basename(dir)))),
            "publisher" => string(object_value(package, :publisher, "")),
            "version" => string(object_value(package, :version, "")),
            "description" => string(object_value(package, :description, "")),
            "categories" => string_array(object_value(package, :categories, nothing)),
            "keywords" => string_array(object_value(package, :keywords, nothing)),
            "path" => package_path,
            "contributes_mcp" => contributes !== nothing && object_value(contributes, :mcpServerDefinitionProviders, nothing) !== nothing,
        ))
    end
    return extensions
end

function split_paths(raw::AbstractString)
    return [String(strip(part)) for part in split(raw, ';') if !isempty(strip(part))]
end

function load_mcp_catalog(config_paths::Vector{String})
    servers = Any[]
    for config_path in config_paths
        if isempty(config_path) || !isfile(config_path)
            continue
        end
        config = try
            JSON3.read(read(config_path, String))
        catch
            continue
        end
        records = object_value(config, :servers, Dict())
        for (name, record) in pairs(records)
            server_name = string(name)
            startswith(server_name, "_comment") && continue
            record isa AbstractString && continue
            headers = object_value(record, :headers, nothing)
            env = object_value(record, :env, nothing)
            args = object_value(record, :args, nothing)
            command = string(object_value(record, :command, ""))
            server_type = string(object_value(record, :type, isempty(command) ? "" : "stdio"))
            push!(servers, Dict(
                "name" => server_name,
                "type" => server_type,
                "url" => string(object_value(record, :url, "")),
                "command" => command,
                "arg_count" => args === nothing ? 0 : length(args),
                "header_names" => headers === nothing ? String[] : [string(key) for key in keys(headers)],
                "env_names" => env === nothing ? String[] : [string(key) for key in keys(env)],
                "source_path" => config_path,
            ))
        end
    end
    sort!(servers; by=server -> (server["source_path"], server["name"]))
    return servers
end

function tokenize(text::AbstractString)
    normalized = replace(lowercase(text), r"[^a-z0-9]+" => " ")
    return Set([token for token in split(normalized) if length(token) > 2 && !(token in STOP_WORDS)])
end

function score_skill(skill, focus_tokens)
    name = string(skill["name"])
    haystack = lowercase(string(name, " ", get(skill, "description", "")))
    score = get(CORE_SKILL_WEIGHTS, name, 0)
    for token in focus_tokens
        occursin(token, haystack) && (score += 1)
    end
    occursin("session", haystack) && (score += 2)
    occursin("projection", haystack) && (score += 2)
    occursin("harness", haystack) && (score += 1)
    return score
end

function score_extension(extension, focus_tokens)
    categories = get(extension, "categories", String[])
    keywords = get(extension, "keywords", String[])
    id = string(extension["id"])
    haystack = lowercase(join([
        id,
        string(get(extension, "display_name", "")),
        string(get(extension, "description", "")),
        join(categories, " "),
        join(keywords, " "),
    ], " "))
    score = get(CORE_EXTENSION_WEIGHTS, id, 0)
    for token in focus_tokens
        occursin(token, haystack) && (score += 1)
    end
    occursin("mcp", haystack) && (score += 3)
    occursin("chat", haystack) && (score += 2)
    occursin("ai", haystack) && (score += 2)
    occursin("github", haystack) && (score += 2)
    get(extension, "contributes_mcp", false) && (score += 4)
    category_set = Set(lowercase.(categories))
    keyword_set = Set(lowercase.(keywords))
    theme_requested = "theme" in focus_tokens || "themes" in focus_tokens
    if !theme_requested && ("themes" in category_set || "theme" in keyword_set || occursin("theme", id))
        score -= 8
    end
    return score
end

function rank_skills(skills; focus::AbstractString="", limit::Integer=DEFAULT_SKILL_LIMIT)
    focus_tokens = tokenize(focus)
    ranked = Any[]
    for skill in skills
        score = score_skill(skill, focus_tokens)
        score <= 0 && continue
        push!(ranked, Dict(
            "name" => string(skill["name"]),
            "score" => score,
            "description" => string(get(skill, "description", "")),
            "path" => string(get(skill, "path", "")),
        ))
    end
    sort!(ranked; by=item -> (-item["score"], item["name"]))
    return ranked[1:min(limit, length(ranked))]
end

function rank_extensions(extensions; focus::AbstractString="", limit::Integer=DEFAULT_EXTENSION_LIMIT)
    focus_tokens = tokenize(focus)
    ranked = Any[]
    for extension in extensions
        score = score_extension(extension, focus_tokens)
        score <= 0 && continue
        push!(ranked, Dict(
            "id" => string(extension["id"]),
            "score" => score,
            "display_name" => string(get(extension, "display_name", "")),
            "version" => string(get(extension, "version", "")),
            "categories" => get(extension, "categories", String[]),
            "keywords" => get(extension, "keywords", String[]),
            "contributes_mcp" => get(extension, "contributes_mcp", false),
            "description" => string(get(extension, "description", "")),
        ))
    end
    sort!(ranked; by=item -> (-item["score"], item["id"]))
    return ranked[1:min(limit, length(ranked))]
end

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
end

function plan_session_context_projection(nodes, relations;
    session_urn::String=DEFAULT_SESSION_URN,
    actor_urn::String=DEFAULT_ACTOR_URN,
    harness_kind::String=DEFAULT_HARNESS_KIND,
    harness_agent_urn::String=DEFAULT_HARNESS_AGENT_URN,
    harness_evidence::String=DEFAULT_HARNESS_EVIDENCE,
    focus::String="",
    skill_catalog=Any[],
    skill_limit::Integer=DEFAULT_SKILL_LIMIT,
    extension_catalog=Any[],
    extension_limit::Integer=DEFAULT_EXTENSION_LIMIT,
    mcp_servers=Any[],
    health=nothing,
    generated_at::String=format_utc(now(UTC)),
    base_url::String=DEFAULT_BASE_URL,
)
    index = nodes_by_urn(nodes)
    haskey(index, session_urn) || error("session node not found: ", session_urn)

    session = index[session_urn]
    outgoing = outgoing_relations(relations, session_urn)
    incoming = incoming_relations(relations, session_urn)

    opens_on_urns = targets_by_port(outgoing, "opens-on")
    occupant_urns = targets_by_port(outgoing, "has-occupant")
    purpose_urns = targets_by_port(outgoing, "has-purpose")
    scope_urns = targets_by_port(outgoing, "pins-urn")
    tool_urns = targets_by_port(outgoing, "mounts-tool")
    owner_urns = sources_by_port(incoming, "owns")
    effective_harness_agent_urn = isempty(strip(harness_agent_urn)) ? actor_urn : harness_agent_urn
    identity = identity_reconciliation(index, occupant_urns;
        actor_urn=actor_urn,
        harness_kind=harness_kind,
        harness_agent_urn=effective_harness_agent_urn,
        harness_evidence=harness_evidence,
    )

    context = Dict(
        "opens_on" => node_summaries(index, opens_on_urns),
        "occupants" => node_summaries(index, occupant_urns),
        "purposes" => node_summaries(index, purpose_urns),
        "scope_roots" => node_summaries(index, scope_urns),
        "mounted_tools" => node_summaries(index, tool_urns),
        "owners" => node_summaries(index, owner_urns),
    )

    purpose_titles = join([string(item["title"]) for item in context["purposes"]], " ")
    purpose_color = isempty(purpose_urns) ? focus : purpose_titles
    skill_focus = join([
        focus,
        node_title(session),
        purpose_titles,
        "session context projection vscode ide agent harness julia graph visual affordance pack",
    ], " ")
    recommended = rank_skills(skill_catalog; focus=skill_focus, limit=skill_limit)
    recommended_extensions = rank_extensions(extension_catalog; focus=skill_focus, limit=extension_limit)

    return Dict(
        "mode" => "plan",
        "projection_kind" => "session_context_pack",
        "source" => "hg_folded_state",
        "generated_at" => generated_at,
        "base_url" => base_url,
        "health" => health === nothing ? Dict() : health,
        "session_urn" => session_urn,
        "actor_urn" => actor_urn,
        "focus" => focus,
        "session" => node_summary(session),
        "purpose_color" => purpose_color,
        "identity" => identity,
        "context" => context,
        "relations" => Dict(
            "outgoing" => [relation_summary(rel) for rel in outgoing],
            "incoming" => [relation_summary(rel) for rel in incoming],
        ),
        "affordance_pack" => Dict(
            "source_pattern_urn" => DEFAULT_PATTERN_URN,
            "available_skill_count" => length(skill_catalog),
            "recommended_skills" => recommended,
            "available_extension_count" => length(extension_catalog),
            "recommended_extensions" => recommended_extensions,
            "mcp_servers" => mcp_servers,
        ),
        "handoff" => Dict(
            "session_header" => Dict(
                "actor" => actor_urn,
                "session_urn" => session_urn,
                "kernel_base_url" => base_url,
            ),
            "prompt_seed" => string(
                "Use actor=", actor_urn,
                " and session_urn=", session_urn,
                ". Treat this chat as S0 conversation staging; verify the HG occupant, actor_urn, and IDE harness candidate before emitting rewrites. Derive skills, extensions, MCP servers, and tools from purpose and scope."
            ),
        ),
    )
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

function urn_line(items)
    isempty(items) && return "<none>"
    return join([string(item["urn"]) for item in items], ", ")
end

function write_item_list(io, title::AbstractString, items)
    println(io, "## ", title)
    if isempty(items)
        println(io, "- <none>")
    else
        for item in items
            println(io, "- ", item["urn"], " (", item["type_id"], ") - ", item["title"])
        end
    end
    println(io)
end

function write_markdown(path::AbstractString, plan)
    dir = dirname(path)
    !isempty(dir) && mkpath(dir)
    open(path, "w") do io
        println(io, "# mo:os Session Context Pack")
        println(io)
        println(io, "Generated: ", plan["generated_at"])
        println(io, "Base URL: ", plan["base_url"])
        println(io, "Session: ", plan["session_urn"])
        println(io, "Actor: ", plan["actor_urn"])
        !isempty(strip(string(plan["focus"]))) && println(io, "Focus: ", plan["focus"])
        !isempty(strip(string(plan["purpose_color"]))) && println(io, "Purpose color: ", plan["purpose_color"])
        println(io)
        println(io, "A session is a purpose-colored occasion of rewrite. This projection is dry: it compiles folded HG state into a handoff artifact and does not emit rewrites or edit IDE config.")
        println(io)
        identity = plan["identity"]
        println(io, "## Identity Reconciliation")
        println(io, "- Status: ", identity["status"])
        println(io, "- Actor: ", identity["actor_urn"])
        println(io, "- HG occupants: ", isempty(identity["hg_occupant_urns"]) ? "<none>" : join(identity["hg_occupant_urns"], ", "))
        println(io, "- Harness: ", isempty(identity["harness_kind"]) ? "<unspecified>" : identity["harness_kind"])
        !isempty(identity["harness_agent_urn"]) && println(io, "- Harness agent candidate: ", identity["harness_agent_urn"])
        !isempty(identity["harness_evidence"]) && println(io, "- Harness evidence: ", identity["harness_evidence"])
        println(io, "- Rule: ", identity["rule"])
        println(io)
        context = plan["context"]
        write_item_list(io, "Kernel Place", context["opens_on"])
        write_item_list(io, "Occupants", context["occupants"])
        write_item_list(io, "Purposes", context["purposes"])
        if isempty(context["purposes"]) && !isempty(strip(string(plan["purpose_color"])))
            println(io, "No `has-purpose` relation was found for this session; the focus string is acting as the temporary purpose color for this occasion.")
            println(io)
        end
        write_item_list(io, "Scope Roots", context["scope_roots"])
        write_item_list(io, "Mounted Tools", context["mounted_tools"])
        write_item_list(io, "Owners", context["owners"])
        println(io, "## Recommended Skills")
        recommended = plan["affordance_pack"]["recommended_skills"]
        if isempty(recommended)
            println(io, "- <none>")
        else
            for skill in recommended
                println(io, "- ", skill["name"], " (score ", skill["score"], ")")
            end
        end
        println(io)
        println(io, "## Recommended VS Code Extensions")
        extensions = plan["affordance_pack"]["recommended_extensions"]
        if isempty(extensions)
            println(io, "- <none>")
        else
            for extension in extensions
                marker = extension["contributes_mcp"] ? " MCP" : ""
                println(io, "- ", extension["id"], " ", extension["version"], " (score ", extension["score"], ")", marker)
            end
        end
        println(io)
        println(io, "## MCP Servers")
        servers = plan["affordance_pack"]["mcp_servers"]
        if isempty(servers)
            println(io, "- <none>")
        else
            for server in servers
                location = isempty(server["url"]) ? server["command"] : server["url"]
                println(io, "- ", server["name"], " (", server["type"], ") - ", location)
            end
        end
        println(io)
        println(io, "## Handoff")
        println(io, "```text")
        println(io, plan["handoff"]["prompt_seed"])
        println(io, "```")
    end
end

function parse_args(argv)
    options = Dict(
        "base-url" => DEFAULT_BASE_URL,
        "session-urn" => DEFAULT_SESSION_URN,
        "actor-urn" => DEFAULT_ACTOR_URN,
        "harness-kind" => DEFAULT_HARNESS_KIND,
        "harness-agent-urn" => DEFAULT_HARNESS_AGENT_URN,
        "harness-evidence" => DEFAULT_HARNESS_EVIDENCE,
        "focus" => "session context projection for VS Code, agents, harnesses, and graph visualization",
        "skills-dir" => DEFAULT_SKILLS_DIR,
        "skill-limit" => string(DEFAULT_SKILL_LIMIT),
        "extensions-dir" => DEFAULT_EXTENSIONS_DIR,
        "extension-limit" => string(DEFAULT_EXTENSION_LIMIT),
        "mcp-configs" => DEFAULT_MCP_CONFIGS,
        "out-base" => DEFAULT_OUT_BASE,
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
    nodes, relations, health = load_state(options)
    skills = load_skill_catalog(options["skills-dir"])
    extensions = load_extension_catalog(options["extensions-dir"])
    mcp_servers = load_mcp_catalog(split_paths(options["mcp-configs"]))
    plan = plan_session_context_projection(
        nodes,
        relations;
        session_urn=options["session-urn"],
        actor_urn=options["actor-urn"],
        harness_kind=options["harness-kind"],
        harness_agent_urn=options["harness-agent-urn"],
        harness_evidence=options["harness-evidence"],
        focus=options["focus"],
        skill_catalog=skills,
        skill_limit=parse(Int, options["skill-limit"]),
        extension_catalog=extensions,
        extension_limit=parse(Int, options["extension-limit"]),
        mcp_servers=mcp_servers,
        health=health,
        base_url=options["base-url"],
    )

    json_path = string(options["out-base"], ".json")
    markdown_path = string(options["out-base"], ".md")
    write_json(json_path, plan)
    write_markdown(markdown_path, plan)
    println("Wrote session context projection JSON: ", json_path)
    println("Wrote session context projection Markdown: ", markdown_path)
    println("Recommended skills: ", length(plan["affordance_pack"]["recommended_skills"]))
    println("Recommended extensions: ", length(plan["affordance_pack"]["recommended_extensions"]))
    println("MCP servers: ", length(plan["affordance_pack"]["mcp_servers"]))
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(SessionContextProjection.main())
end
