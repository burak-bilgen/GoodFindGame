# Project Flip

Original offline-first iPhone trading game. Internal codename; final branding requires clearance.

Open `ProjectFlip.xcodeproj`. Requires Xcode with Swift 6 support; deployment target iOS 17, portrait iPhone. No external dependencies or signing team is stored. Select your personal team locally for device builds.

```sh
python3 Scripts/check_localization.py
xcodebuild -project ProjectFlip.xcodeproj -scheme ProjectFlip -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

See Docs for requirements and milestone status. Localization uses semantic keys in a String Catalog; English and Turkish are first-class languages. Keep simulation independent of UI and locale.

Current priority is the trading-feel milestone: marketplace discovery, seller reading, inspection, repair decisions and payoff. Category fidelity, progression, Game Center and monetization remain paused. See [the ranked UX audit](Docs/GAMEPLAY_UX_AUDIT.md), [playtest evidence](Docs/PLAYTEST_TRADING_FEEL.md) and [the visual acceptance follow-up](Docs/VISUAL_POLISH_QA.md).

## Play the vertical slice

Browse Market, read the seller’s clues and condition claim, then open a listing and ask about issues before offering. Accept a counter or negotiate, buy, and follow delivery straight to your item. A fresh save’s introductory listing has one discoverable existing fault and enough margin for either an as-is sale or a repair. Basic inspection is free; optional expert inspection uses game cash. A repair quote compares immediate service cost with estimated value recovered. Publish at your chosen price, follow the live listing, accept/reject/counter a buyer, then see the signed profit/loss and return directly to the next hunt. Full costs remain in Trade history. Existing saves keep their original item truth.

Market supports fictional product-name search, category and localized price filters, newest/oldest sorting and a persistent watchlist. Bookmark a listing from its detail screen; watched listings remain visible when unavailable. After the first sale, the trends screen tracks timed category/model demand changes that affect current estimates and new offers. After the first sale, live listings can expire, drop in price or sell to another trader; a periodic refresh brings in new stock. Firm quotes retain their promised window, and watched archives retain the actual outcome. See Docs/MARKET_SIMULATION.md for schedules and offline behavior.

The catalog has 50 fictional definitions across gaming/electronics, cameras and retro/collectibles, with 24 category-specific defects. Ten-slot feeds rotate through that content; existing saves preserve their item IDs and hidden truth. See Docs/CONTENT_CATALOG.md for scope and compatibility. English uses neutral credits (¤); Turkish uses ₺ without changing simulation amounts. Seller questions/offers, delivery, professional inspection and buyer interest now use persisted timers. DEBUG timers are seconds; production timers are minutes, with an accelerated first trade. Launch/foreground catch-up resolves the world and shows a grouped report until acknowledged. UI tests explicitly opt into instant timing through the same queue. Local notifications now use persisted events, contextual opt-in, per-category settings and exact-object routing. No ads, Game Center or backend are present yet.

DEBUG builds expose Developer tools under Profile for save reset, cash, market regeneration, hidden truth, forced responses and virtual time travel. Release builds exclude that screen and its actions. UI tests use isolated saves. No signing team or personal Xcode data is committed.

The five-trade UI evaluation completed and an omniscient-seller pricing flaw was fixed before Phase B. Keep playtesting whether information gathering, bargaining, risks and inspection results create interesting decisions. Passing automated tests establishes correctness; it does not establish fun. The corrected master brief and supplemental requirements in Docs are the project requirements; auctions are conditional stretch scope, otherwise V1.1.
