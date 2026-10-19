# PROJECT FLIP — Codex Master Brief
**Version:** 1.0  
**Date:** 2026-10-19  
**Target:** iPhone first / iOS first  
**Working title:** Project Flip  
**Final product name:** TBD — do not ship under “Kelepir” or any third-party marketplace-like name before trademark/name clearance.

---

# 0. Instructions to Codex

You are building a production-quality iOS mobile game, not a prototype-only demo and not a generic CRUD app.

Read this document fully before creating files.

## Absolute priorities

1. Build a **fun vertical slice first**.
2. Keep the game **offline-first** for v1.
3. Make the world feel **alive while the app is closed**.
4. Optimize for **short, repeated mobile sessions**.
5. Do not copy the UI, brand language, colors, iconography, naming, data, listings, photos, or trade dress of Sahibinden, Cebinden, Facebook Marketplace, Letgo, eBay, or any other marketplace/game.
6. Do not use real marketplace scraping or real third-party product/brand assets.
7. Do not add backend, accounts, multiplayer, subscriptions, battle passes, loot boxes, or real-money game-currency purchases in v1.
8. Do not introduce unnecessary frameworks or architectural layers.
9. Prefer deterministic, testable simulation logic.
10. Every system added must support one of these goals:
   - better deal-hunting decisions,
   - stronger anticipation,
   - meaningful risk,
   - progression,
   - retention,
   - monetization without destroying player trust.

## Development strategy

Do **not** attempt to build every feature in this document immediately.

Implementation order is mandatory:

**Phase A — 3-day vertical slice**
- market feed,
- listing detail,
- seller negotiation,
- buy item,
- inspect item,
- list item for sale,
- receive NPC offer,
- accept/counter,
- record profit/loss,
- save/load.

If this loop is not enjoyable, stop expanding scope and improve the loop.

Only after Phase A is playable should Codex proceed to:
- offline simulation,
- notifications,
- market trends,
- progression,
- content expansion,
- ads/IAP,
- analytics.

---

# 1. Product Vision

Project Flip is a **living second-hand marketplace trading simulator**.

The fantasy is not “own a store and tap upgrades.”

The fantasy is:

> “Can I find a deal that everyone else missed, understand the risk better than the seller/buyer, negotiate well, and flip it for a profit?”

The player browses a fictional second-hand marketplace, evaluates imperfect information, chats with sellers, makes offers, waits for replies, buys items, discovers hidden defects, repairs or holds inventory, creates listings, negotiates with buyers, follows changing market prices, participates in auctions, builds reputation, and gradually becomes a high-level trader/collector.

The world continues to evolve while the game is closed.

A player may close the game after making an offer and receive a notification 25 minutes later:

> “Mert countered: ₺7,400. Offer expires in 18 min.”

Later:

> “Your inspection is complete — one hidden issue was found.”

Later:

> “New buyer offer: ₺9,200.”

The player should often think:

> “I wonder if they replied.”
>
> “Did my item sell?”
>
> “Did the inspection find something bad?”
>
> “Did someone outbid me?”
>
> “Did I miss that deal?”

That anticipation is the retention engine.

---

# 2. One-Sentence Pitch

**A living second-hand market simulator where you hunt undervalued listings, negotiate with believable sellers and buyers, uncover hidden defects, react to changing prices, and flip products for profit while the market keeps moving even when the app is closed.**

---

# 3. Product Principles

## 3.1 Marketplace-first, not shop-first

The primary screen is a fictional marketplace feed.

The player’s main behavior is:
- browse,
- filter,
- inspect clues,
- message,
- evaluate,
- decide.

Do not make a 3D store the center of the experience.

## 3.2 Information is gameplay

The true value of an item is not immediately visible.

The player starts with incomplete information:
- condition may be uncertain,
- seller may be wrong,
- seller may hide something,
- market demand may be changing,
- photos/descriptions may contain clues.

The player’s advantage comes from learning.

## 3.3 Losing money must be possible

If nearly every trade is profitable, there is no game.

The player can:
- overpay,
- miss a defect,
- buy into a falling market,
- repair an item that is not worth repairing,
- hold inventory too long,
- reject a good offer,
- lose an auction,
- sell too cheaply,
- damage reputation.

Losses must feel fair and explainable.

## 3.4 Waiting creates anticipation, not punishment

Time is used to make the world feel alive:
- seller replies,
- shipping,
- inspection,
- repairs,
- buyer interest,
- auctions.

Waiting times should usually be minutes, not many hours.

Never use “wait 8 hours or pay money” as the core business model.

## 3.5 Offline state must be coherent

When the player returns after 90 minutes, the game should simulate what happened:
- messages arrived,
- offers arrived,
- listings gained views/favorites,
- inspections completed,
- repairs completed,
- auctions changed,
- market trends moved.

The player should see a concise “While you were away” summary.

## 3.6 Monetization cannot destroy the fantasy

Ads must never make buying/selling feel like a punishment.

No forced ad immediately after tapping Buy, Sell, Inspect, Message, or Accept Offer.

Rewarded ads should offer optional convenience/information.

---

# 4. Audience

## Primary

Age roughly 16–40.

Players who enjoy:
- business/tycoon games,
- flipping/reselling,
- marketplaces,
- bargaining,
- collecting,
- price speculation,
- “find the hidden gem” content,
- short mobile sessions.

## Turkey-specific appeal

The negotiation language and marketplace culture can feel familiar:
- “Son ne olur?”
- “Bugün alırım.”
- “Pazarlık payı var.”
- “Takas düşünür müsün?”
- “Kutusu/faturası var mı?”

These are localization flavor only. The game must remain globally understandable.

## Global appeal

Categories should be universal:
- gaming,
- cameras,
- watches,
- music gear,
- retro tech,
- phones/electronics,
- collectibles,
- sneakers,
- vintage items.

English localization should not be literal Turkish translation. NPC dialogue must feel native to each locale.

---

# 5. Competitive Positioning

## Known local / regional patterns

### Cebinden / Car Sales Simulator Pocket
Strength:
- proven appetite for mobile negotiation/trading loops,
- dynamic market fantasy,
- familiar classified-listing presentation.

Observed weakness:
- player reviews complain about excessive ads,
- progression ceiling,
- restrictions that push VIP/payment,
- “nothing left to do” after short progression.

### Thrift Shop Empire
Strength:
- second-hand goods,
- negotiation,
- fake products,
- repairs,
- value research,
- reputation.

Risk to us:
- generic “second-hand shop simulator” is no longer distinctive.

## Global patterns

Games such as pawn-shop, used-car, auction, storage and dealer simulators prove that:
- buy-low/sell-high is understandable,
- hidden information is compelling,
- bargaining is compelling,
- jackpot discoveries are shareable.

## Our differentiation

Project Flip is specifically:

