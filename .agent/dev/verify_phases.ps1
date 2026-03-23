$r = Invoke-RestMethod 'http://localhost:8000/state'

# Phase 10: Firestarter
$firestarter = $r.nodes.'urn:moos:agent:firestarter'
Write-Host "`n--- Phase 10: Firestarter Node ---"
$firestarter | ConvertTo-Json -Depth 5

# Phase 5: category-master
$catmaster = $r.nodes.'urn:moos:tool:category-master'
Write-Host "`n--- Phase 5: category-master ---"
$catmaster | ConvertTo-Json -Depth 5

# Phase 6: article-extractor
$extractor = $r.nodes.'urn:moos:tool:article-extractor'
Write-Host "`n--- Phase 6: article-extractor ---"
$extractor | ConvertTo-Json -Depth 5

# Phase 7: Industry Entities
Write-Host "`n--- Phase 7: Industry Entities ---"
$entities = @('urn:moos:industry:kaggle-agi-cognitive-benchmark-2026', 'urn:moos:industry:google-developer-knowledge-api-mcp', 'urn:moos:industry:chrome-webmcp-preview')
foreach ($urn in $entities) {
    $node = $r.nodes.$urn
    Write-Host "URN: $urn"
    $node | ConvertTo-Json -Depth 5
}

# Phase 8: OWNS Wires
Write-Host "`n--- Phase 8: OWNS Wires ---"
$extractor_wires = Invoke-RestMethod 'http://localhost:8000/state/wires/incoming/urn:moos:tool:article-extractor'
$extractor_wires | ConvertTo-Json -Depth 5
