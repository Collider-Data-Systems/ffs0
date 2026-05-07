#!/usr/bin/env julia

module SessionContextProjection

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_SESSION_URN = "urn:moos:session:sam.governance"
const DEFAULT_ACTOR_URN = "urn:moos:agent:claude-code.hp-laptop"
const DEFAULT_PATTERN_URN = "urn:moos:pattern:session-affordance-pack"
const DEFAULT_SKILLS_DIR = "dev/claude-skills"
const DEFAULT_OUT_BASE = "tmp/projections/session_context/current_session"
const DEFAULT_SKILL_LIMIT = 5

const CORE_SKILL_WEIGHTS = Dict(
    "moos-state-readback" => 7,
    "moos-tooling-dx" => 6,
    "moos-rewrite-envelope" => 6,
    "moos-categorical-research" => 4,
    "moos-running-state-validator" => 4,
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

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
end

function plan_session_context_projection(nodes, relations;
    session_urn::String=DEFAULT_SESSION_URN,
    actor_urn::String=DEFAULT_ACTOR_URN,
    focus::String="",
    skill_catalog=Any[],
    skill_limit::Integer=DEFAULT_SKILL_LIMIT,
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
        "context" => context,
        "relations" => Dict(
            "outgoing" => [relation_summary(rel) for rel in outgoing],
            "incoming" => [relation_summary(rel) for rel in incoming],
        ),
        "affordance_pack" => Dict(
            "source_pattern_urn" => DEFAULT_PATTERN_URN,
            "available_skill_count" => length(skill_catalog),
            "recommended_skills" => recommended,
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
                ". Treat this chat as the current session occasion; derive skills/tools from purpose and scope before emitting rewrites."
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
        "focus" => "session context projection for VS Code, agents, harnesses, and graph visualization",
        "skills-dir" => DEFAULT_SKILLS_DIR,
        "skill-limit" => string(DEFAULT_SKILL_LIMIT),
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
    plan = plan_session_context_projection(
        nodes,
        relations;
        session_urn=options["session-urn"],
        actor_urn=options["actor-urn"],
        focus=options["focus"],
        skill_catalog=skills,
        skill_limit=parse(Int, options["skill-limit"]),
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
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(SessionContextProjection.main())
end