1. **marketplace feed first,**
2. **information asymmetry first,**
3. **multi-category knowledge,**
4. **real-time-feeling asynchronous world,**
5. **offline event resolution + meaningful notifications,**
6. **dynamic demand and speculative inventory,**
7. **buyer/seller personalities and history,**
8. **collection goals beyond money.**

We are not making:
- a pawn-shop clone,
- a car dealer clone,
- a marketplace app clone,
- a 3D shop simulator.

---

# 6. Core Game Loop

## Loop A — Deal Hunt

1. Open market.
2. Browse listings.
3. Notice a potentially undervalued item.
4. Evaluate visible clues.
5. Inspect seller history.
6. Ask seller questions.
7. Estimate value/risk.
8. Make offer.
9. Wait or continue browsing.
10. Seller accepts / rejects / counters / ignores.
11. Buy or walk away.

## Loop B — Acquisition

1. Purchase succeeds.
2. Shipping/pickup timer begins.
3. Item arrives.
4. Player performs a basic self-inspection.
5. Optional paid in-game-currency professional inspection.
6. Hidden defects and real condition are partially/fully revealed.
7. Player chooses:
   - keep,
   - repair,
   - sell as-is,
   - add to collection.

## Loop C — Resale

1. Player creates listing.
2. Chooses asking price.
3. Chooses disclosure level/description style.
4. Listing generates views/favorites/messages over time.
5. NPC buyers send offers.
6. Player:
   - accepts,
   - rejects,
   - counters,
   - waits.
7. Sale completes.
8. Profit/loss is calculated.
9. Reputation may change.

## Loop D — Portfolio

1. Hold inventory.
2. Watch market trend.
3. Decide when to sell.
4. Balance cash vs stock.
5. Unlock higher-value categories.
6. Build collection and reputation.

---

# 7. Session Design

The game must support multiple session lengths.

## 30-second session
- answer one counteroffer,
- accept one buyer offer,
- collect one completed inspection result.

## 2-minute session
- check notifications,
- browse newest listings,
- adjust one sale price.

## 5-minute session
- negotiate,
- buy an item,
- start inspection/repair,
- list one item.

## 15-minute session
- actively hunt deals,
- compare several listings,
- manage inventory,
- participate in auction.

## 30+ minute session
- deep market session,
- optimize portfolio,
- collection hunting,
- multiple trades.

Do not make the player perform repetitive busywork to fill time.

---

# 8. First 7 Days of Player Experience

This is a design target, not a hard wall-clock script.

## First 5 minutes

Goal: player understands the fantasy without tutorial overload.

Player:
1. starts with a modest bankroll,
2. sees 6–10 listings,
3. gets a guided example,
4. asks seller one question,
5. makes one offer,
6. receives fast response,
7. buys first item,
8. performs immediate basic inspection,
9. lists it,
10. receives first buyer offer quickly,
11. completes first profit.

The first trade should usually be positive but not enormous.

The player must feel:
> “I understood why that was a good deal.”

## Day 1

Unlocked:
- basic electronics,
- simple seller personalities,
- basic inspection,
- selling,
- reputation,
- watchlist.

Retention hook:
- after first longer session, player leaves with at least one unresolved state:
  - seller reply pending,
  - item shipping,
  - item listed for sale,
  - inspection pending.

## Day 2

Unlock:
- category knowledge progression,
- market trend screen,
- more deceptive/inexperienced sellers.

Player starts seeing:
- bad deals,
- borderline deals,
- good deals.

## Day 3

Unlock:
- second category, ideally Cameras or Retro Gaming,
- category-specific defects,
- repair decisions.

Introduce:
- first meaningful loss possibility.

## Day 4

Unlock:
- client requests.

Example:
> “I need a clean retro handheld under ₺8,000 within 24 hours.”

This is a diegetic daily quest.

## Day 5

Unlock:
- collections,
- rare variants.

Money is no longer the only goal.

## Day 6

Unlock:
- limited timed market events (auctions are a conditional stretch goal only),
- Game Center introduction after the player understands the core economy.

Do not show Game Center as onboarding friction on first launch.

Suggested first social prompt:
> “Want to compare this week’s trading score with friends?”

## Day 7

Unlock:
- stronger market events,
- portfolio speculation,
- first **Weekly Market Challenge**,
- recurring Game Center leaderboard for the weekly challenge,
- first naturally-earned Game Center achievements.

By Day 7 player should have at least four reasons to return:
1. active deals,
2. progression/wealth,
3. collection/rare item hunt,
4. weekly social competition / Game Center prestige.

---

# 9. Game Time and Offline Simulation

This is a core technical feature.

## 9.1 Requirements

The game must simulate asynchronous events while closed without requiring a backend.

Use:
- persisted event queue,
- wall-clock timestamps,
- deterministic random seeds where practical,
- local notifications for selected meaningful events.

## 9.2 Event model

Suggested concept:

```swift
struct GameEvent: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let resolveAt: Date
    let type: GameEventType
    let payload: EventPayload
    let seed: UInt64
    var status: GameEventStatus
}
```

Possible event types:
- sellerReply,
- sellerCounterOffer,
- shipmentArrived,
- inspectionCompleted,
- repairCompleted,
- buyerOffer,
- listingExpired,
- auctionOutbid,
- auctionEnded,
- marketEventStart,
- marketEventEnd,
- clientRequestExpiry.

## 9.3 Resolution logic

On:
- app launch,
- foreground,
- relevant user action,

resolve all pending events with:

`resolveAt <= now`

in chronological order.

Then:
- update game state,
- schedule/cancel subsequent events,
- create “while away” summary,
- refresh relevant notifications.

## 9.4 Clock manipulation protection

This is an offline single-player game. Do not over-engineer anti-cheat.

However:
- persist lastKnownWallClock,
- if device time moves backward significantly, avoid negative progression,
- if time moves forward unrealistically, cap some high-value generated outcomes,
- never corrupt save data,
- do not punish normal timezone/DST changes.

Design for player trust, not authoritarian anti-cheat.

---

# 10. Local Notifications

Use Apple UserNotifications.

Ask for notification permission only after the player has experienced a relevant asynchronous event, not immediately on first launch.

Suggested permission moment:
> “Want us to tell you when sellers reply and offers arrive?”

## Notification categories

User settings must allow categories to be individually enabled/disabled:

- Offers & negotiations
- Shipping & inspections
- Auctions
- Market events
- Client requests

## Good notifications

- “Mert countered: ₺7,400. Offer expires in 18 min.”
- “Your Vega X4 inspection is complete.”
- “New buyer offer: ₺9,200.”
- “You’ve been outbid. 9 min remain.”
- “The item on your watchlist dropped 12%.”
- “Repair complete: Orion Pocket is ready to list.”

## Bad notifications

