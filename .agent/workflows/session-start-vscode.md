---
description: Start a VS Code session by claiming pending delegation_task work from the graph
---

# Session Start (VS Code)

## Steps

1. Verify kernel is healthy:

```powershell
Invoke-RestMethod http://localhost:8000/healthz | ConvertTo-Json -Compress
```

2. Query pending delegation tasks assigned to VS Code:

```powershell
$lens = Invoke-RestMethod "http://localhost:8000/state/lens?kind=delegation_task"
$tasks = @($lens.nodes.PSObject.Properties.Value) |
  Where-Object {
    $_.payload.assigned_to -match "vscode-ai|vscode" -and $_.payload.status -eq "pending"
  } |
  Sort-Object updated_at
$tasks | Select-Object urn,@{n='title';e={$_.payload.title}},@{n='phase_id';e={$_.payload.phase_id}}
```

3. Claim the first pending task by setting status to in_progress:

```powershell
$task = $tasks | Select-Object -First 1
if ($null -ne $task) {
  $payload = @{}
  foreach ($p in $task.payload.PSObject.Properties) { $payload[$p.Name] = $p.Value }
  $payload.status = "in_progress"
  $payload.started_at = (Get-Date).ToUniversalTime().ToString("o")

  $env = @{
    type = "MUTATE"
    actor = "urn:moos:agent:vscode-ai"
    mutate = @{
      urn = $task.urn
      expected_version = [int]$task.version
      payload = $payload
    }
  }
  Invoke-RestMethod "http://localhost:8000/morphisms" -Method Post -ContentType "application/json" -Body ($env | ConvertTo-Json -Depth 20 -Compress)
}
```

4. Confirm the claimed task state:

```powershell
if ($null -ne $task) {
  Invoke-RestMethod ("http://localhost:8000/state/nodes/" + $task.urn) | ConvertTo-Json -Depth 8
}
```

5. Execute the claimed task and checkpoint completion in graph with a channel_message linked to the task PRG.
