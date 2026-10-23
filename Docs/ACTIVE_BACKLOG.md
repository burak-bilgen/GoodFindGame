# Delivery and remaining work

Updated 2026-10-23 after the commercial quality pass. Current approved scope keeps photo generation stopped and unphotographed products paused. Implementation, external acceptance and optional expansions are separated below.

## Implemented

- [x] Career shop: paid opening after three completed sales, three specializations, limited curated window, paid capacity growth earned through window sales. Existing buyer budgets and firm offers remain authoritative.
- [x] Catalog: 80 definitions retained for save compatibility; 63 photographed products eligible for new listings. The remaining 17 are paused and copied as comments in `DEFERRED_PRODUCTS.jsonc`. They do not appear in new feeds or market search. Existing owned items and agreements remain usable.
- [x] One fixed photo per product mapping. No cosmetic-condition image variants or inspection-photo comparison. Some older models share family photography. Twelve additional household photos packaged at 768px JPEG; no more generation authorized.
- [x] Twenty-four authored seller voices; stable item facts and prices.
- [x] Settings consolidated; player-facing Developer tools removed. Minimum deployment iOS 26 for all targets.
- [x] Active-tab reselection returns that tab to its root/top; switching tabs preserves other tabs. Reselection recreates the selected root, so its local filters reset.
- [x] Inbox: persisted activity/read state, actionable replies before recency, buyer offers needing attention at top, closed conversations in Archive. Legacy undated conversations retain their relative order and are not marked unread merely by migration.
- [x] Inventory: compact shipment/stock rows, capacity and status filters. Large photos stay on detail screens.
- [x] Removed duplicate title banners in Messages, Inventory, Shop, Settings, Career, Clients, Selling and Recovery. The weekly competition keeps its distinct challenge identity.
- [x] Local profile name, four avatar choices and earned display-title selection. Persisted independently of career/weekly save files and Game Center; shop name and earned rank remain distinct.
- [x] Language and Apple AI research captured in `LANGUAGE_PRIORITIES.md` and `APPLE_AI_FEASIBILITY.md`.

## Current quality and agent verification

- [x] Sustainable routine trading: public-information strategy regression, ordinary seller bargaining room and end-user buyer audience; meaningful risky wins/losses remain. No guaranteed profit.
- [x] Public-evidence appraisal, compact decision hierarchy, career milestone prompts, useful pending/ready handoffs and loss-appropriate feedback.
- [x] New session-scale timers, bounded fresh arrivals, legacy-deadline compatibility and paid-report/listing conflict protection.
- [x] Four shipping languages with 895 complete keys; complete trade replays in English/Turkish/German/French, large Turkish, reduced motion, recovery, clients, collections, shop and offline/concurrent checks. See [quality evidence](QUALITY_PASS_2026_10_23.md).
- [x] Shared dark-text palette, explicit trading touch targets and native core-market touch audit. Additional inspection/pricing/buyer controls passed their native touch audit. Large German/French trade replays and four-language screen-reader offer attention are covered. Large-text attention counts now adapt to rows without splitting digits; see the quality report for final follow-up evidence.

## External acceptance

- [ ] Human free play across first-session, loss/recovery and shop progression. Use [the current playtest guide](HUMAN_PLAYTEST.md); automated outcomes do not prove enjoyment or retention.
- [ ] Physical-device sound/haptics, sustained performance and full VoiceOver use. Simulator checks cover behavior, layout and exposed accessibility properties. Minimum-iOS 26 runtime acceptance also remains open: this machine currently has iOS 27.2 runtimes only; deployment-target compilation is verified.
- [ ] Native-speaker editorial acceptance in the four shipping languages. Authored translations and automated validation are complete.
- [ ] Live Game Center: owner-account App Store Connect resources and signed sandbox verification. Local offline competition, optional authentication, achievements, identifiers and four-language metadata are implemented. See [setup](GAME_CENTER_SETUP.md).

## Deliberately deferred, not required closeout work

- Seventeen paused products and additional photography: resume only on explicit owner instruction. No new image generation is authorized.
- Additional languages (Japanese, Chinese scripts, Arabic/RTL; Hindi only with stronger audience evidence): not enabled or promised in current scope.
- Optional Apple on-device text: researched, not implemented. No model download or hidden economy changes belong to current gameplay.

Current simulator evidence is in [the quality report](QUALITY_PASS_2026_10_23.md); [CLOSEOUT_QA.md](CLOSEOUT_QA.md) describes an earlier milestone. Test counts are scoped to their recorded checkpoints, not a claim that every UI test was run in one final batch.
