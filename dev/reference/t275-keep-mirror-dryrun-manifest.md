# T8 - Keep->Drive mirror DRY-RUN manifest (t275, gate G4)

What ONE run of Invoke-KeepDriveMirror.ps1 would push outward, measured from scratch/keep/t195-t206. Nothing has been pushed; $OutRoot does not exist; both rclone remotes currently point at OTHER accounts - fix before any run.

TOTAL: 185 files, 25.32 MB

| ext | files | MB |
|---|---|---|
| .json | 150 | 0.49 |
| .png | 26 | 17.30 |
| .jpg | 9 | 7.52 |

IMAGES (the family-photo exposure class): 35 files, 24.83 MB - largest 10:
- api/attachments/20260722-t263-12-47-1ekaf2-tjybtewpv4y5u5xzovqwtulypfebtt-ramtno/03-1wl15nhN4uh6SU7gOb6sZfC0ksT4iwDIjqt3QHcIA2VYKmZlq9K6eLx5RlzGVH0k.png (3305 KB)
- api/attachments/20260718-t259-17-37-manifold-mo-os-so-om-engine-code-re-write-an/01-1YDRsBd59yE_i5yjqzE0HMhzFyhX3qailS_nRHJwqROci5bcTUu30k1WFHnRIVnw.png (3089 KB)
- api/attachments/20260802-t274-14-11yirdtesl2ikppmi2-tjdaor-k0pbskwrpqvw9hv-liqzm/01-16wtfdFWr8Jqk9YKk7xCtAvP9rzSnvgyJW6IdvZ8B5zRQCsey7th7_SuwNIPNQVO_xwEI.jpg (2641 KB)
- api/attachments/20260716-t249-ae-continuity-achieved-1a8jnl1kkrrp3s9fspqrb7dxdrw/01-1hX0iEVivJ8wYnBAZ0Yx_Pcs46wHs9_gAOqsPtAEpgn3uFnC76YPnFncxRRd6nEM9cYGC.jpg (1321 KB)
- api/attachments/20260725-t266-1ltpq-ujyqvob6ysgs1qr6mcj3o5lxnydo7rvqycbibh0vn2ij/01-1zod6CZ5M9zm0UX8_nhGEG1l6bbVQztgpDVV7fZMTxHv856RdJI9eSfuVbWare8M8_sed.jpg (1228 KB)
- api/attachments/20260718-t259-17-37-manifold-mo-os-so-om-engine-code-re-write-an/02-1-obX7YtMxMV4lyIaAX517zMdXBshumhZsk5OQhk5-8yNmt-rTOpjG_Q5eRI.png (1215 KB)
- api/attachments/20260724-t265-1511-on-axes-of-topology-help-me-lingo-1i5rfxle2xr/01-1D81FBQQHkyair15htSZw2APgOqECQT7CVj7I_6gVsRB5oA-_cfwalnCBsoKPZQ.png (1144 KB)
- api/attachments/20260726-t265-1511-on-axes-of-topology-help-me-lingo-1i5rfxle2xr/01-1D81FBQQHkyair15htSZw2APgOqECQT7CVj7I_6gVsRB5oA-_cfwalnCBsoKPZQ.png (1144 KB)
- api/attachments/20260724-t265-1511-on-axes-of-topology-help-me-lingo-1i5rfxle2xr/06-1-ZWHg89fDIkqYmhS9k1GkEBTnzxMlRpqPx3wW4HkRd1vXb_8z9rg7YeEL028hiw.png (1011 KB)
- api/attachments/20260722-t263-12-47-1ekaf2-tjybtewpv4y5u5xzovqwtulypfebtt-ramtno/02-1zCCFzdfpkKwMeG7AlVyTrMa0IG0jqT5dOedFTa_qIFWP7q0nJC40NClFXrBg.png (773 KB)

DECISION SHAPE (D7/G4): (a) notes-only (md/json, no attachments) | (b) allowlist named notes | (c) full mirror | (d) no mirror. Plus: name the DESTINATION account+folder explicitly.
