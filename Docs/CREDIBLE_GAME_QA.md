# Credible game milestone — verification

22 October 2026. Implementation is divided into economy, art, native game feel, career/expertise, recurring clients, collections, recovery and identity commits. No Game Center, ads, payments, auctions, backend, new categories or expanded rarity system was added. Bundle identifiers, production display name and save location remain Project Flip pending naming review.

## What changed

- Canonical USD-cent accounting, independent versioned regional price profiles and typed USD/TRY display currency. All fifty products now have explicit value bands and positioning. Locale no longer swaps symbols over identical amounts or reprices a career. Legacy saves have backed-up explicit migration; existing firm agreements survive career gates.
- Seven model-specific four-condition product masters plus replaced controller/monitor families. Seller-photo direction uses seller claims; inspection comparison and earned external evidence are separate from hidden faults. New live stock can actually be heavily worn. Chapter 16's initially incorrect console master was rejected and replaced with a handheld.
- Compact marketplace cash instrument, stronger item-focused trade results, native finite feedback, opt-in original audio and existing haptics. No animation library was justified. New career/client/collection/recovery surfaces use the same game environment.
- Four career stages and non-monetary trust access; case-based specialist endorsement beyond the original knowledge ranks; two remembered clients with three authored chapters each; two three-piece owned collections and persistent hunts; liquidation and bounded consignment recovery.
- Ten researched name candidates, top three and Findrove working recommendation, with a preliminary vector direction. Trademark, store metadata, domain and handles are not cleared or reserved.

## Baseline and targeted evidence

Baseline: `/tmp/FlipMilestone-baseline.xcresult`, 121 units pass. Absurd-monitor regression: `/tmp/FlipMilestone-price-red.xcresult`, fails at 520,000 canonical cents against a 30,000-cent ordinary-monitor ceiling. The corrected clean Vista base is $120, not $5,200.

Targeted checkpoints:

| Area | Result bundle | Verified result |
| --- | --- | --- |
| Economy | `/tmp/FlipMilestone-economy4.xcresult` | 126 units pass, no recorded runtime warnings |
| Economy bilingual trades | `/tmp/FlipMilestone-economy-ui.xcresult` | 2 pass |
| Art + bilingual trades | `/tmp/FlipMilestone-art-final.xcresult` | 129 pass |
| Game shell | `/tmp/FlipMilestone-feel.xcresult` | 2 bilingual trades pass |
| Career/expertise | `/tmp/FlipMilestone-career-final.xcresult` | 131 pass |
| Clients | `/tmp/FlipMilestone-clients-units2.xcresult`, `/tmp/FlipMilestone-clients-ui2.xcresult` | 131 units + 2 acceptance/relaunch journeys pass |
| Collections | `/tmp/FlipMilestone-collections-final.xcresult` | 7 affected units + 2 bilingual hunt/relaunch journeys pass |
| Recovery | `/tmp/FlipMilestone-recovery-final.xcresult` | 5 affected units + 2 zero-cash bilingual service journeys pass |
| Progression regression | `/tmp/FlipMilestone-progression-final.xcresult` | 135 units pass |
| Currency independence | `/tmp/FlipMilestone-currency-preflight.xcresult` | 2 bilingual currency-change/relaunch journeys pass; saved market stays fixed |
| Final units | `/tmp/FlipMilestone-final-units.xcresult` | 138 units pass, no recorded runtime warnings |

The first client UI run exposed an ancestor accessibility identifier masking nested controls; both tests failed, that identifier was removed, then both acceptance/relaunch journeys passed. Intermediate economy runs exposed stale old-scale fixtures and an unguarded test-array assumption; fixtures were rebased without removing price/traffic safeguards. An initial final-suite build failed on a throwing short-circuit expression in a new simulation test. A later all-suite attempt was intentionally interrupted when visual QA required the corrected handheld and gallery hierarchy. None is represented as a green full run.

## Economy simulations

Ten thousand generated listings and buyer budgets cover both US/USD and Turkey/TRY, with deterministic currency round trips, value-band bounds, positive prices, realistic behavior ceilings, condition boundaries, overflow rejection and no repeat repair restoration.

The final repeated-trade probe evaluates 250 candidate listings per limited policy/region. Both limited policies always pay for expert reports, accept an immediate buyer and ignore bargaining/tool progression. Results:

| Profile / policy | Trades | Losses | Repairs | Final canonical cash |
| --- | ---: | ---: | ---: | ---: |
| US, unfiltered at ask | 33 | 31 | 7 | $10.55 |
| US, public discount filter | 43 | 33 | 14 | $17.66 |
| Turkey, unfiltered at ask | 34 | 27 | 11 | $21.04 equivalent |
| Turkey, public discount filter | 82 | 57 | 42 | $43.87 equivalent |

These are deliberately incomplete strategies, not a description of skilled players. The evidence-aware probe evaluates 1,000 candidates per region using actual seller questions, bounded bargaining, public information, paid tools, free self-inspection, reports only before rank-three self-diagnosis, and reasonable asking prices. It does not read hidden truth to select a purchase. Final results:

| Profile | Completed trades | Passed candidates | Expert reports | Losing trades | Final canonical cash |
| --- | ---: | ---: | ---: | ---: | ---: |
| US | 212 | 788 | 15 | 101 | $2,184.92 |
| Turkey | 216 | 784 | 15 | 98 | $2,433.83 equivalent |