Never send:
- “We miss you!”
- “Come back now!”
- fake urgency,
- fake offers,
- events that did not exist in simulation.

## Scheduling rules

Schedule only events already created in game state.

If game state changes:
- cancel obsolete notifications,
- replace changed timers,
- avoid duplicate pending notifications.

Keep a stable mapping:
`GameEvent.id -> UNNotificationRequest.identifier`

---

# 11. Marketplace Feed

The marketplace feed is the hero screen.

## Listing card should show

- generated item art,
- item/model name,
- asking price,
- seller display name,
- seller rating / trade count,
- location,
- age of listing,
- 1–2 visible metadata hints,
- optional labels such as:
  - New
  - Price drop
  - Popular
  - Suspicious
  - Watched

Do **not** reveal “good deal” as an objective truth by default.

The player should infer it.

## Feed controls

V1:
- category,
- min/max price,
- newest,
- watched,
- search fictional product names.

Later:
- seller rating,
- condition,
- distance,
- rarity.

## Feed refresh

Listings have lifetimes.

NPC competitors may buy listings.

Player can genuinely miss opportunities.

Do not fake “27 people are viewing” unless the simulation generated competition state.

---

# 12. Seller System

Sellers must feel different.

## Hidden personality dimensions

Suggested parameters:

```text
knowledge: 0...1
honesty: 0...1
patience: 0...1
urgency: 0...1
bargainingSkill: 0...1
responseSpeed: 0...1
riskTolerance: 0...1
attachmentToItem: 0...1
```

## Archetypes

Examples:
- Honest casual seller
- Clueless owner
- Urgent seller
- Professional reseller
- Stubborn seller
- Friendly seller
- Manipulative seller
- Collector
- Suspicious new account

Archetypes should only initialize parameters. Behavior should still have variance.

## Seller knowledge vs truth

Important distinction:

A seller can give false information because:
1. they are lying,
2. they genuinely do not know.

This avoids making every inconsistency “villain NPC.”

## Seller memory

Persist previous transactions.

If player traded with them before, profile may show:
- previous trades,
- disputes,
- trust history.

Later versions can create recurring sellers.

---

# 13. Negotiation System

Avoid a single “Offer -10%” slider.

The negotiation should remain lightweight but expressive.

## Player actions

V1:
- numeric offer,
- “I can buy today” modifier,
- “Item has issues” modifier if known,
- “Meet me halfway” counter,
- accept,
- reject,
- walk away.

Later:
- bundle offers,
- trade-in,
- delivery negotiation.

## Seller decision model

Seller acceptance should depend on:
- reservation price,
- urgency,
- player reputation,
- offer history,
- patience,
- current demand,
- competing NPC interest,
- bargaining skill,
- dialogue modifier.

Do not make seller acceptance purely random.

## Negotiation fatigue

Repeated insulting offers can:
- lower seller patience,
- cause seller to stop responding,
- increase their minimum,
- create short cooldown.

---

# 14. Item System

## V1 categories

Start with **three categories max**:

1. Gaming / consumer electronics
2. Cameras
3. Retro tech / collectibles

Do not start with phones, watches, sneakers, music gear, furniture, etc. Add later.

## Item definition vs item instance

### ItemDefinition
Static fictional product family.

```text
id
category
brand
model
releaseEra
baseMarketValue
valueVolatility
rarity
possibleDefects
repairProfile
inspectionProfile
artAssetID
```

### ItemInstance
A generated physical item.

```text
definitionID
age
condition
cosmeticScore
functionalScore
hiddenDefects
authenticity
includedAccessories
repairHistory
purchasePrice
acquiredAt
```

## Fictional brands

Do not use Apple, Sony, Rolex, Nike, Nintendo, Canon, etc. in v1.

Create original names and visual identities.

Names must not be obvious near-copies of trademarks.

---

# 15. Category-Specific Knowledge

Each category must teach different clues.

## Gaming / electronics

Possible defects:
- controller drift,
- HDMI issue,
- overheating,
- storage failure,
- noisy fan,
- damaged ports,
- third-party accessories.

## Cameras

Possible attributes:
- shutter count,
- sensor damage,
- lens fungus,
- scratches,
- autofocus issues,
- battery condition.

## Retro / collectibles

Possible attributes:
- region,
- completeness,
- original packaging,
- replacement parts,
- authenticity,
- edition rarity,
- cosmetic condition.

The player should gradually learn what matters.

---

# 16. Inspection

## Self-inspection

Free.
Immediate.
Limited by:
- player category knowledge,
- obviousness of defect,
- tool access.

## Professional inspection

Costs game currency.
Takes real-world minutes.
Reveals more data.

Example:
- 15–30 min,
- no real-money requirement.

## Rewarded ad use

Optional:
> “Get a second expert opinion now.”

Rewarded ad may:
- reveal one additional clue,
- speed one inspection,
- provide a market valuation range.

Never reveal everything every time.

---

# 17. Repairs

Repairs are economic decisions, not mandatory chores.

Each defect has:
- repair cost,
- repair time,
- success probability if relevant,
- expected value improvement,
- possibility of no value gain.

Player can sell as-is.

## Repair service tiers

Later:
- cheap/slow/risky,
- balanced,
- expensive/fast/reliable.

V1 can use one standard service.

---

# 18. Player Selling

Player creates a listing with:

- asking price,
- item condition summary,
- optional notes,
- disclosure choices,
- listing duration.

Generated listing performance depends on:
- price competitiveness,
- demand,
- category trend,
- reputation,
- item desirability,
- time of day / simulated market traffic,
- rarity.

## Buyer events

NPC buyers can:
- favorite,
- message,
- make offer,
- withdraw,
- counter,
- buy at asking price in rare cases.

## Buyer personalities

Examples:
- bargain hunter,
- collector,
- impatient buyer,
- cautious buyer,
- reseller,
- lowballer.

---

# 19. Reputation and Ethics

The player is also a market participant.

Reputation should matter.

Factors:
- accurate disclosure,
- shipping reliability,
- cancelled sales,
- misleading descriptions,
- disputes.

The player may choose to hide a defect, but this must create real long-term downside.

Possible consequences:
- bad review,
- refund/dispute,
- lower buyer trust,
- slower sales,
- worse offers,
- restricted premium marketplace access.

Do not moralize. Make it an economic choice with consequences.

---

# 20. Market Economy

## 20.1 Market value

Each item has a base value.

Final fair market value can be modeled as:

```text
fairValue =
baseValue
× categoryTrend
× modelTrend
× conditionModifier
× rarityModifier
× seasonModifier
× localeModifier
```

Use bounded randomness.

## 20.2 Asking price

Seller asking price is not fair value.

```text
askingPrice =
fairValue
× sellerKnowledgeBias
× sellerUrgencyBias
× sellerPersonalityBias
× randomNoise
```

