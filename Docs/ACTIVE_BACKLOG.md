# Delivery and remaining work

Updated 2026-10-23. Current scope follows the owner's request to stop generating photos, pause unphotographed products, and keep verification focused.

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

## Intentionally deferred / needs external acceptance

- [ ] German/French translation completion and linguistic review. Partial authored work is preserved in `Localization/de-fr.tsv`; neither language is enabled. Further language expansion was held during the owner's quota constraint. Japanese/Chinese are research priorities, not delivered support; Arabic/ Hindi remain evaluated candidates.
- [ ] Live Game Center: owner-account App Store Connect resources and signed sandbox verification. Local optional authentication, leaderboard, weekly saves and achievements are implemented. Setup instructions are in `GAME_CENTER_SETUP.md`.
- [ ] Human playtest of shop decisions and pacing. Automated checks do not establish enjoyment or long-term retention.
- [ ] Optional Apple on-device text integration is researched, not implemented. No AI model download, hidden economy changes or online photo generation is part of the game.
- [ ] Paused products / additional photography only when the owner explicitly resumes that work. No new images should be generated to close this list.

Verification details: `CLOSEOUT_QA.md`. Earlier broad test counts belong to earlier milestones; they are not a claim that the whole current suite was rerun.
