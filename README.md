# Project Flip

Original offline-first iPhone trading game. Internal codename; final branding requires clearance.

Open `ProjectFlip.xcodeproj`. Requires Xcode with Swift 6 support; deployment target iOS 26, portrait iPhone. No external dependencies. Select your signing team locally for device builds.

```sh
python3 Scripts/check_localization.py
xcodebuild -project ProjectFlip.xcodeproj -scheme ProjectFlip -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO -resultBundlePath /tmp/ProjectFlip-checkpoint.xcresult test
python3 Scripts/check_test_result.py /tmp/ProjectFlip-checkpoint.xcresult
```

Use an unused result-bundle path for each run. The result check rejects recorded
runtime warnings even when XCTest reports a passing interaction.

Previous milestone: **Credible trading game** — canonical/regional economy, product art, game shell, career, clients, collections and recovery implemented; final regression/visual review is recorded in [the milestone QA report](Docs/CREDIBLE_GAME_QA.md). See [the ordered plan](Docs/CREDIBLE_GAME_MILESTONE.md). Findrove is the [recommended working brand](Docs/PRODUCT_NAMING.md), awaiting review; production identifiers remain Project Flip.

The game remains offline-first, portrait iPhone, iOS 26+, with English, Turkish, German and French. Optional Game Center competition and achievements are implemented. No external dependencies, ads, payment system, auctions or custom backend are present. Keep simulation independent of UI and locale. Automated correctness does not establish human enjoyment or retention.

## Current delivery

Paid shop opening and window growth, 63 active photographed products, varied listing copy, compact stock filters, activity-ordered messages/archive, editable profile and consolidated settings. Reselect an active tab to return to its root. Seventeen unphotographed products are paused; their definitions remain compatible with existing saves. Photo generation is stopped. German/French translations are complete and enabled alongside English/Turkish. See [delivery/backlog](Docs/ACTIVE_BACKLOG.md) and [focused verification](Docs/CLOSEOUT_QA.md).

## Play the game

Browse Market, read the seller’s clues and condition claim, then open a listing and ask about issues before offering. Accept a counter or negotiate, buy, and follow delivery straight to your item. A fresh save’s introductory listing has one discoverable existing fault and enough margin for either an as-is sale or a repair. Basic inspection is free; optional expert inspection uses game cash. A repair quote compares immediate service cost with estimated value recovered. Publish at your chosen price, follow genuine traffic and possible buyer interest, accept/reject/counter a buyer, then see the signed profit/loss and return directly to the next hunt. Listings can expire or be withdrawn and relisted; a counter reply is asynchronous. Estimated ranges support pricing without certifying an exact value. Full costs remain in Trade history. Existing saves keep their original item truth.

Market supports fictional product-name search, category and localized price filters, newest/oldest sorting and a persistent watchlist. Bookmark a listing from its detail screen; watched listings remain visible when unavailable. After the first sale, the trends screen tracks timed category/model demand changes that affect current estimates and new offers. After the first sale, live listings can expire, drop in price or sell to another trader; a periodic refresh brings in new stock. Firm quotes retain their promised window, and watched archives retain the actual outcome. See Docs/MARKET_SIMULATION.md for schedules and offline behavior.

The catalog contains 50 fictional definitions across gaming/electronics, cameras and retro/collectibles, with 24 category-specific faults. [Canonical USD-cent value, regional price profiles and display currency are separate](Docs/REGIONAL_ECONOMY.md). All languages now share one economy. A new career defaults to TRY for Turkish and USD otherwise; display currency can be selected independently in Profile → Currency & language. Fixed fictional FX is 1 USD = 40 TRY, never live FX. Language/currency never change supply, value or difficulty. Character names and fictional neighborhoods are localized by language. Existing regional saves receive a backup and keep every cash amount, item and outstanding agreement; new market content follows shared rules.

[Career stages and expertise](Docs/TRADER_CAREER.md) unlock access without direct price, speed or fee bonuses. Existing inspection ranks remain; specialist endorsement requires varied studied models and diagnosed fault types. Messages/Profile link to two recurring clients with three connected requests each. Requests use full earned reports and actual market leads, with one accepted hunt and no offline expiry. Payments replace ordinary sale proceeds.

Profile also opens two three-piece collections with dedicated fictional product masters, stories and a chosen hunt on the market. Displayed objects retain capital and occupy inventory; return them to trading before sale/service/client supply. Completion grants a persistent Curator distinction, not money or a profit multiplier. Low-cash recovery offers clearly loss-making liquidation and capped service commissions on supplied goods, with no expertise/trust farming. The source of every receipt is preserved.

[The product art bible](Docs/PRODUCT_ART_BIBLE.md) separates model artwork, condition, seller presentation and earned findings; inspection can compare seller claims with observed reality. [Native motion rules](Docs/MOTION_DESIGN.md) coordinate short visual/audio/haptic feedback and respect Reduce Motion. Most products still use family photos; seven important collection/camera models have unique masters. Broader rare editions remain deferred.

Seller questions/offers, delivery, expert inspection and buyer interest use persisted timers. Normal Debug and Release use production pacing; isolated UI-test saves opt into accelerated timing. New replies sample 30–90 seconds before urgency scaling; delivery roughly 3–7 minutes; expert reports 15 minutes; buyer-interest observations 60–180 seconds before price/category scaling. A 45-minute sale window does not guarantee a buyer. Offline catch-up and genuine event-derived notification routes remain in place.

Profile → Competition opens **Weekly Flip** after three career sales. Everyone starts with the same $1,000 value, common weekly seed and fresh expertise, using the existing trading engines with a separate save. Monday 00:00 UTC resets archive previous results without touching career. A versioned, capped TraderScore measures realized performance; only finalized results submit to the matching recurring leaderboard. Play offline without signing in, earn 12 gameplay achievements locally, and connect deliberately to compare friends/world rank. Local finisher badges confer no economic reward. [Manual Apple setup and sandbox acceptance](Docs/GAME_CENTER_SETUP.md) are required before live Game Center can be verified. Direct friend challenges and Activities remain deferred; there is no monetization.

[Additional language research and editorial translation](Docs/LOCALIZATION_BACKLOG.md) is queued after this milestone. It will expand the shared world, not introduce country-specific economies.

DEBUG builds expose Developer tools under Profile for save reset, cash, market regeneration, hidden truth, forced responses and virtual time travel. Release builds exclude that screen and its actions. UI tests use isolated saves. No signing team or personal Xcode data is committed.

Continue unassisted human playtesting of the first session, returns, expertise, client continuity, collection desire, losses and recovery. Physical-device feedback, minimum-iOS runtime acceptance, legal naming/IP clearance and real retention remain open. Additional content and monetization should follow those observations, not passing tests alone.