A clueless seller may underprice.
A stubborn seller may overprice.
A professional seller is usually near market.

## 20.3 Dynamic trends

Categories/models can move.

Examples:
- camera demand +12%,
- retro gaming -7%,
- a fictional new model launches and old model drops,
- a fictional creator makes an old device trend,
- seasonal demand increases.

Events must have:
- start time,
- duration,
- affected scope,
- magnitude,
- reason text.

Do not generate extreme price swings too frequently.

---

# 21. Inventory and Capital Pressure

Money should not be the only constraint.

Player has:
- cash,
- inventory slots,
- optionally repair queue capacity.

Inventory creates opportunity cost.

A player who spends all cash on five slow-moving items may miss a great deal.

This creates natural strategy without artificial energy systems.

---

# 22. Collections

Collections solve the “I have ₺50M, now what?” problem.

Possible collection sets:
- classic handhelds,
- vintage cameras,
- rare colorways,
- complete-in-box items,
- limited editions.

Rare items create tension:

> Sell for a large profit, or keep to complete a set?

Collection completion may award:
- cosmetic badges,
- marketplace themes,
- profile frames,
- non-economic prestige.

Avoid pay-to-complete.

---

# 23. Rare Variants and Shareable Moments

Some items can have rare attributes:
- prototype,
- launch edition,
- factory error,
- unusual color,
- serialized limited edition,
- signed fictional creator item.

Rare finds should be uncommon enough to feel special.

Provide a clean share card:
- item art,
- rarity,
- purchase price,
- estimated value,
- profit.

This is intended for TikTok/Reels/X/Discord organic sharing.

---

# 24. Auctions

Not required for the 3-day vertical slice.

Stretch only after the core loop, offline event system, progression, Game Center, monetization, testing, localization and polish are healthy and time remains. Otherwise defer auctions to V1.1.

Auction behavior:
- visible current bid,
- bid increments,
- NPC competitors,
- closing time,
- outbid notifications.

No fake real-player language.
NPC bidders are clearly game-world entities if needed.

Auctions create strong return triggers:
> “You’ve been outbid. 8 min remaining.”

---

# 25. Client Requests

This replaces generic daily missions.

NPC:
> “I’m looking for a clean retro handheld under ₺12,000. Can you find one by tomorrow?”

Player:
- accepts request,
- hunts market,
- decides margin,
- fulfills or fails.

Benefits:
- creates category-specific goals,
- moves inventory,
- adds narrative flavor,
- produces daily variety.

---

# 26. Retention Design

Retention must come from open loops, not manipulative spam.

## Core open loops

- pending seller response,
- pending counteroffer,
- shipment,
- inspection,
- repair,
- live listing,
- buyer offer,
- watchlist price movement,
- auction,
- market trend,
- client request,
- weekly challenge rank movement,
- friend Game Center challenge.

## Return cadence

Target:
- some outcomes in 2–10 min,
- some in 15–45 min,
- occasional longer 1–3 hour events,
- avoid forcing overnight waits in the early game.

The player should often leave voluntarily with something unresolved.

---

# 27. “While You Were Away” Screen

On return after meaningful elapsed time, show:

### While you were away

- 2 seller replies
- 1 buyer offer
- 18 new listing views
- 3 favorites
- inspection completed
- one watched listing sold

Allow tap-through.

Do not overwhelm with every simulation event.

Group low-value events.

---

# 28. Game Center / Apple Games Integration

Game Center is a **first-class retention and discovery layer**, not a replacement for the core game.

The entire core economy must remain playable offline without Game Center.

Game Center should add:
- friendly competition,
- prestige,
- achievements,
- repeatable weekly goals,
- friend challenges,
- deep links into challenge modes,
- additional Apple ecosystem discovery surfaces.

Apple currently supports:
- classic leaderboards,
- recurring leaderboards,
- achievements,
- challenges built on leaderboards,
- activities that deep-link players into specific game content.

Apple also surfaces Game Center challenge/activity experiences inside the Apple Games ecosystem and other OS surfaces. Treat this as **incremental discoverability**, not as a guaranteed App Store ranking boost.

## 28.1 No custom backend required for V1

For v1, use GameKit / Game Center for:
- player authentication,
- leaderboard score submission,
- achievements,
- supported challenges,
- activities.

Do not build our own account system or leaderboard backend just to support social comparison.

The local save remains the source of truth for the single-player game.

Game Center is the source of truth only for the Game Center features it owns.

## 28.2 Authentication strategy

Do not block first launch on Game Center.

Recommended flow:

1. Launch directly into the game.
2. Attempt normal Game Center authentication using Apple’s expected GameKit flow.
3. If authentication needs visible UI, present it only when appropriate.
4. If authentication fails or the player is not signed in, the game continues normally.
5. Social UI clearly explains that Game Center is optional.

Never make Game Center login mandatory for:
- saving locally,
- buying/selling,
- progression,
- notifications,
- collections.

## 28.3 Leaderboard philosophy

Do **not** use a single permanent “richest player ever” leaderboard as the primary competitive surface.

A permanent wealth leaderboard:
- becomes dominated by early players,
- rewards raw playtime,
- discourages new users,
- is vulnerable to offline save manipulation,
- eventually becomes meaningless.

Primary competition should use **recurring leaderboards**.

Suggested V1 leaderboards:

### Weekly Trader Score
Reset: weekly.

Score is a bounded composite derived from:
- realized trade profit,
- return on investment,
- successful trade volume,
- reputation quality.

Avoid simply submitting lifetime bankroll.

### Deal of the Week
Reset: weekly.

Score:
- best legitimate percentage return on one completed trade,
- use sensible caps and validation rules so tiny-denominator exploits do not dominate.

Example:
Purchased for 2,400
Sold for 14,800
Return = +516%

### Optional category leaderboards — later
- Camera Masters
- Retro Masters
- Gaming Masters

Do not create dozens of leaderboards before there is proven demand.

## 28.4 Weekly Market Challenge

This should become one of the strongest medium-term retention systems.

A Weekly Market Challenge is a separate, standardized run with controlled starting conditions.

Example:

### Camera Craze
Duration: 7 days  
Starting capital: 50,000 challenge credits  
Allowed category: Cameras  
Goal: highest realized trading score

Important:
- challenge bankroll is separate from main save,
- everybody gets the same rules,
- challenge rewards are prestige/cosmetic only,
- challenge results do not inject large economic rewards into main progression.

This gives a late-starting player a fair reason to compete because the leaderboard resets.

## 28.5 Game Center Challenges

Where supported and appropriate, associate suitable leaderboards with Game Center Challenges.

Use case:
> “Beat your friend’s 24-hour flipping score.”

A challenge can turn our largely single-player game into a social competition without building multiplayer infrastructure.

