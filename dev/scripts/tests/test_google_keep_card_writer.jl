using Dates
using JSON3
using Test

include(joinpath(@__DIR__, "..", "google_keep_card_writer.jl"))

const Cards = GoogleKeepCardWriter
const CardStage = GoogleKeepCardWriter.Stage

const FIXTURE_GENERATED_AT = "2026-07-08T19:50:01Z"
const FIXTURE_T_DAY = 259
const FIXTURE_DATE = "2026-07-18"

fixture_card_query() = Dict{String, Any}("fleet" => true, "per_workspace" => "occupied-active", "include_birth" => false)

function fixture_rows()
    return Any[
        Dict("persona" => "Zappa", "agent" => "claude-cowork.hp-z440", "workspace" => "sam.z440-cowork-workspace", "engine" => "hp-z440.primary", "engine_port" => ":8000", "emit" => "hp-z440.primary", "surface" => "Claude Code / Cowork pane · Z440 · `ffs0.code-workspace`", "mcp" => "moos-primary", "purpose" => "sam.cowork-workspace-curation"),
        Dict("persona" => "Steinberger", "agent" => "vscode.hp-z440.menno", "workspace" => "sam.steinberger-seat", "engine" => "hp-z440.menno", "engine_port" => ":8001", "emit" => "hp-z440.primary", "surface" => "VS Code · Z440 (desktop 3) · `moos-router`", "mcp" => "moos-primary *(opens-on `moos-menno`)*", "purpose" => "sam.tooling-ergonomics-and-dx"),
        Dict("persona" => "Wolfram", "agent" => "vscode.hp-laptop.wolfram", "workspace" => "sam.kernel-proper", "engine" => "hp-z440.primary", "engine_port" => ":8000", "emit" => "hp-z440.primary", "surface" => "VS Code · hp-laptop · `ffs0.code-workspace`", "mcp" => "moos-primary", "purpose" => "sam.kernel-implementation-z440"),
        Dict("persona" => "John Lydon (governance)", "agent" => "claude-cowork.hp-laptop", "workspace" => "sam.governance", "engine" => "hp-laptop.primary", "engine_port" => ":8000", "emit" => "hp-laptop.primary", "surface" => "Claude Desktop / Cowork · hp-laptop · `ffs0.code-workspace`", "mcp" => "moos-hp-laptop-primary", "purpose" => "sam.doctrine-governance-and-delegation"),
        Dict("persona" => "Φ(purpose)?", "agent" => "menno", "workspace" => "menno.birth-workspace", "engine" => "hp-z440.menno", "engine_port" => ":8001", "emit" => "", "surface" => "—", "mcp" => "", "purpose" => ""),
        Dict("persona" => "John Lydon (governance)", "agent" => "claude-cowork.hp-laptop", "workspace" => "sam.governance", "engine" => "hp-laptop.primary", "engine_port" => ":8000", "emit" => "hp-laptop.primary", "surface" => "Claude Desktop / Cowork · hp-laptop · `ffs0.code-workspace`", "mcp" => "moos-hp-laptop-primary", "purpose" => "sam.doctrine-governance-and-delegation"),
    ]
end

function fixture_cards(; kwargs...)
    return Cards.build_cards(
        fixture_rows();
        card_query=fixture_card_query(),
        t_day=FIXTURE_T_DAY,
        date=FIXTURE_DATE,
        ontology_version="4.0.2",
        gate_status="warn",
        gate_summary=Dict{String, Any}("pass" => 23, "warn" => 1, "fail" => 0),
        workstation_order=["hp-z440", "hp-laptop", "hpprodesk"],
        skills_by_session=Dict("urn:moos:session:sam.z440-cowork-workspace" => ["skill-1", "skill-2", "skill-3", "skill-4", "skill-5", "skill-6", "skill-7"]),
        desktops_by_session=Dict("urn:moos:session:sam.steinberger-seat" => 3),
        generated_at=FIXTURE_GENERATED_AT,
        kwargs...,
    )
