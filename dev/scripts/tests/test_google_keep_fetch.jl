using Dates
using JSON3
using Test

include(joinpath(@__DIR__, "..", "google_keep_fetch.jl"))

const GKeep = GoogleKeepFetch

@testset "Google Keep API fetcher" begin
    @testset "normalizes text notes" begin
        note = Dict(
            :name => "notes/demo-note",
            :title => "T206 storyboard",
            :createTime => "2026-05-26T12:00:00Z",
            :updateTime => "2026-05-26T12:30:00.123Z",
            :body => Dict(:text => Dict(:text => "G ingest keeps cloud fixes")),
        )
        normalized = GKeep.normalize_note(note)
        @test normalized["title"] == "T206 storyboard"
        @test normalized["textContent"] == "G ingest keeps cloud fixes"
        @test normalized["apiName"] == "notes/demo-note"
        @test normalized["sourceUrl"] == "https://keep.googleapis.com/v1/notes/demo-note"
        @test normalized["createdTimestampUsec"] > 0
        @test normalized["userEditedTimestampUsec"] > 0
    end

    @testset "normalizes list notes" begin
        note = Dict(
            :name => "notes/list-note",
            :title => "T200",
            :body => Dict(:list => Dict(:listItems => [
                Dict(:text => Dict(:text => "Ux"), :checked => false),
                Dict(:text => Dict(:text => "FG OUT IN"), :checked => true, :childListItems => [Dict(:text => Dict(:text => "Clock dns"), :checked => false)]),
            ])),
        )
        text = GKeep.note_text(note)
        @test occursin("[ ] Ux", text)
        @test occursin("[x] FG OUT IN", text)
        @test occursin("Clock dns", text)
        normalized = GKeep.normalize_note(note)
        @test length(normalized["listContent"]) == 3
    end

    @testset "fetches pages and details" begin
        calls = []
        function fake_request(url; method="GET", bearer="", form=nothing, json_body=nothing)
            push!(calls, url)
            if occursin("v1/notes?", url)
                return Dict(:notes => [Dict(:name => "notes/a")], :nextPageToken => "")
            end
            return Dict(:name => "notes/a", :title => "A", :body => Dict(:text => Dict(:text => "manifold GPU cache")))
        end
        notes, pages, truncated = GKeep.fetch_notes("access"; page_size=50, max_pages=3, request_json_fn=fake_request)
        @test pages == 1
        @test truncated == false
        @test length(notes) == 1
        @test notes[1][:title] == "A"
        @test any(url -> occursin("pageSize=50", url), calls)
        @test any(url -> endswith(url, "/v1/notes/a"), calls)
    end

    @testset "exports staged JSON" begin
        mktempdir() do dir
            notes = Any[Dict(:name => "notes/a", :title => "T206 API", :updateTime => "2026-05-26T12:00:00Z", :body => Dict(:text => Dict(:text => "session Keep API staging")))]
            export_record = GKeep.export_notes(notes, dir)
            @test export_record["written_count"] == 1
            @test isfile(export_record["normalized_files"][1])
            parsed = JSON3.read(read(export_record["normalized_files"][1], String))
            @test parsed.sourceUrl == "https://keep.googleapis.com/v1/notes/a"
        end
    end

    @testset "auth URL uses Keep scope" begin
        credentials = Dict(:installed => Dict(:client_id => "client", :client_secret => "secret", :auth_uri => "https://accounts.example/auth", :token_uri => "https://accounts.example/token"))
        url = GKeep.authorization_url(credentials; scopes=GKeep.DEFAULT_SCOPES, redirect_uri=GKeep.DEFAULT_REDIRECT_URI, state="keep-state")
        @test startswith(url, GKeep.GOOGLE_OAUTH_V2_AUTH_URI)
        @test occursin("scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fkeep.readonly", url)
        @test occursin("redirect_uri=http%3A%2F%2F127.0.0.1%3A53683%2F", url)
    end

    @testset "reports Keep scope blocker" begin
        diagnostics = GKeep.scope_diagnostics(GKeep.DEFAULT_SCOPES)
        @test diagnostics["all_requested_scopes_in_keep_discovery"] == true
        @test occursin("invalid_scope", diagnostics["observed_blocker"])
        @test any(action -> occursin("Google Keep API", action), diagnostics["operator_action"])
    end
end