Good challenge formats:
- Highest profit in 24h
- Best ROI in 3 attempts
- Camera-only flip challenge
- Retro-only challenge
- Fixed-bankroll challenge

Challenge outcomes should award:
- prestige,
- cosmetic recognition,
- achievement progress.

Do not award large amounts of main-economy cash.

## 28.6 Game Center Activities

Activities should deep-link directly into meaningful game content.

Possible activities:
- Weekly Market Challenge
- Camera Craze
- Retro Rush
- Auction Sprint — later
- Daily Deal Hunt — later

When a player enters through an activity, route them directly to the relevant game mode/state instead of dumping them on the home screen.

Keep activity identifiers stable once shipped.

## 28.7 Achievements

Achievements must celebrate behavior, mastery and memorable failures — not only grind.

Suggested initial set:

### First Flip
Complete first profitable sale.

### Natural Trader
Earn 100%+ return on one trade.

### That Hurt
Lose a meaningful amount on one completed trade.

### Detective
Discover 10 hidden defects before purchase.

### Negotiator
Close a purchase at least 25% below original asking price.

### Collector
Complete first collection set.

### Lucky Find
Acquire first top-rarity item.

### Millionaire
Reach defined net-worth milestone.

### Trusted Seller
Reach a high reputation threshold.

### Market Veteran
Complete a substantial number of trades.

Avoid achievements that require:
- watching ads,
- spending real money,
- enabling notifications.

## 28.8 Anti-cheat / trust boundary

The core game is offline-first.

Therefore Game Center competitive scores **must not be treated as secure financial truth**.

Client-side saves can potentially be manipulated.

For V1:

- leaderboard rewards are prestige/cosmetic,
- do not grant rare economic items for top rank,
- do not grant meaningful main-game currency for top rank,
- cap impossible score ranges,
- reject obviously invalid local values before submission,
- record local score provenance for debugging,
- submit only completed/finalized challenge results,
- never allow a leaderboard rank to alter marketplace odds.

If competitive integrity becomes commercially important, add server-authoritative challenge verification in a later version.

Do not build that backend preemptively.

## 28.9 Game Center score normalization

Currency varies by localization and game balance changes over time.

Therefore do not submit raw “₺ profit” as the canonical competitive value if regional economies can differ.

Prefer an internal integer `TraderScore`.

Illustrative formula only:

```text
TraderScore =
normalizedRealizedProfit
+ roiBonus
+ reputationBonus
+ challengeObjectiveBonus
```

Rules:
- deterministic,
- integer based,
- versioned,
- capped,
- documented in code,
- impossible to overflow 64-bit leaderboard limits.

Persist:
- scoringAlgorithmVersion.

A balance patch must not silently reinterpret already-submitted scores.

## 28.10 Social UI

Add an optional Competition surface, but keep the marketplace primary.

Possible placement:
Profile → Competition

Display:
- current weekly rank,
- friends rank,
- weekly challenge status,
- achievement progress,
- best flip,
- previous weekly badge.

Avoid turning the main feed into a social dashboard.

## 28.11 Cosmetic seasonal recognition

Examples:
- Weekly Top 10 badge,
- Top 100 frame,
- completed challenge badge,
- rare achievement title.

These may appear in the player profile locally.

Do not make competitive cosmetics purchasable if they are meant to represent skill.

## 28.12 Development timing

Game Center is **not part of the first 72-hour vertical slice**.

Add it only after:
- trading loop works,
- scoring is deterministic,
- profit/loss is reliable,
- save/load works.

Recommended implementation point:
Days 19–21 alongside retention systems.

Minimum V1 Game Center scope:
1. authenticate player,
2. 6–10 achievements,
3. one weekly recurring leaderboard,
4. Weekly Market Challenge score submission,
5. Game Center access from Profile/Competition,
6. deep-link architecture prepared for Activities.

Stretch if schedule allows:
- second leaderboard,
- first Game Center Challenge,
- first Activity.

## 28.13 Definition of Done — Game Center V1

- game works with Game Center unavailable,
- authentication never blocks core gameplay,
- leaderboard score submissions are idempotent where possible,
- weekly challenge uses standardized starting conditions,
- achievement progress survives relaunch,
- Game Center UI can be opened from the game,
- invalid/impossible scores are not submitted,
- no leaderboard reward materially affects the main economy,
- TR/EN Game Center metadata is prepared in App Store Connect,
- identifiers are centralized and not scattered through views.

---

# 29. Monetization

V1 monetization principles:

1. The complete game is playable without paying.
2. No pay-to-win.
3. No real-money cash packs in v1.
4. No loot boxes.
5. No subscription in v1.
6. Do not sell relief from intentionally bad game design.

## 28.1 Rewarded ads

Strongest ad format for this game.

Possible rewards:
- one expert clue,
- instant second opinion,
- speed up one inspection/repair,
- market trend report,
- one optional feed refresh.

The player explicitly chooses it.

## 28.2 Interstitial ads

Use sparingly and only at natural transitions.

Initial tuning target:
- never during tutorial,
- never immediately after core action button,
- minimum several completed meaningful actions between ads,
- cooldown-based,
- remotely configurable later if backend is added.

For offline v1, keep frequency constants in a config file.

## 28.3 Remove Ads IAP

One-time purchase using StoreKit 2.

Effect:
- removes interstitial ads,
- rewarded ads may remain available voluntarily if they give optional rewards, but never become mandatory.

## 28.4 Supporter Pack — later

Possible:
- Remove Ads,
- cosmetic profile badge,
- marketplace theme,
- UI sound pack.

No economy advantage.

---

# 30. Why No Currency Packs in V1

Selling game cash undermines the central fantasy.

If the player can buy millions instantly:
- deal skill loses meaning,
- risk loses meaning,
- progression becomes suspect,
- losses become less meaningful.

Validate retention and economy first.

---

# 31. Analytics

Keep analytics privacy-conscious.

Minimum events:

```text
session_started
session_ended
listing_opened
seller_question_sent
offer_sent
offer_accepted
offer_rejected
offer_countered
item_purchased
inspection_started
inspection_completed
repair_started
repair_completed
player_listing_created
buyer_offer_received
item_sold
trade_profit
trade_loss
category_unlocked
rare_item_found
notification_permission_prompted
notification_permission_result
notification_opened
rewarded_ad_offered
rewarded_ad_completed
interstitial_shown
remove_ads_viewed
remove_ads_purchased
game_center_auth_started
game_center_auth_succeeded
game_center_auth_failed
achievement_unlocked
leaderboard_score_submitted
leaderboard_opened
weekly_challenge_started
weekly_challenge_completed
game_center_challenge_started
game_center_activity_opened
```

