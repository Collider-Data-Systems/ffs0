using Dates
using JSON3
using Test

include(joinpath(@__DIR__, "..", "keep_t195_t206_ingest_stage.jl"))

const Stage = KeepT195T206IngestStage

function write_json(path, value)
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function timestamp_usec(dt::DateTime)
    return Int(round(datetime2unix(dt) * 1_000_000))
end

@testset "T206 Keep loose-thought ingest stage" begin
    mktempdir() do dir
        keep_dir = joinpath(dir, "Keep")
        mkpath(keep_dir)
        t200_path = joinpath(keep_dir, "manifold-compute.json")
        write_json(t200_path, Dict(
            "title" => "Manifold compute and Macrohard",
            "textContent" => "mo:os is a manifold object operations surface. Rust, assembly, GPU, CUDA, HDC presets and HG projections belong in a distributed hyperware compute network.",
            "userEditedTimestampUsec" => timestamp_usec(DateTime(2026, 5, 20, 14, 50, 0)),
            "labels" => [Dict("name" => "moos")],
        ))

        old_path = joinpath(keep_dir, "old-note.json")
        write_json(old_path, Dict(
            "title" => "Old note",
            "textContent" => "T190 outside current ingest window",
            "userEditedTimestampUsec" => timestamp_usec(DateTime(2026, 5, 10, 12, 0, 0)),
        ))

        undated_path = joinpath(keep_dir, "loose.html")
        write(undated_path, "<html><head><title>Loose staging</title></head><body><h1>Loose staging</h1><p>Keep this IDE conversation as S0 source until reviewed.</p></body></html>")

        plan = Stage.plan_stage(keep_dir; existing_source_urls=Set{String}(), include_undated=true, generated_at="2026-05-26T12:50:00Z")

        @test plan["projection_kind"] == "t206_keep_loose_thought_ingest_stage"
        @test plan["source"]["exists"] == true
        @test plan["notes_total"] == 3
        @test plan["selected_note_count"] == 2
        @test plan["excluded_note_count"] == 1
        @test plan["buckets"]["t_days"]["T200"] == 1
        @test plan["buckets"]["t_days"]["undated"] == 1
        @test haskey(plan["buckets"]["themes"], "manifold_compute")
        @test haskey(plan["buckets"]["themes"], "runtime_substrate")
        @test haskey(plan["buckets"]["themes"], "accelerator_cache")
        @test plan["candidate_hg"]["apply_ready"] == false
        @test plan["candidate_hg"]["candidate_node_count"] == 8
        @test any(node -> node["type_id"] == "knowledge_item" && node["review_status"] == "source_structured", plan["candidate_hg"]["candidate_nodes"])
        @test any(node -> node["type_id"] == "knowledge_item" && node["review_status"] == "needs_date_review", plan["candidate_hg"]["candidate_nodes"])
        @test any(rel -> rel["rewrite_category"] == "WF12" && rel["src_urn"] == Stage.DEFAULT_CHANNEL_URN, plan["candidate_hg"]["candidate_relations"])
        @test occursin("review-only", plan["candidate_hg"]["apply_boundary"])

        duplicate_plan = Stage.plan_stage(keep_dir; existing_source_urls=Set([Stage.source_url(t200_path)]), include_undated=false, generated_at="2026-05-26T12:50:00Z")
        @test duplicate_plan["selected_note_count"] == 0
        @test duplicate_plan["excluded_note_count"] == 3
        @test any(row -> row["reason"] == "duplicate_source", duplicate_plan["excluded_notes"])
    end
end