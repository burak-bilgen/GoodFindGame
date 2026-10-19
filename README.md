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

The first category has ten fictional definitions. English uses neutral credits (¤); Turkish uses ₺ without changing simulation amounts. Initial negotiations, delivery, inspections and buyer attention resolve immediately in this Phase A build. Timers, offline catch-up and notifications belong to Phase B. No ads, Game Center or backend are present yet.

DEBUG builds expose Developer tools under Profile for save reset, cash, market regeneration, hidden truth and forced responses. Release builds exclude that screen and its actions. UI tests use isolated saves. No signing team or personal Xcode data is committed.

Before Phase B, play at least five trades and assess whether information gathering, bargaining, risks and inspection results create interesting decisions. Passing automated tests establishes correctness; it does not establish fun. The corrected master brief and supplemental requirements in Docs are the project requirements; auctions are conditional stretch scope, otherwise V1.1.