Important metrics:
- D1 retention
- D3 retention
- D7 retention
- sessions per day
- average session length
- trades per active day
- percentage of losing trades
- time to first trade
- time to first notification return
- notification opt-in
- notification open rate by category
- rewarded-ad engagement
- Remove Ads conversion
- progression speed
- bankruptcy/soft-lock rate
- Game Center sign-in success rate
- percentage of active players opening leaderboards
- weekly challenge participation rate
- weekly challenge completion rate
- sessions triggered after a Game Center challenge/activity
- retention difference between Game Center participants and non-participants

Do not optimize ad impressions before retention.

---

# 32. Economy Balancing

Build a headless simulation test harness.

Codex should support running thousands of simulated players with simple strategies.

Example bot strategies:
- buy anything >20% under estimated fair value,
- conservative inspector,
- reckless buyer,
- long-term holder,
- aggressive negotiator.

Measure:
- median bankroll over simulated days,
- percentile distribution,
- bankruptcy rate,
- average profit per category,
- exploit loops,
- progression unlock time,
- inventory lock rate.

Target:
- player can recover from mistakes,
- no category prints infinite money,
- no guaranteed profit strategy,
- no early unrecoverable death spiral.

---

# 33. Bankruptcy / Recovery

Avoid hard game-over.

If player reaches very low cash:
- small client request,
- starter marketplace opportunities,
- ability to sell inventory,
- one-time low-value recovery job.

Do not give infinite free money.
Do not force IAP to recover.

---

# 34. UX Structure

Portrait-first iPhone.

Main navigation can resemble a fictional “trader phone,” but not an existing marketplace.

Suggested tabs:

- Market
- Messages
- Inventory
- Selling
- Profile

Optional Wallet/Trends inside Profile or Market.

## Primary flows

### Buy flow
Market → Listing → Seller → Offer → Purchase → Delivery → Inspection → Inventory

### Sell flow
Inventory → Create Listing → Live Listing → Buyer Offer → Negotiation → Sale

### Async return flow
Notification → Deep link → Relevant event → Action

Deep links should open exact object/state where possible.

---

# 35. Visual Direction

Goal:
- polished,
- modern,
- tactile,
- game-like without looking childish,
- not a clone of any classified marketplace.

Avoid:
- Sahibinden yellow/black identity,
- recognizable third-party marketplace layouts,
- copied iconography,
- copied terminology,
- copied cards,
- copied navigation.

Create original:
- palette,
- logo,
- card system,
- typography hierarchy,
- fictional brand illustrations.

Product art can initially use simple original vector/3D-like illustrations or generated placeholder shapes, then be replaced.

---

# 36. Technical Architecture

## Stack

- SwiftUI
- SwiftData or lightweight persistence abstraction
- GameKit / Game Center
- StoreKit 2
- UserNotifications
- OSLog
- XCTest / Swift Testing as appropriate
- AdMob later in implementation
- no backend for v1

Target iOS 17+ unless a project requirement later changes this.

Use latest stable Xcode/Swift available in the development environment.

## Suggested modules / folders

```text
ProjectFlip/
  App/
  Core/
    Clock/
    RNG/
    Money/
    Config/
  Domain/
    Items/
    Sellers/
    Buyers/
    Listings/
    Negotiation/
    Inspection/
    Repair/
    Market/
    Events/
    Progression/
  Simulation/
    MarketEngine/
    EventEngine/
    PricingEngine/
    ListingGenerator/
    SellerEngine/
    BuyerEngine/
  Persistence/
  Notifications/
  GameCenter/
  Monetization/
  Analytics/
  UI/
    Market/
    ListingDetail/
    Messages/
    Inventory/
    Selling/
    Inspection/
    Profile/
    Components/
  Resources/
    SeedData/
    Localization/
  Tests/
```

Do not create modules just for aesthetic architecture.
Keep dependencies straightforward.

---

# 37. Core Domain Types

Suggested high-level types:

```swift
PlayerState
Wallet
PlayerReputation
CategoryProgress

ItemDefinition
ItemInstance
ItemDefect

SellerProfile
BuyerProfile
MarketplaceListing
PlayerListing

Conversation
Message
NegotiationState
Offer

InspectionJob
RepairJob
Shipment

MarketState
MarketTrend
MarketEvent

GameEvent
GameEventQueue

Collection
CollectionEntry
```

Use strongly typed IDs where practical.

Money:
- use integer minor units or Decimal,
- never Double for currency calculations.

---

# 38. Randomness

Randomness should be:
- reproducible in tests,
- injectable,
- seeded for generated listings/events where useful.

Create an RNG abstraction rather than scattering `Int.random` everywhere.

A listing’s generated hidden facts should not change when the view redraws.

---

# 39. Persistence

Requirements:
- save automatically after meaningful state change,
- crash-safe,
- migration-friendly,
- no save corruption if notification arrives before launch.

Persist:
- player state,
- inventory,
- active listings,
- conversations,
- event queue,
- market state,
- collection state,
- settings,
- last simulation timestamp.

Do not persist derived UI state unnecessarily.

---

# 40. Performance

Feed may contain many generated listings.

Avoid:
- expensive recalculation in SwiftUI body,
- generating listing truth repeatedly,
- large JSON parsing every render.

Generate/persist listing snapshots.

Use pagination/windowing if feed becomes large.

---

# 41. Accessibility and Localization

Initial localizations:
- Turkish
- English

All user-facing strings must be localized from the start.

Support:
- Dynamic Type reasonably,
- VoiceOver labels on core controls,
- reduced-motion behavior where needed,
- sufficient contrast.

Money formatting should use locale-aware display, while the internal game economy can use a fictional or locale-selected currency model.

For Turkey:
- ₺ presentation.

For English/global build:
- choose locale-based currency only if economy tuning remains coherent, otherwise use a fictional neutral currency until regional economy tables exist.

---

# 42. Legal / IP Guardrails

This section is mandatory.

## 41.1 Do not copy a marketplace

The concept of:
- listings,
- offers,
- messaging,
- buying and selling

is not a license to copy another company’s expression, UI, brand, database, imagery, or trade dress.

Do not:
- use “Sahibinden” in product name, subtitle, screenshots, keywords, or marketing,
- use their logo,
- use yellow/black as a deliberate lookalike identity,
- reproduce their screen layouts,
- reproduce their icons,
- reproduce listing text,
- scrape listings,
- scrape prices,
- use seller identities,
- use listing photos,
- claim affiliation.

## 41.2 Do not copy Cebinden

Do not reuse:
- app name,
- fictional car brands,
- UI,
- text,
- art,
- progression,
- monetization wording,
- dialogue,
- exact feature arrangement.

We are borrowing a genre pattern, not implementation/content.

## 41.3 Third-party brands

V1 uses fictional product brands.

Do not include real logos or product photography unless separately licensed/cleared.

## 41.4 Store compliance

