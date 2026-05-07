using Dates
using Test

include(joinpath(@__DIR__, "..", "google_calendar_writer.jl"))

const GCW = GoogleCalendarWriter

@testset "Google Calendar writer" begin
    @testset "form encoding" begin
        @test GCW.urlencode("a b+c@example.com") == "a%20b%2Bc%40example.com"
        @test GCW.urldecode("a%20b%2Bc%40example.com") == "a b+c@example.com"
        @test GCW.query_value("http://127.0.0.1/?code=abc%20123&state=x", "code") == "abc 123"
        @test GCW.query_has_key("http://127.0.0.1/?code=abc%20123&state=x", "code")
        @test !GCW.query_has_key("http://127.0.0.1/?state=x", "code")
    end

    @testset "loopback callback parsing" begin
        @test GCW.redirect_port("http://127.0.0.1:53682/") == 53682
        @test GCW.redirect_port("http://localhost:53682/") == 53682
        @test GCW.callback_code_from_request_line("GET /?state=s1&code=abc%20123&scope=x HTTP/1.1"; expected_state="s1") == "abc 123"
        @test GCW.maybe_callback_code_from_request_line("GET /favicon.ico HTTP/1.1"; expected_state="s1") === nothing
        @test GCW.maybe_callback_code_from_request_line("GET /?state=s1&code=abc%20123&scope=x HTTP/1.1"; expected_state="s1") == "abc 123"
        @test_throws ErrorException GCW.callback_code_from_request_line("GET /?state=s2&code=abc HTTP/1.1"; expected_state="s1")
        @test_throws ErrorException GCW.callback_code_from_request_line("GET /?state=s1&error=access_denied HTTP/1.1"; expected_state="s1")
        @test_throws ErrorException GCW.redirect_port("https://example.com/callback")
    end

    @testset "client config and authorization URL" begin
        credentials = Dict(
            :installed => Dict(
                :client_id => "client-id",
                :client_secret => "client-secret",
                :auth_uri => "https://accounts.example/auth",
                :token_uri => "https://accounts.example/token",
                :redirect_uris => [GCW.DEFAULT_REDIRECT_URI],
            ),
        )
        config = GCW.client_config(credentials)
        @test config["client_id"] == "client-id"
        url = GCW.authorization_url(credentials; scopes=["scope/a", "scope/b"], redirect_uri="http://127.0.0.1:1/", state="state-1")
        @test startswith(url, "https://accounts.example/auth?")
        @test occursin("client_id=client-id", url)
        @test occursin("scope=scope%2Fa%20scope%2Fb", url)
        @test occursin("redirect_uri=http%3A%2F%2F127.0.0.1%3A1%2F", url)
    end

    @testset "token normalization" begin
        now_utc = DateTime("2026-05-06T18:00:00")
        response = Dict(:access_token => "access", :expires_in => 3600, :token_type => "Bearer")
        existing = Dict(:refresh_token => "refresh")
        token = GCW.normalize_token(response; existing=existing, now_utc=now_utc)
        @test token["access_token"] == "access"
        @test token["refresh_token"] == "refresh"
        @test token["expires_at"] == "2026-05-06T19:00:00Z"
        @test !GCW.token_needs_refresh(token; now_utc=DateTime("2026-05-06T18:10:00"))
        @test GCW.token_needs_refresh(token; now_utc=DateTime("2026-05-06T18:59:00"), margin_seconds=120)
    end

    @testset "exchange and refresh forms" begin
        credentials = Dict(:client_id => "client", :client_secret => "secret", :token_uri => "https://oauth.example/token")
        calls = []
        function fake_request(url; method="GET", bearer="", form=nothing, json_body=nothing)
            push!(calls, Dict(:url => url, :method => method, :bearer => bearer, :form => form, :json_body => json_body))
            return Dict(:access_token => "new-access", :refresh_token => "new-refresh", :expires_in => 60)
        end
        token = GCW.exchange_code(credentials, "http://127.0.0.1/?code=abc%20123"; request_json_fn=fake_request, now_utc=DateTime("2026-05-06T18:00:00"))
        @test token["refresh_token"] == "new-refresh"
        @test calls[1][:method] == "POST"
        @test Dict(calls[1][:form])["grant_type"] == "authorization_code"
        @test Dict(calls[1][:form])["code"] == "abc 123"

        empty!(calls)
        refreshed = GCW.refresh_token(credentials, token; request_json_fn=fake_request, now_utc=DateTime("2026-05-06T18:00:00"))
        @test refreshed["access_token"] == "new-access"
        @test Dict(calls[1][:form])["grant_type"] == "refresh_token"
    end

    @testset "dry-run write plan" begin
        event = Dict(
            "projection_id" => "moos-1",
            "source_urn" => "urn:moos:program:sam.demo",
            "calendar_label" => "purple",
            "google_event" => Dict(
                "summary" => "Demo",
                "start" => Dict("date" => "2026-05-06"),
                "end" => Dict("date" => "2026-05-07"),
                "extendedProperties" => Dict("private" => Dict("moos_projection_id" => "moos-1")),
            ),
        )
        result = GCW.write_plan(Dict("events" => [event]), "primary", ""; dry_run=true)
        @test result["mode"] == "dry-run"
        @test result["event_count"] == 1
        @test result["results"][1]["action"] == "dry-run"
        body = GCW.calendar_event_body(event)
        @test body["colorId"] == "3"
    end

    @testset "insert and patch upsert" begin
        event = Dict(
            "projection_id" => "moos-2",
            "source_urn" => "urn:moos:program:sam.demo",
            "calendar_label" => "red",
            "google_event" => Dict(
                "summary" => "Demo",
                "start" => Dict("date" => "2026-05-06"),
                "end" => Dict("date" => "2026-05-07"),
                "extendedProperties" => Dict("private" => Dict("moos_projection_id" => "moos-2")),
            ),
        )

        calls = []
        function fake_insert(url; method="GET", bearer="", form=nothing, json_body=nothing)
            push!(calls, Dict(:url => url, :method => method, :json_body => json_body))
            if method == "GET"
                return Dict(:items => [])
            end
            return Dict(:id => "created-id")
        end
        inserted = GCW.upsert_event("primary", event, "access"; request_json_fn=fake_insert)
        @test inserted["action"] == "insert"
        @test calls[end][:method] == "POST"
        @test calls[end][:json_body]["colorId"] == "11"

        empty!(calls)
        function fake_patch(url; method="GET", bearer="", form=nothing, json_body=nothing)
            push!(calls, Dict(:url => url, :method => method, :json_body => json_body))
            if method == "GET"
                return Dict(:items => [Dict(:id => "existing-id")])
            end
            return Dict(:id => "existing-id")
        end
        patched = GCW.upsert_event("primary", event, "access"; request_json_fn=fake_patch)
        @test patched["action"] == "patch"
        @test calls[end][:method] == "PATCH"
        @test occursin("existing-id", calls[end][:url])
    end
end