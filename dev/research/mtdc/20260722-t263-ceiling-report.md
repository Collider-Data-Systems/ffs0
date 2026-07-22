# T263 MTDC ceiling report — game netcode, sequencers, protocols, clocks, hardware

> Produced 2026-07-22 (T=263) by an 11-agent web-verified survey workflow (5 domain researchers, 5 adversarial number-checkers, 1 synthesizer), commissioned by Sam in the t263 Zappa Strategy convo to establish the upper ceiling before fixing frame-length numbers. Verifier corrections applied inline; per-domain confidence all HIGH. Companion to dev/design/t263_notes_on_strategy*.pdf and the staged ki:s0.t263-strategy-recovery ingest.

CEILING REPORT — MTDC frame architecture (3x Windows Xeon workstation, GbE LAN, Tailscale/WireGuard mesh, Go today / Rust planned). Synthesis of five verified surveys + two supplementary checks. Anti-optimistic reading throughout; verifier corrections applied.

=====================================================================
1. SEQUENCER CEILING — one blessed log, this hardware
=====================================================================

Layered, from theory down to what you actually deployed:

| Layer | Ceiling (envelopes/s) | Evidence |
|---|---|---|
| Order assignment (memory only) | ~10M+ trivially; 26M ops/s (2011 Nehalem) to 160M ops/s (EPYC, Disruptor 4), 1P-1C | LMAX Disruptor paper, lmax-exchange.github.io/disruptor/disruptor.html |
| Sequence + journal + serialize, one thread, binary codec | ~1–6M | LMAX 6M orders/s on a 2010 Nehalem Dell (martinfowler.com/articles/lmax.html); Chronicle Queue >1M events/s durable at 1–20 us (chronicle.software) |
| Same, Go with allocation-free codec | ~1M (expect low end of LMAX band) | LMAX 10K naive → 100K well-factored → 6M optimized progression; NATS (Go) proves 7–14.8M msgs/s publish-only is reachable in Go with batching (docs.nats.io natsbench) |
| Naive Go + JSON (where the kernel sits today) | ~10–100K | Go JSON marshal 1.3–3.7 us/op vs protobuf 0.2–0.9 us (codingexplorations.com benchmark); Redis unpipelined 100–400K ops/s is the genre bracket |
| Windows UDP egress/ingress, per socket | IOCP ~384K, RIO ~482K datagrams/s (2012 measurements); modern RIO ~1 Mpps single steered flow, ~2.3 Mpps with UDP segmentation offload | serverframework.com RIO series; learn.microsoft.com Q&A 268716. No recvmmsg on Windows — RIO is the only batching path |
| Gigabit wire | 1.488 Mpps min-size; ~1.18M env/s @100B batched; ~236K env/s @500B batched; ~220K pps @500B unbatched; ~81K pps @1500B | Ethernet framing arithmetic; blog.cloudflare.com/how-to-receive-a-million-packets |

Break order on this deployment (first to last): (1) unicast fan-out on the sequencer NIC, (2) per-datagram syscall cost if unbatched (~100K env/s is the batching-mandatory line), (3) serialization codec, (4) the single-writer CPU core — last, by ~an order of magnitude. Contention math says single-writer is the right call, not a compromise: 500M increments in 300 ms single-thread vs 118,000 ms two-thread-locked, a 19–393x penalty for shared writers (mechanical-sympathy.blogspot.com single-writer-principle).