Apple explicitly rejects copycat/impersonator apps.
Google Play prohibits impersonation and IP infringement.

Product identity must be obviously original.

## 41.5 Name clearance

“Project Flip” is a codename only.

Before final brand selection:
- search App Store,
- search Google Play,
- search web/domain/social handles,
- check TÜRKPATENT and relevant international marks,
- get legal review if commercial launch has meaningful traction.

This document is product planning, not legal advice.

---

# 43. Privacy

V1 goal:
- no account,
- no social graph,
- no real marketplace data,
- no user-generated public content,
- no server profile.

Ads/analytics SDKs create privacy obligations.

Before release:
- audit all SDK data collection,
- configure App Privacy labels,
- implement required consent flow,
- use ATT only if tracking behavior requires it,
- publish a privacy policy.

Do not request permissions unrelated to clear product functionality.

---

# 44. V1 Non-Goals

Do not build these unless this file is explicitly revised:

- Android version
- multiplayer
- real user marketplace
- backend accounts
- Firebase auth
- live chat with humans
- user-generated public listings
- real money trading
- crypto
- real product price API
- Sahibinden / eBay / Facebook / Letgo integration
- 3D walkable store
- avatar character controller
- clans
- guilds
- real-time PvP
- custom/server-hosted leaderboard backend
- global player auction house
- subscriptions
- battle pass
- loot boxes
- paid game-currency packs
- 10+ categories
- AI/LLM network dialogue generation at runtime

---

# 45. MVP Content Scope

Target after vertical slice:

## Categories
3

## Fictional item definitions
~45–60 total

Example:
- 20 gaming/electronics
- 15 camera
- 15–25 retro/collectible

## Seller archetypes
8

## Buyer archetypes
6

## Defects
~20–30 total across categories

## Market events
15–20 templates

## Client requests
15–20 templates

## Rare variants
10–15

## Collection sets
3–5

Content should be data-driven, not hardcoded into views.

---

# 46. 30-Day Build Plan

## Days 1–3 — Vertical slice

Build:
- app shell,
- persistence,
- basic marketplace feed,
- one category,
- 10 item definitions,
- listing detail,
- seller profile,
- offer/counter/accept,
- instant first-version delivery,
- simple inspection,
- inventory,
- create listing,
- NPC buyer offer,
- sell,
- profit/loss history.

Definition of Done:
A tester can complete five trades and understand why each made or lost money.

No ads.
No advanced animation.
No auctions.

## Days 4–7 — Simulation foundation

Build:
- GameClock,
- EventQueue,
- offline event resolution,
- seller delayed responses,
- shipping timers,
- inspection timers,
- buyer-offer timers,
- “while away” summary,
- save/load tests.

Then:
- local notification scheduling,
- notification categories,
- deep links to event target.

## Days 8–11 — Market depth

Build:
- dynamic fair value,
- asking-price model,
- seller personalities,
- competition,
- listing expiration,
- market trends,
- watchlist.

## Days 12–15 — Category depth

Add:
- Cameras,
- Retro,
- category-specific defects,
- category knowledge,
- repairs,
- second-order decisions.

## Days 16–18 — Progression

Add:
- category unlocks,
- inventory capacity,
- reputation,
- collections,
- rare variants,
- client requests.

## Days 19–21 — Retention + Game Center

Tune:
- event timing,
- notification value,
- first-session pacing,
- Day 1–Day 7 progression,
- while-away summary,
- onboarding.

Implement after the core loop is stable:
- Game Center authentication,
- initial achievements,
- one weekly recurring leaderboard,
- Weekly Market Challenge scoring,
- Competition entry point,
- score validation/caps,
- optional Activity/Challenge integration if schedule remains healthy.

## Days 22–23 — Monetization

Implement:
- AdMob rewarded ad,
- limited interstitial,
- StoreKit 2 Remove Ads,
- test ad IDs in dev,
- consent/privacy flow.

Do not tune for maximum ads.

## Days 24–25 — Balance simulation

Build bots.
Run large simulations.
Fix:
- economy exploits,
- bankruptcy traps,
- category imbalance,
- progression pacing.

## Days 26–27 — UI polish

- animations,
- haptics,
- sound,
- empty states,
- errors,
- accessibility,
- Turkish and English pass.

## Day 28 — Legal/store pass

- remove placeholder third-party-like assets,
- verify fictional brands,
- app name review,
- privacy policy,
- App Privacy,
- screenshots/metadata,
- review notes.

## Days 29–30 — TestFlight / App Store

- crash pass,
- analytics verification,
- notification verification,
- purchase restore testing,
- clean install,
- migration test,
- App Store submission.

---

# 47. First 72 Hours — Exact Codex Backlog

Codex should begin here.

## Task 1 — Project skeleton

Create iOS SwiftUI project structure.

Requirements:
- portrait iPhone first,
- dependency-light,
- compile cleanly,
- basic test target,
- localization files for TR/EN,
- no ad SDK yet.

## Task 2 — Seed domain model

Implement:
- Money
- ItemDefinition
- ItemInstance
- SellerProfile
- MarketplaceListing
- Offer
- PlayerState

Use sample data.

## Task 3 — Deterministic listing generator

Generate listings from:
- item base value,
- item condition,
- seller knowledge,
- seller urgency,
- market modifier.

Include hidden truth and public listing snapshot.

Write unit tests.

## Task 4 — Market feed

SwiftUI feed with:
- listing cards,
- category filter,
- sort newest,
- listing detail navigation.

Use original visual language.

## Task 5 — Listing detail

Show:
- photos/art placeholder,
- asking price,
- seller profile,
- public attributes,
- description,
- message/offer CTA.

## Task 6 — Negotiation

Implement:
- make numeric offer,
- seller accept/reject/counter,
- deterministic seller decision model,
- negotiation history.

For Phase A, responses may be immediate behind a debug config.

## Task 7 — Purchase + inventory

Upon successful offer:
- deduct cash,
- create owned item,
- preserve hidden defect truth,
- add to inventory.

## Task 8 — Inspection

Basic inspection reveals a subset of facts.

Professional inspection can initially resolve immediately behind debug configuration.

## Task 9 — Player resale listing

Player:
- selects owned item,
- enters asking price,
- creates listing.

Simulate buyer interest.

## Task 10 — Buyer offer

Generate NPC buyer offer based on:
- fair market value,
- asking price,
- buyer archetype,
- player reputation placeholder.

Allow:
- accept,
- reject,
- counter.

## Task 11 — Profit/loss

On completed sale:
- calculate acquisition cost,
- repair/inspection costs,
- sale amount,
- net profit/loss.

Store transaction history.

## Task 12 — Vertical-slice debug panel

DEBUG builds only:
- reset save,
- add cash,
- regenerate market,
- reveal hidden item truth,
- force seller response,
- force buyer offer.

