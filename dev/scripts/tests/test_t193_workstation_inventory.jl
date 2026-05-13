using Test
using JSON3

include(joinpath(@__DIR__, "..", "t193_workstation_inventory.jl"))

const Inventory = T193WorkstationInventory

prop(value) = Dict(:value => value, :mutability => "mutable")

function write_record(io, envelope; log_seq)
    JSON3.write(io, Dict(:envelope => envelope, :log_seq => log_seq, :applied_at => "2026-05-13T12:00:00Z"))
    println(io)
end

@testset "T193 workstation inventory" begin
    mktempdir() do dir
        log_path = joinpath(dir, "moos.jsonl")
        open(log_path, "w") do io
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:user:sam", :type_id => "user", :properties => Dict(:name => prop("sam"))), log_seq=1)
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:workstation:hp-laptop", :type_id => "workstation", :properties => Dict(:hostname => prop("hp-laptop"))), log_seq=2)
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:ws:hp-z440", :type_id => "workstation", :properties => Dict()), log_seq=3)
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:kernel:hp-laptop.primary", :type_id => "kernel", :properties => Dict(:status => prop("active"))), log_seq=4)
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:session:sam.governance", :type_id => "session", :properties => Dict(:status => prop("active"))), log_seq=5)
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:agent:claude-code.hp-laptop", :type_id => "agent", :properties => Dict(:name => prop("Guido"))), log_seq=6)
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:purpose:sam.doctrine-governance-and-delegation", :type_id => "purpose", :properties => Dict(:title => prop("Governance"))), log_seq=7)
            write_record(io, Dict(:rewrite_type => "ADD", :node_urn => "urn:moos:program:sam.t193.workstation-inventory", :type_id => "program", :properties => Dict(:title => prop("T193 inventory"), :status => prop("planned"))), log_seq=8)
            write_record(io, Dict(:rewrite_type => "LINK", :relation_urn => "urn:moos:rel:hp-laptop.hosts.primary", :src_urn => "urn:moos:workstation:hp-laptop", :src_port => "hosts", :tgt_urn => "urn:moos:kernel:hp-laptop.primary", :tgt_port => "hosted-on", :rewrite_category => "WF03"), log_seq=9)
            write_record(io, Dict(:rewrite_type => "LINK", :relation_urn => "urn:moos:rel:temporary", :src_urn => "urn:moos:user:sam", :src_port => "owns", :tgt_urn => "urn:moos:session:sam.governance", :tgt_port => "owned-by", :rewrite_category => "WF01"), log_seq=10)
            write_record(io, Dict(:rewrite_type => "UNLINK", :relation_urn => "urn:moos:rel:temporary"), log_seq=11)
            write_record(io, Dict(:rewrite_type => "MUTATE", :target_urn => "urn:moos:program:sam.t193.workstation-inventory", :field => "status", :new_value => "active"), log_seq=12)
        end

        topology = Dict(
            :expected_ontology_version => "3.16.1",
            :kernels => Dict(
                Symbol("hp-laptop.primary") => Dict(:urn => "urn:moos:kernel:hp-laptop.primary", :host => "hp-laptop", :http_local => "http://localhost:8000", :mcp_server => "moos-hp-laptop-primary", :seats => ["urn:moos:session:sam.governance"]),
                Symbol("hp-z440.primary") => Dict(:urn => "urn:moos:kernel:hp-z440.primary", :host => "hp-z440", :http_lan => "http://192.168.1.11:8000", :mcp_server => "moos-primary", :seats => ["urn:moos:session:sam.kernel-proper"]),
            ),
            :personas => Dict(
                :guido => Dict(:actor_urn => "urn:moos:agent:claude-code.hp-laptop", :session_urn => "urn:moos:session:sam.governance", :opens_on_kernel => "hp-laptop.primary", :emit_kernel => "hp-laptop.primary", :mcp_server => "moos-hp-laptop-primary"),
            ),
        )

        state = Inventory.fold_jsonl_log(log_path)
        inventory = Inventory.plan_inventory(
            log_state=state,
            topology=topology,
            reachable_hosts=["hp-laptop", "hppro"],
            offline_hosts=["hp-z440"],
            planned_hosts=["hppro"],
            generated_at="2026-05-13T13:54:00Z",
            t_day="193",
        )

        @test inventory["projection_kind"] == "t193_workstation_inventory"
        @test inventory["source"]["max_log_seq"] == 12
        @test length(inventory["host_matrix"]) == 3
        hosts = Dict(row["host"] => row for row in inventory["host_matrix"])
        @test hosts["hp-laptop"]["status"] == "reachable-now"
        @test hosts["hp-z440"]["status"] == "offline-now"
        @test hosts["hppro"]["status"] == "reachable-now"
        @test hosts["hppro"]["present_in_hg"] == false
        @test inventory["hppro_candidates"][1]["kernel_urn"] == "urn:moos:kernel:hppro.primary"
        requested = Dict(row["type_id"] => row for row in inventory["requested_type_inventory"])
        @test requested["workstation"]["count"] == 2
        @test requested["program"]["nodes"][1]["status"] == "active"
        categories = Dict(row["name"] => row["count"] for row in inventory["relation_inventory"]["by_category"])
        @test categories["WF03"] == 1
        @test !haskey(categories, "WF01")

        json_path = joinpath(dir, "inventory.json")
        md_path = joinpath(dir, "inventory.md")
        Inventory.write_json(json_path, inventory)
        Inventory.write_markdown(md_path, inventory)
        @test isfile(json_path)
        markdown = read(md_path, String)
        @test occursin("T193 Workstation Inventory", markdown)
        @test occursin("How To Read This", markdown)
        @test occursin("HP Pro Candidate", markdown)
        @test occursin("urn:moos:kernel:hppro.primary", markdown)
        @test occursin("Z440", markdown)
    end
end