Fan-out is the hard number: no multicast anywhere on the tailnet (tailscale/tailscale#11134 — point-to-point WireGuard, multicast does not traverse), so sequencer egress = rate x size x N_subscribers. At 500B x 100K env/s each subscriber costs 50 MB/s → a gigabit NIC feeds ~2 full-rate subscribers. NATS measured the same wall: 14.8M msgs/s publish with 0 subscribers collapsing to 955K publish rate with 5 (broker copies per-socket; nats-server discussion #5641). Interest management is a bandwidth filter or the sequencer NIC is the ceiling.

Consensus caveat: if frame commit ever round-trips followers, Aeron Cluster is the comparable — 100K msgs/s at P99 136 us, but at 1M msgs/s open-source collapses to P50 3.3 ms / P99 8.5 ms (AWS Aeron 2025 benchmark). Consensus-gated commit saturates ~10x before raw transport. Keep replication async and off the actuation-gating path (Kafka: sync 3x replication = 421,823 rec/s vs 786,980 async — a 2x lever; LinkedIn benchmark).

Bottom line: sequencer CPU ceiling ~1M env/s (defensible, LMAX/Aeron-proven, requires Rust-or-tuned-Go codec); deployed ceiling ~200–500K env/s Windows-syscall-bound, divided by N subscribers for fan-out; today's Go+JSON reality ~10–100K env/s, i.e. 10–100x below the defensible target.

=====================================================================
2. PROPAGATION CEILING — LAN vs Tailscale tiers
=====================================================================

500B envelope assumed. "Sync frame ceiling" = 1/RTT for commit round-tripping the sequencer; tail consumers are throughput-bound, not RTT-bound.

| Tier | RTT | Envelope rate | Sync frame ceiling |
|---|---|---|---|
| (a) Raw UDP, same GbE LAN | 0.2–0.5 ms | 50–150K/s Go single socket unbatched (Linux ref: 861K pps, toonk.io; Windows lower); wire ceiling 236K/s @500B batched | ~700–2,000 Hz |
| (b) Tailscale direct, same LAN (Windows/wintun) | 0.5–1.5 ms | 20–50K/s realistic (CPU-bound in userspace WG); 400–600 Mbps healthy Windows, pathological reports as low as 10 Mbps | ~700–2,000 Hz latency-wise; throughput is the binder |
| (c) Tailscale same-city direct | 2–10 ms | 10–50K/s (uplink-bound) | 100–500 Hz |
| (d) Tailscale cross-site direct (intra-EU) | 10–40 ms | ~10K/s class | 25–100 Hz |
| (e) DERP relay fallback | 40–200 ms (+18–45 ms typical, +180 ms distant) | few K/s (~70% throughput cut) | 5–25 Hz |

Sources: contabo.com WG-vs-Tailscale measurements; tailscale.com/blog/nat-traversal-improvements-pt-1 and peer-relays posts; tailscale.com performance docs. WireGuard adds 60B/packet IPv4; Tailscale MTU 1280 → usable QUIC-datagram payload ~1100–1150B if QUIC is ever adopted (RFC 9221 single-packet constraint; the 1200B floor is RFC 9000's).

Two hard qualifiers. First: the headline wireguard-go numbers (13.0 Gbps, beating kernel WG) are Linux-only (UDP GSO/GRO + sendmmsg); Windows/wintun has none of these offloads — the Windows datapath, not Go and not the protocol, is the mesh throughput ceiling. Second: every Tailscale connection starts on DERP and upgrades; >90% of pairs go direct, but the design must survive tier (e) as the degraded mode, not treat it as exceptional.

Loss/reorder: switched LAN ~0% until socket-buffer overflow; internet paths <2–3% reorder (Google PlanetLab; 0.79% IPv4 RIPE study), <1% loss on healthy paths. Deterministic re-sort already absorbs this → unreliable-sequenced plain UDP inside the tunnel for the tail (inherits WG AEAD free; QUIC inside WG double-encrypts at roughly 2.4x CPU unoptimized, parity only after heavy tuning — Fastly, corrected figure), plus one reliable channel for frame commit/watermark. WebTransport/QUIC only matters when leaving the tunnel or adding browser subscribers; HOL blocking on a reliable ordered channel only bites above ~200–500 msgs/s/connection on lossy paths.

=====================================================================
3. EPSILON MENU AND FRAME-RATE RANGE (frame floor ~10x epsilon)
=====================================================================

| Tier | Epsilon | Frame floor | Frame ceiling | Available on this fleet? |
|---|---|---|---|---|
| Stock Windows w32time | tens of ms – seconds (Kerberos-grade defaults) | — | unusable | yes, and it's what you have unless tuned |
| Tuned w32time, LAN, one box promoted to local NTP | ~1 ms (Microsoft's supported 1 ms tier: <0.1 ms one-way to source, <=4 hops, stratum <=5, CPU <80%) | 10 ms | ~100 frames/s | YES — the realistic fleet ceiling as-is |
| chrony + GPS/PPS stratum-1 (~$100 Pi build) | 50–200 us (measured: 150–180 us P99 aggressive polling vs LeoNTP over 70 us-RTT LAN) | 0.5–2 ms | 500–2,000 frames/s | NO — requires Linux consumers; Windows clients stay ~1 ms |
| PTP hardware timestamping | sub-us | 10 us | 100 kHz | NO — no Windows PHC path; software-PTP "few us" claims unverified |
| Tailscale WAN (NTP over internet) | 5–10 ms typical, 100+ ms tail (HLC paper measured 1.5–16 ms avg EC2 offsets; asymmetry unprovable below RTT/2 without per-site GPS) | 50–100 ms | 10–20 frames/s cross-site, degrade-to-1 Hz tail | this is the cross-site reality |

Sources: learn.microsoft.com high-accuracy time support boundary + configuring-systems-for-high-accuracy (registry: Min/MaxPollInterval=6, SpecialPollInterval=64, UpdateInterval=100, UtilizeSslTimeData=0); engineering.fb.com (10 ms → 100 us chrony); scottstuff.net 2025 chrony/GPS measurement; cse.buffalo.edu HLC tech report 2014-04; Spanner OSDI'12 (epsilon avg ~4 ms, sawtooth 1–7 ms — with GPS+atomic masters, i.e. Google's floor is your fleet's ceiling neighborhood).

Independent OS floor: Windows default timer 15.625 ms; timeBeginPeriod buys 1 ms; sub-ms pacing needs QPC+spin (randomascii; corrected: Win10 2004 scoped per-process, Win11 ignores background raises). So even with perfect clocks, frame cadence below ~1 ms is not schedulable on stock Windows — 64–128 Hz is the comfortable band, exactly game-server territory.

NET RANGE: floor 10–20 frames/s (cross-site, honest epsilon), ceiling ~100 frames/s (fleet-wide, tuned w32time + Windows timer floor). The 500–2,000 fps tier exists but costs an OS change or a per-site GPS stratum-1 with Linux time consumers. Critically, HLC ordering itself needs zero sync (causality survives arbitrary degradation; 64-bit 48+16 encoding; c<=7 even under 16 ms NTP offset stress) — epsilon only gates frame boundaries as wall-clock claims and actuation. If a frame must ever assert real-time order externally, copy ClockBound's [earliest, latest] interval API + ~2x-epsilon commit-wait at the actuation boundary only (github.com/aws/clock-bound; Spanner pattern).

=====================================================================
4. GAME-NETCODE TRANSFERS — what, and at what rate mandatory
=====================================================================

| Technique | Transfers as | Mandatory above |
|---|---|---|
| Interest management (slice subscriptions) | bandwidth filter, not just relevance filter | N_sub x rate x size approaching NIC: @500B, >2 full-rate subscribers at 100K env/s on GbE; on Tailscale-Windows (400–600 Mbps) it's ~1 subscriber. Effectively day-one at swarm tempo. Doom's IPX broadcast getting banned from office LANs is the 1993 version of this lesson (doomwiki.org) |
| Envelope batching (many rewrites per datagram, 8–64KB frames) | syscall amortization | ~100K env/s aggregate (kernel pps cost: single RX queue/thread ~0.35–0.43M pps, corrected Cloudflare reading; Windows RIO ~0.5M class). Every surveyed system batches |
| Delta vs last-acked, per-subscriber ack frontier (Quake 3: 32 retained snapshots, ~36 bits/changed field vs 132) | per-subscriber watermark + catch-up wire format | when any subscriber needs derived-state sync rather than the raw log — i.e., late joiners and slow consumers, at any rate. Cap the retained tail window (Q3: 32 frames) or memory scales per-subscriber unboundedly |
| Rollback / bounded speculation (GGPO: GGPO_MAX_PREDICTION_FRAMES=8) | speculative tail depth bound, in frames not wall-time | the moment anything actuates off the unfinalized tail. Budget rule: worst-case re-fold of the full tail must fit in one frame → fold step <= ~1/10–1/15 of frame budget (SnapNet: ~15 re-simulated frames inside 16.66 ms → 1.1 ms effective tick budget) |
| Frames-commit-as-units + fine intra-frame timestamps (CS2 subtick, 64 Hz) | HLC-within-frame, verbatim | already the design; production-validated at 64 Hz |
| Producer runs ahead by half-RTT + 1 frame (Overwatch) | agents stamp intents against a future frame so the sequencer never stalls | when RTT ~ frame period: cross-site (10–40 ms) at anything >=25 Hz |
| TiDi deterministic slowdown (EVE: floor 10% real time) | overload response: stretch frame cadence, never shed rewrites | any rate — it is the only overload mode consistent with log-is-truth |

Consistency-domain comparables (all far above this deployment): EVE 2,670 concurrent writers B-R5RB (2014), 6,739 in-system M2-XFE (CCP-reported concurrency record, breaking the 6,557 Guinness-era mark; M2-XFE's actual Guinness records were cost/$378,012 and 257 Titans — corrected attribution), 13,770 across 3 systems; WoW ~3,000/layer. A handful of LLM agents at AoE-class command rates (0.5–4 cmds/s each) is 2–3 orders inside the proven envelope. SpatialOS/Worlds Adrift is the anti-lesson: distributed multi-writer authority (entity handoff across hundreds of workers) glitched physics and killed the game commercially — single sovereign sequencer is the correct call at this scale.

=====================================================================
5. T262 ASSUMPTIONS — CONFIRMED vs OVERTURNED
=====================================================================

CONFIRMED:
- Single blessed sequencer, no distributed write authority. Single-writer principle (19–393x contention penalty), LMAX (6M/s one thread), SpatialOS failure. Strongest-confirmed assumption in the design.
- Log is truth, state derived by deterministic re-fold. AoE synced 1,500 units over 28.8 kbps by shipping only ordered commands; LMAX replays a full day in under a minute. Bandwidth scales with command rate, not state size.
- HLC-within-frame ordering. CS2 subtick in production; HLC causality needs zero clock sync; 64-bit encoding fits the envelope.
- Speculative tail read at wire speed is free. Disruptor consumers chase the cursor at memory speed (52 ns mean hop); watermark gates only side effects. Confirmed with one condition: tail depth must be bounded in frames (GGPO) and fold cost <=1/10 frame budget, or re-fold blows the frame.
- Current 61–63 Hz tempo is comfortable. 10–30x sync headroom on LAN; exactly shipped-game cadence (Overwatch 63, CS2 64, Valorant 128).
- Frames gate actuation. Universal convergence across games, trading, and logs (Valorant 2.34 ms frame budget; Kafka sync/async divide).

OVERTURNED or RE-JUDGED:
- "Total order costs approximately nothing." SPLIT VERDICT, and the split is the report's headline. The ordering ACT is confirmed nearly free at any tempo — nanoseconds, 10M+/s, never the bottleneck. But at datagram-swarm tempo the claim silently included DISTRIBUTION of the total order, and that is not free: (a) one total order means every subscriber's ingress is the full feed unless the sequencer filters per-subscriber — slice subscriptions become load-bearing bandwidth filters, not an optimization; (b) unicast-only fan-out (no tailnet multicast) makes sequencer egress linear in N — ~2 full-rate subscribers per GbE NIC at 500B x 100K/s, ~1 through wintun; (c) unbatched envelopes hit the syscall wall at ~100K/s (Windows ~0.4–0.5M datagrams/s class); (d) if commit round-trips anything, Aeron Cluster shows a 10x-early collapse. At rewrites-per-minute all four terms rounded to zero, so the original justification was correct for its tempo — and does not survive the tempo change. Restate as: "assigning total order costs nothing; broadcasting a total order costs rate x size x N and is the first thing that breaks."
- Cross-site frames at LAN tempo. Overturned. Sync commit ceiling 25–100 Hz direct, 5–25 Hz on DERP; 61–63 Hz cross-site synchronous is marginal-to-impossible. Watermark-lagged async commit is required, not optional, and the design must tolerate degrade-to-1-Hz tails.
- Uniform frame rate fleet-wide. Overturned by the epsilon menu: ~100 Hz ceiling on-LAN vs 10–20 Hz cross-site. Frames need per-tier cadence or TiDi-style stretching.
- "Go is the bottleneck / Rust fixes it." Re-judged: the binding constraints are Windows-shaped — wintun without offloads, no recvmmsg (RIO only), 1 ms timer floor, w32time epsilon floor ~1 ms, no hardware timestamping path. The Rust rewrite is justified on the LMAX 10K-naive-vs-6M-optimized codec/allocation axis (~100x), not language speed; it does not move the Windows datapath ceilings at all.
- Implicit "current kernel is near its platform ceiling." Overturned in the encouraging direction: Go+JSON today (~10–100K/s class) is ~10–100x below the defensible 1M env/s single-sequencer target on this same hardware.

STILL UNCERTAIN (flagged, not resolved):
- Windows RIO figures are mostly 2012-era; the modern ~1 Mpps / 2.3 Mpps-with-USO claim comes from a single Microsoft Q&A thread, not a reproducible benchmark. Treat the Windows syscall tier as 0.4–1M datagrams/s with wide error bars.
- Tailscale-on-Windows throughput has no authoritative benchmark: healthy reports 300–600 Mbps, pathological 10 Mbps (wintun/Windows-stack interactions, e.g. the SMB-over-Tailscale reports). Measure on the actual Z440↔hp-laptop path before trusting tier (b).
- Windows software-PTP "few microseconds" is vendor-claimed (PTPSync/Domain Time II), unverified independently.
- Go-on-Windows UDP pps specifically (vs the Linux 861K pps reference) is unmeasured — the 50–150K/s unbatched figure is an inference.
- The frame-floor = 10x-epsilon rule is a design convention, not a measured law; the real constraint pair is (epsilon for wall-clock claims, Windows 1 ms pacing floor).

Sources beyond the surveys' own citations: [serverframework.com RIO take 2](https://serverframework.com/asynchronousevents/2012/08/windows-8server-2012-registered-io-performance---take-2.html), [Microsoft Q&A on RIO performance](https://learn.microsoft.com/en-us/answers/questions/268716/has-winsock-registered-io-performance-degraded-sin), [tailscale/tailscale#9707](https://github.com/tailscale/tailscale/issues/9707), [Tailscale performance best practices](https://tailscale.com/docs/reference/best-practices/performance), [Windows-kills-SMB-over-Tailscale thread](https://news.ycombinator.com/item?id=42132131), [tailscale.com/blog/more-throughput](https://tailscale.com/blog/more-throughput).

## Appendix — verifier corrections (applied above)

### game-netcode [high]
- EVE M2-XFE (misattribution, number itself correct): 6,739 peak concurrent in-system, 13,770 across 3 systems, and ~35% of online pilots are all confirmed by CCP's own 'The Second Timer in M2-XFE' post — but the 6,739 peak is from the SECOND fight (Jan 2, 2021), breaking the prior 6,557 record set by Fury of FWST-8 (Oct 2020), and it is not itself a Guinness record. The two Guinness records M2-XFE earned (Dec 30-31, 2020 fight) were 'Most Costly Video Game Battle' ($378,012) and 'Most Titans Lost' (257) — not a concurrency record. Reword the parenthetical from 'Guinness-record single-shard ceiling' to 'CCP-reported concurrency record (broke the 6,557 Guinness-era mark); M2-XFE's Guinness records were for cost/Titan losses'.

### sequencers [high]
- Cloudflare UDP claim wrong: 1.4M pps was achieved with MULTIPLE NUMA-aligned RX queues + receiver threads, not 'one tuned RX queue/core' — a single RX queue/thread tops out ~0.35-0.43M pps (0.374M pinned). The '~480K pps/core when spread over 4 queues' figure is not in the source; nearest number (0.48-0.495M pps TOTAL) is from 2 threads contending on one shared socket, and 4-thread SO_REUSEPORT gives ~1.1M pps total. Batching/kernel-bypass thesis survives; both headline numbers are misstated. This also softens the 'sequencer CPU has 10-50x headroom' side of the derived gigabit-LAN claim at the high end.
- Aeron misattribution: the '~800K msg/s OS vs 4.7M msg/s kernel bypass' max-throughput comparison is from the Aeron Google Cloud write-up (single-zone, 288-byte, GCP C3: '800,000' vs 'over 4,700,000'), NOT the AWS 2025 benchmark post, which publishes no max-throughput figures. Numbers themselves confirmed.
- Disruptor latency provenance conflated: 52ns mean / 128ns 99% / ABQ 32,757ns come from the three-stage-pipeline latency test on a 2.2GHz Core i7-2720QM (Sandy Bridge, Ubuntu 11.04), not the Nehalem 2.8GHz box used for the 25,998,336 ops/sec 1P-1C throughput number, and not strictly the unicast config. Values correct; hardware pairing in the claim is wrong.

### protocols [high]
- Fastly QUIC-vs-TCP claim is wrong/misattributed: the cited post reports no '~90% vs ~50% CPU utilization' numbers. It measures throughput at saturated CPU — TLS1.3/TCP 466 Mbps vs off-the-shelf QUIC 196 Mbps (~2.4x cost) — and concludes that after optimizations (ack frequency, GSO, larger packets) QUIC reached 464 Mbps, i.e. computational parity with TLS/TCP. The '~2x' figure only describes unoptimized QUIC and the source explicitly walks it back.
- GameNetworkingSockets constant name is wrong: it is k_cbMaxSteamNetworkingSocketsMessageSizeSend = 512 * 1024 (steamnetworkingtypes.h), not 'k_cbMaxSteamDatagramMessageSize'. The 512 KB value is correct but is the SEND-side max; the header notes peers may accept larger received messages.
- Tailscale wireguard-go version requirement misattributed: the cited posts require Tailscale 1.36 (TSO/GRO + sendmmsg/recvmmsg; TUN offload in Linux since 2.6.27) and 1.40-unstable (UDP GSO/GRO; kernel 4.18+/5.0+ on Ubuntu 22.04). Neither cited source says 'Linux 6.2+/Tailscale 1.54+' — that pairing is from a later uncited change (UDP GRO forwarding era). The throughput numbers themselves (13.0 vs 11.8 Gbps bare-metal i5-12400; 2.42 -> 5.36 Gbps c6i.8xlarge) are confirmed.
- RFC 9221 citation nit: the '1200B path guaranteed' floor is not in RFC 9221 (no mention of 1200 bytes); it derives from RFC 9000's minimum UDP payload requirement. The single-packet constraint and 65535 sentinel ('accept any DATAGRAM frame that fits inside a QUIC packet') are confirmed verbatim in RFC 9221.

### clocks [high]
- Minor misattribution: the '(5 min tolerance)' figure in the Windows default-config claim is NOT on the cited Microsoft high-accuracy page — the page only says the default config targets 'Kerberos version 5 authentication requirements' without a number; 5 minutes is the AD/Kerberos default max clock skew from a different source. All registry values on that line (Min/MaxPollInterval=6 -> 64 s, SpecialPollInterval=64, UpdateInterval=100, UtilizeSslTimeData=0 = Secure Time Seeding disabled) verified verbatim; page additionally specifies FrequencyCorrectRate=2 and notes UtilizeSslTimeData requires a reboot.
- Nuance on the 50 ms tier: Microsoft's wording is 'better than 5 ms of network latency between [the target and] its time source' (one-way per their RTT/2 methodology, so the claim reads correctly), but the tier also requires stratum <= 5, <= 6 network hops, and one-day avg CPU <= 90% (vs <= 80% and <= 4 hops for the 1 ms tier) — the claim omits the 50 ms tier's own hop/CPU limits. Omission, not error. Doc is current (updated 2026-02); tiers 1 s / 50 ms / 1 ms, the 0.1 ms figure, and pre-2016 non-support all confirmed exactly.
- Wording nuance on Facebook: the article says 'improve accuracy from 10 milliseconds to 100 microseconds' (claim says 'precision'), and the +/-100 us band was measured with hardware timestamping enabled; software chrony in their lab showed +/-200 us vs ntpd's -10..+3 ms. The 10 ms -> 100 us headline figure itself is verified verbatim.
- No numeric errors found in the HLC-paper claims (read PDF directly): 1.5-16 ms measured avg NTP offsets on m1.xlarge vs stratum-2 0.ubuntu.pool.ntp.org; '100 ms or more' asymmetric-route quote; ~1 ms LAN ideal; 16-node offset=16ms run max l-pt 90.5 ms / 90th pct 25.2 ms / avg 2.3 ms / c max 7; 4-region WAN c=0 ~95%; |l-pt| <= epsilon (Cor. 1); c <= epsilon/d+1 (Cor. 4); 48+16-bit 64-bit encoding (sec. 6.2); 99.9% NTP-kink masking (sec. 4.2) — all exact.
- No errors in Spanner TrueTime claims (read OSDI'12 PDF via Google mirror; USENIX URL returns 403): epsilon sawtooth 'about 1 to 7 ms over each poll interval', avg 4 ms, 30 s poll, applied drift rate 200 us/s, expected commit wait >= 2*epsilon-bar (~5 ms in 1-replica microbenchmark) — all confirmed verbatim; 'generally < 10 ms' is a fair reading of Fig. 6 tail percentiles.

### hardware [high]
- Windows timer claim: version attribution swapped. Win10 2004 introduced per-process scoping of timeBeginPeriod (raises no longer affect other processes globally); it is Windows 11 that ignores timer-resolution raises from background/minimized processes. The 15.625 ms / 64 Hz default and 1 ms timeBeginPeriod floor are correct (randomascii primary source).
- io_uring vs epoll +20-40% pps: the number appears in the cited Phoronix article but is a PROJECTED figure ('expected improvement') from Microsoft's .NET io_uring socket-engine pull request, not a measured io_uring-vs-epoll UDP benchmark. Keep the range but relabel as vendor projection, or cite a measured benchmark instead.
