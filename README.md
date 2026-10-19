# Project Flip

Original offline-first iPhone trading game. Internal codename; final branding requires clearance.

Open `ProjectFlip.xcodeproj`. Requires Xcode with Swift 6 support; deployment target iOS 17, portrait iPhone. No external dependencies or signing team is stored. Select your personal team locally for device builds.

```sh
python3 Scripts/check_localization.py
xcodebuild -project ProjectFlip.xcodeproj -scheme ProjectFlip -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

See Docs for requirements and milestone status. Localization uses semantic keys in a String Catalog; English and Turkish are first-class languages. Keep simulation independent of UI and locale.

## Play the vertical slice

Browse Market, compare the asking price with the model reference and seller claims, open a listing, ask about issues and send an offer. Accept a counter or negotiate, then confirm purchase. In Inventory, inspect the item and create a resale listing. Open Selling to accept, reject or counter a buyer. Profile → Trade history explains the result. A basic inspection is free; a professional inspection uses game cash.

Market supports fictional product-name search, category and localized price filters, newest/oldest sorting and a persistent watchlist. Bookmark a listing from its detail screen; watched listings remain visible when unavailable. After the first sale, the trends screen tracks timed category/model demand changes that affect current estimates and new offers. After the first sale, live listings can expire, drop in price or sell to another trader; a periodic refresh brings in new stock. Firm quotes retain their promised window, and watched archives retain the actual outcome. See Docs/MARKET_SIMULATION.md for schedules and offline behavior.

The first category has ten fictional definitions. English uses neutral credits (¤); Turkish uses ₺ without changing simulation amounts. Seller questions/offers, delivery, professional inspection and buyer interest now use persisted timers. DEBUG timers are seconds; production timers are minutes, with an accelerated first trade. Launch/foreground catch-up resolves the world and shows a grouped report until acknowledged. UI tests explicitly opt into instant timing through the same queue. Local notifications now use persisted events, contextual opt-in, per-category settings and exact-object routing. No ads, Game Center or backend are present yet.

DEBUG builds expose Developer tools under Profile for save reset, cash, market regeneration, hidden truth, forced responses and virtual time travel. Release builds exclude that screen and its actions. UI tests use isolated saves. No signing team or personal Xcode data is committed.

The five-trade UI evaluation completed and an omniscient-seller pricing flaw was fixed before Phase B. Keep playtesting whether information gathering, bargaining, risks and inspection results create interesting decisions. Passing automated tests establishes correctness; it does not establish fun. The corrected master brief and supplemental requirements in Docs are the project requirements; auctions are conditional stretch scope, otherwise V1.1.
