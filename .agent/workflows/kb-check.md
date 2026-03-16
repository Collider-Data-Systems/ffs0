---
description: Check KB health — ontology, instances, superset, graph state consistency
---

# Knowledge Base Health Check

// turbo-all

## Steps

1. Check ontology SOT:
```powershell
$ontology = Get-Content ".\ffs0-factory-super\.agent\kb\superset\ontology.json" | ConvertFrom-Json
Write-Host "Types:" $ontology.types.Count "Morphisms:" $ontology.morphisms.Count
```

2. Count instance files:
```powershell
(Get-ChildItem ".\ffs0-factory-super\.agent\kb\instances" -Filter *.json).Count
```

3. Count superset files:
```powershell
(Get-ChildItem ".\ffs0-factory-super\.agent\kb\superset" -Filter *.json).Count
```

4. Verify kernel graph state matches KB:
```powershell
$health = Invoke-RestMethod "http://localhost:8000/healthz"
Write-Host "Nodes:" $health.nodes "Wires:" $health.wires "Log:" $health.log_depth
```

5. Check registry types match ontology:
```powershell
$registry = Invoke-RestMethod "http://localhost:8000/semantics/registry"
Write-Host "Registry types:" $registry.PSObject.Properties.Count
```

6. Report any discrepancies.