This will dramatically accelerate balancing.

---

# 48. Phase B — Offline Event Backlog

Only after vertical slice is fun.

1. Implement `GameEvent`.
2. Implement persisted event queue.
3. Implement deterministic event resolver.
4. Replace immediate seller replies with scheduled replies.
5. Replace instant shipping with scheduled shipping.
6. Replace instant professional inspection with scheduled inspection.
7. Replace immediate buyer offers with scheduled buyer-interest ticks.
8. Implement foreground catch-up.
9. Implement while-away summary.
10. Integrate local notifications.
11. Cancel/reschedule notifications when event state changes.
12. Add debug time travel in DEBUG only.

---

# 49. Suggested Config

Centralize tuning:

```swift
struct GameBalanceConfig {
    var startingCash: Money
    var marketListingCount: Int
    var sellerReplyMinSeconds: TimeInterval
    var sellerReplyMaxSeconds: TimeInterval
    var shippingMinSeconds: TimeInterval
    var shippingMaxSeconds: TimeInterval
    var inspectionDuration: TimeInterval
    var buyerOfferBaseRate: Double
    var listingLifetime: TimeInterval
    var interstitialCooldown: TimeInterval
}
```

Use separate:
- debug config,
- production config.

Debug timers should be seconds.
Production timers should be minutes.

---

# 50. Test Requirements

## Unit tests

Must cover:
- money arithmetic,
- pricing,
- seller acceptance,
- hidden defect stability,
- event ordering,
- offline resolution,
- profit/loss,
- save/load roundtrip,
- market trend modifiers.

## Property/invariant tests where possible

Examples:
- sale cannot create negative item count,
- wallet cannot become NaN,
- event resolves at most once,
- same seed generates same item truth,
- completed listing cannot receive new offer,
- Remove Ads purchase state survives relaunch.

## UI tests

Critical flows:
- first trade,
- notification deep-link route,
- restore purchase,
- create listing.

---

# 51. Quality Bar

The app should feel like a game, not a spreadsheet.

Add:
- satisfying haptics on deal acceptance,
- subtle money count animation,
- message typing/arrival feel,
- inspection reveal animation,
- rare item reveal treatment,
- profit/loss summary,
- clean sound design.

Do not overanimate every tap.

---

# 52. Product Kill Criteria

Before investing heavily, evaluate the vertical slice.

Stop/rework if testers consistently say:
- “I’m just tapping the cheapest item.”
- “There’s no reason to ask questions.”
- “Every trade is guaranteed profit.”
- “Negotiation feels random.”
- “I don’t care when sellers reply.”
- “It feels exactly like Cebinden/Sahibinden.”
- “It feels like a spreadsheet.”
- “I have nothing interesting to decide.”

The core game succeeds when testers voluntarily:
- compare listings,
- hesitate before buying,
- remember seller behavior,
- care about inspection results,
- feel loss,
- feel excitement about rare deals,
- want to check pending offers.

---

# 53. Post-MVP Roadmap — Only If Metrics Support It

Possible V1.1:
- auctions,
- one new category,
- richer collections,
- recurring sellers,
- more client requests,
- deeper repair services,
- expand Game Center Challenges/Activities if V1 participation is healthy.

Possible V1.2:
- seasonal market events,
- daily/weekly seeded market challenges,
- cloud save.

Possible V2:
- Android port,
- optional backend,
- asynchronous leaderboards/challenges,
- cross-device sync.

Do not add real user-to-user trading until fraud/moderation/economy consequences are fully understood.

---

# 54. Naming Direction

Do not lock final name during engineering.

Desired brand characteristics:
- short,
- pronounceable in TR + EN,
- not descriptive enough to be generic,
- no resemblance to Sahibinden/Cebinden,
- works as app icon,
- evokes trade/deals/discovery without copying a marketplace.

Temporary internal bundle/product naming may use:
`ProjectFlip`

Final naming is a separate clearance task.

---

# 55. Official Policy / Research References

These references are for product/legal awareness. Re-check before release because platform policies change.

## Apple

## Apple Game Center / Apple Games

Game Center overview:
https://developer.apple.com/game-center/

Leaderboards and recurring leaderboards:
https://developer.apple.com/help/app-store-connect/configure-game-center/manage-leaderboards/

Leaderboard reference:
https://developer.apple.com/help/app-store-connect/reference/game-center/leaderboards/

Challenges:
https://developer.apple.com/help/app-store-connect/configure-game-center/manage-challenges

Activities:
https://developer.apple.com/help/app-store-connect/configure-game-center/manage-activities

Apple Games discoverability / engagement guidance:
https://developer.apple.com/videos/play/meet-with-apple/248/

App Review — Copycats / impersonation:
https://developer.apple.com/app-store/review/guidelines/

Apple App Review Help — Preventing copycat and impersonation rejections:
https://developer.apple.com/help/app-review/guideline-reference/4-1-prevent-copycat-rejection

Local notification scheduling:
https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app

## Google Play

Impersonation policy:
https://support.google.com/googleplay/android-developer/answer/9888374

Intellectual property policy:
https://support.google.com/googleplay/android-developer/answer/9888072

## Ads

AdMob iOS interstitial guidance:
https://developers.google.com/admob/ios/interstitial

AdMob iOS rewarded / rewarded interstitial docs:
https://developers.google.com/admob/ios/rewarded-interstitial

## Competitor references

Cebinden / Car Sales Simulator Pocket — App Store:
https://apps.apple.com/tr/app/car-sales-simulator-pocket/id6756355015

Cebinden — Google Play:
https://play.google.com/store/apps/details?id=com.cebinden.cebinden_app

Thrift Shop Empire — App Store:
https://apps.apple.com/tr/app/thrift-shop-empire/id6758114329

## Turkish marketplace/IP note

Do not scrape or reproduce third-party marketplace data/assets.
Before launch, separately review:
- current third-party marketplace terms,
- Turkish copyright/trademark/unfair competition rules,
- TÜRKPATENT name/mark availability.

---

# 56. Final Directive to Codex

Start with **Section 47 — First 72 Hours**.

Do not add features outside that list until the vertical slice builds and the core loop is playable.

At the end of each implementation milestone:

1. build the project,
2. run tests,
3. fix warnings/errors caused by your changes,
4. summarize files changed,
5. state the next highest-priority task from this document,
6. do not silently expand scope,
7. for Game Center work, keep identifiers/config centralized and verify the game still works when Game Center is unavailable.

Game Center is a multiplier, not the core product. Do not use it to hide a weak trading loop.

The first success condition is not “many features.”

The first success condition is:

> A player sees a suspiciously cheap listing, makes a judgment under uncertainty, negotiates, buys, discovers the actual condition, resells, and immediately wants to hunt the next deal.

Build that first.