Starting cash is $1,000 before tools. Every settlement reconciles cash against the exact ledger; expertise and trust never supply price multipliers. The difference supports a viable evidence-aware path while retaining loss risk. It is not measured human skill, recommended play, a target loss rate, a forecast of session income or proof of regional balance parity. These headless probes resolve transactions immediately and do not measure time-to-sale or enjoyment. They support behavioral bounds and accounting; human pacing and voluntary retention still require playtesting.

## Final regression and visual review

The two complete UI batches exercised all 63 UI methods on isolated simulators without parallel workers inside each run. Original frozen inputs are recorded in `../../Artifacts/CredibleGame-2026-10-22/final-source-proof.json`, with coverage in `qa-shards.json`.

| Final run | Outcome |
| --- | --- |
| `/tmp/FlipMilestone-qa-0.xcresult` | 30 pass, 1 fail, 0 skip; no runtime warnings |
| `/tmp/FlipMilestone-qa-1.xcresult` | 32 pass, 0 fail, 0 skip; no runtime warnings |
| `/tmp/FlipMilestone-final-followup.xcresult` | 148 pass, 0 fail, 0 skip; all 138 units plus ten affected bilingual UI journeys; no runtime warnings |

The sole complete-batch failure was the unchanged `tradePayoff.isHittable` assertion in `testLargeTurkishRepairTrade`. Its recording showed long Turkish item/status text squeezed into a narrow horizontal column above the result. The shared result now puts the amount first at accessibility sizes, gives the object/name full width, removes a repeated product summary, and scrolls to a stable anchor that exists before settlement. The same assertion then passed. Before that follow-up, two other changes gave clients distinct portrait families and exposed migration information directly from the market. These three source changes were explicitly retested with the affected journeys rather than hidden under an all-green claim.

Final screenshot review then found truncated inspection comparison labels and cramped defect annotations on small result photos. Short EN/TR controls now show Seller photo / Actual item, with the complete evidence disclaimer below and correct context when selected. Evidence annotations appear only on photos at least 180 points wide, leaving thumbnails clear. These presentation changes are isolated to DeviceArt, InventoryView and the string catalog. Post-batch differences and final hashes are preserved in `post-batch-changes.json` / `post-review-source-proof.json`.

All **201 distinct cases (138 unit + 63 UI)** have passing coverage across the complete batches and correction runs. This is not one uninterrupted green 201-case bundle. No assertion was relaxed to accommodate the large-text defect.

The Release plist confirms iOS 17.0 minimum, iPhone-only support and unchanged `gameproject.bilgenworks.ProjectFlip` / Project Flip identity; the test-only recovery launch argument is absent from the Release executable. Xcode emits the existing non-blocking App Intents metadata message because this target has no AppIntents dependency.

Debug build-for-testing passes (`/tmp/FlipMilestone-final-build.log`); subsequent targeted test runs also build Debug. Release simulator build passes (`/tmp/FlipMilestone-final-release-followup.log`). The final photo-control follow-up (`/tmp/FlipMilestone-photo-final.xcresult`) passes five affected UI journeys with zero failures/skips/runtime warnings; current-source Release also passes (`/tmp/FlipMilestone-photo-release.log`). A further bilingual first-trade follow-up (`/tmp/FlipMilestone-comparison-final.xcresult`) passes both tests with zero failures/skips/runtime warnings, explicitly toggling/asserting both inspection-photo modes and waiting for the finished reveal before capture. Only test evidence/selection assertions changed after the five-case photo follow-up; app sources remained unchanged. Localization validates **683** paired EN/TR keys. No third-party dependency was added.

Visual review inspected actual simulator captures of marketplace hunt, seller conversation, inspection reality, collection desire and trade result in both languages, plus Turkish accessibility text and English Reduce Motion. The marketplace has an ambition/career entry and tactile item photography rather than a dominant banking wallet; conversation preserves readable offers; inspection separates advertised and earned appearance; collection uses object slots/story/hunts; settlement gives the actual object and profit an explicit payoff. Earlier failed/early-transition frames remain in the raw exports and are not used as approved final frames. [The selected evidence gallery](../../Artifacts/CredibleGame-2026-10-22/showcase/README.md) links the captured states without retouching game imagery. This supports a game presentation checkpoint, not a claim of final App Store marketing readiness or measured consumer preference.

Original atlases, diagnostic recordings, frozen test inputs and exported screenshots remain in `../../Artifacts/CredibleGame-2026-10-22/` outside Git. Generated master art is original fictional direction; resemblance review found and replaced an incorrect model/form-factor image. This is not a legal non-infringement opinion.

## Limits

iPhone 18 Pro simulator on iOS 27.2; deployment remains iOS 17. No claim of physical-device audio/haptic quality, minimum-iOS runtime acceptance, comprehensive VoiceOver evaluation, legal IP/name clearance, measured retention or App Store commercial success. Most models still use family-level photographs rather than fifty unique masters. Two small collections and six client requests form a finite first-career milestone, not a promise of months of content. Recent-market history remains deliberately deferred until meaningful comparable sale samples exist; the game does not invent market-sale analytics.
