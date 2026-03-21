# mo:os Development Automation Script

function Show-Help {
    Write-Host "Usage: .\dev.ps1 <command>"
    Write-Host "Commands:"
    Write-Host "  boot     - Start kernel with KB hydration"
    Write-Host "  test     - Run all Go tests in the kernel"
    Write-Host "  validate - Run ontology validation"
    Write-Host "  health   - Check kernel health endpoint"
}

$cmd = $args[0]
$root = "C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super"

switch ($cmd) {
    "boot" {
        cd "$root\..\moos\platform\kernel"
        go run ./cmd/moos --kb "$root\.agent\kb" --hydrate
    }
    "test" {
        cd "$root\..\moos\platform\kernel"
        go test -v ./...
    }
    "validate" {
        cd "$root\.agent\kb"
        python validate.py
    }
    "health" {
        curl -s http://localhost:8000/healthz
    }
    default {
        Show-Help
    }
}