end

card_by_slug(cards, slug) = only([card for card in cards if card["slug"] == slug])

@testset "Google Keep card writer" begin
    @testset "sentinel and title self-check" begin
        @test CardStage.is_generated_card_title("[moos-ws] fleet")
        @test CardStage.is_generated_card_title("[moos-ws] kernel-proper")
        @test !CardStage.is_generated_card_title("T259 keep as workspace surface")
        @test !CardStage.is_generated_card_title("groceries")
        @test CardStage.explicit_t_day("[moos-ws] fleet") === nothing
        @test CardStage.explicit_t_day("T259 foo") == 259
        @test Cards.assert_card_titles([Dict("title" => "[moos-ws] kernel-proper")]) == true
        @test_throws ErrorException Cards.assert_card_titles([Dict("title" => "[moos-ws] T259 foo")])
        @test_throws ErrorException Cards.assert_card_titles([Dict("title" => "no sentinel here")])
    end

    @testset "per-workspace card builder" begin
        cards = fixture_cards()
        zappa = card_by_slug(cards, "z440-cowork-workspace")
        @test zappa["title"] == "[moos-ws] z440-cowork-workspace"
        @test startswith(zappa["body"], "Zappa\n")
        @test occursin("T=259 (2026-07-18)", zappa["body"])
        @test occursin("Agent: claude-cowork.hp-z440", zappa["body"])
        @test occursin("Engine: hp-z440.primary :8000", zappa["body"])
        @test !occursin("(emit", zappa["body"])
        @test occursin("Purpose: sam.cowork-workspace-curation", zappa["body"])
        @test !occursin("`", zappa["body"])
        @test occursin("skill-5", zappa["body"])
        @test !occursin("skill-6", zappa["body"])
        @test endswith(zappa["body"], Cards.card_footer(FIXTURE_GENERATED_AT))

        steinberger = card_by_slug(cards, "steinberger-seat")
        @test occursin("Engine: hp-z440.menno :8001 (emit hp-z440.primary)", steinberger["body"])
        @test occursin("Desktop: 3", steinberger["body"])
        @test occursin("MCP: moos-primary (opens-on moos-menno)", steinberger["body"])
    end

    @testset "card char limit flag" begin
        cards = fixture_cards()
        @test all(card -> card["over_limit"] == false, cards)
        @test all(card -> card["char_count"] == length(card["body"]), cards)
        long_row = Dict("persona" => "Zappa", "agent" => "claude-cowork.hp-z440", "workspace" => "sam.z440-cowork-workspace", "engine" => "hp-z440.primary", "engine_port" => ":8000", "emit" => "hp-z440.primary", "surface" => "", "mcp" => "", "purpose" => repeat("x", 1600))
        long_card = Cards.build_workspace_card(long_row; t_day=FIXTURE_T_DAY, date=FIXTURE_DATE, generated_at=FIXTURE_GENERATED_AT)
        @test long_card["over_limit"] == true
        @test long_card["char_count"] > Cards.CARD_CHAR_LIMIT
    end

    @testset "hash stability excludes footer" begin
        row = fixture_rows()[1]
        first_pass = Cards.build_workspace_card(row; t_day=FIXTURE_T_DAY, date=FIXTURE_DATE, generated_at="2026-07-08T19:50:01Z")
        second_pass = Cards.build_workspace_card(row; t_day=FIXTURE_T_DAY, date=FIXTURE_DATE, generated_at="2026-07-09T09:00:00Z")
        @test first_pass["text_sha1"] == second_pass["text_sha1"]
        @test first_pass["footer"] != second_pass["footer"]
        @test first_pass["body"] != second_pass["body"]
        @test first_pass["text_sha1"] == CardStage.text_hash(string(first_pass["title"], "\n", first_pass["body_core"]))
        rotated = Cards.build_workspace_card(row; t_day=FIXTURE_T_DAY + 1, date="2026-07-19", generated_at="2026-07-08T19:50:01Z")
        @test rotated["text_sha1"] != first_pass["text_sha1"]
    end

    @testset "fleet card and selection" begin
        cards = fixture_cards()
        @test length(cards) == 5
        @test [card["slug"] for card in cards[2:end]] == ["z440-cowork-workspace", "steinberger-seat", "kernel-proper", "governance"]

        fleet = card_by_slug(cards, "fleet")
        @test fleet["title"] == "[moos-ws] fleet"
        @test startswith(fleet["body"], "mo:os fleet\n")
        @test occursin("T=259 (2026-07-18)", fleet["body"])
        @test occursin("Ontology: v4.0.2", fleet["body"])
        @test occursin("Gate: warn (pass 23 / warn 1 / fail 0)", fleet["body"])
        @test occursin("hp-z440:", fleet["body"])
        @test occursin("hp-laptop:", fleet["body"])
        @test occursin("- kernel-proper (Wolfram)", fleet["body"])
        @test occursin("- governance (John Lydon (governance))", fleet["body"])
        @test !occursin("birth-workspace", fleet["body"])
        @test findfirst("hp-z440:", fleet["body"]).start < findfirst("hp-laptop:", fleet["body"]).start

        fleet_only = fixture_cards(; cards_mode="fleet")
        @test length(fleet_only) == 1
        @test fleet_only[1]["slug"] == "fleet"

        per_workspace_only = fixture_cards(; cards_mode="per-workspace")
        @test length(per_workspace_only) == 4

        single = fixture_cards(; card_slug="governance")
        @test length(single) == 1
        @test single[1]["slug"] == "governance"
        @test_throws ErrorException fixture_cards(; card_slug="no-such-slug")

        @test_throws ErrorException Cards.build_cards(Any[]; card_query=fixture_card_query(), t_day=FIXTURE_T_DAY, date=FIXTURE_DATE)
        birth_only = Any[fixture_rows()[5]]
        @test_throws ErrorException Cards.build_cards(birth_only; card_query=fixture_card_query(), t_day=FIXTURE_T_DAY, date=FIXTURE_DATE)
    end

    @testset "planned action against local index" begin
        cards = fixture_cards()
        fleet = card_by_slug(cards, "fleet")
        empty_index = Dict{String, Any}("pending_deletes" => Any[])
        @test Cards.planned_action(fleet, empty_index) == "create"
        matching_index = Dict{String, Any}(
            "pending_deletes" => Any[],
            "fleet" => Dict{String, Any}("apiName" => "notes/abc", "title" => fleet["title"], "text_sha1" => fleet["text_sha1"], "written_at" => FIXTURE_GENERATED_AT),
        )
        @test Cards.planned_action(fleet, matching_index) == "skip"
        matching_index["fleet"]["text_sha1"] = "0000000000000000000000000000000000000000"
        @test Cards.planned_action(fleet, matching_index) == "rotate"
    end

    @testset "CLI arg parsing covers write and cleanup" begin
        options = Cards.parse_args(["--mode", "write", "--cards", "fleet", "--card-slug", "fleet", "--delete-orphans", "true"])
        @test options["mode"] == "write"
        @test options["cards"] == "fleet"
        @test options["card-slug"] == "fleet"
        @test options["delete-orphans"] == "true"
        cleanup = Cards.parse_args(["--mode", "cleanup", "--confirm", "true"])
        @test cleanup["mode"] == "cleanup"
        @test cleanup["confirm"] == "true"
        defaults = Cards.parse_args(String[])
        @test defaults["mode"] == "plan"
        @test defaults["cards"] == "both"
        @test_throws ErrorException Cards.parse_args(["--unknown", "x"])
        @test_throws ErrorException Cards.parse_args(["--mode"])
        @test_throws ErrorException Cards.parse_args(["--cards", "everything"])
        @test_throws ErrorException Cards.parse_args(["positional"])
    end
end
