# Market demand and valuation

The first completed player resale unlocks a saved version-one market calendar. The first demand movement starts 12 simulation hours later. One movement starts per simulation day, lasts 14–18 hours, and changes either one category or one fictional model by 5–12% in either direction. Intervals between movements return to baseline; changes do not compound. These are initial balance defaults, still subject to playtesting.

The calendar saves its seed, anchor, version and dated scope epochs. Its pure deterministic forecast can price an offer at its actual future arrival time, including across a trend boundary. Time zones do not change the schedule. Simulation time normalization handles clock rollback. Content expansion adds enlarged scope pools after the current and next already-known cycle, preserving historical/active/queued movements while allowing later cycles to include new categories.

A market-cycle event records the actual trend and schedules its end and the next cycle. After a long absence, preparation cancels stale cycle ticks and schedules only the latest elapsed cycle. Fixed work still resolves chronologically. Historical buyer offers can query the calendar at their own timestamps; they do not accidentally use today's trend. Fourteen processed trends are retained. No currency, inventory or realized profit is granted by a demand movement.

Current demand affects buyer willingness, timed resale attention, estimates based on revealed defects, excellent-condition reference values, and newly generated NPC listing prices. Existing seller asking prices and already-issued buyer offers remain firm. A trend does not reveal hidden defects or guarantee a sale.

Market → trends shows active demand and processed history, scope, signed percentage, reason, start/end and remaining time. Return reports link to the real trend. Market-category local notification plans derive from the actual pending cycle and route to that trend after catch-up. Disabling the category removes those requests through the existing notification synchronizer. This milestone tests the planner and routes; real native notification delivery was previously verified for the shared mechanism, not separately by waiting 12 hours for a market movement.

## Listing lifecycle and competition

The first completed sale also unlocks the live feed. Production refreshes every 30 minutes and assigns existing/new listings 2–6 hours of remaining lifetime. Normal Debug builds use those same production timings. Isolated accelerated tests refresh every 90 seconds with 5–9 minute remaining lifetimes. The isolated instant UI-test mode keeps stock fixed; the live-feed UI tests use actual DEBUG timers. The onboarding stock remains stable until the first sale.

Every listing's competitor decision, NPC identity, potential purchase time, price-drop amount/time and expiry are booked once from a save/listing seed. Bargain-looking public prices attract more competition. Competitors use claimed condition without hidden defects, so they can misjudge deceptive stock. No fabricated viewer counts are shown. Competitor purchases and expiry close the listing and conversation without changing player money or inventory.

A valid counter/agreed price is honored through its expiry. NPC purchase/retirement events defer until one second afterward. Price drops that conflict with a firm quote are cancelled, rather than changing its amount. Legacy quotes with no timer receive one full persisted offer window before retirement is allowed. Replies invalidated by an earlier known purchase/expiry are excluded from notification plans, including equal-timestamp sequence ordering. Watched price-drop alerts are likewise suppressed if a prior known closure or firm quote prevents the change. Closing events are visible in return reports and archived watched listings; no closing push alerts are scheduled.

Refresh runs once at the end of catch-up, after fixed due work, and refills toward ten active listings. A long absence generates one current batch rather than hundreds of missed batches. Model pools rotate, new prices use current demand, and replenished stock does not get the guaranteed clean discounted starter treatment. Currency and acquired hidden truth remain stable.

System-created archives keep the latest forty closed listings plus all watched, contacted and acquired/financially referenced listings. Corresponding lifecycle records follow that retention. Pending work is retained and settled event history remains capped at 200. User trade/conversation/watch history is intentionally preserved. Unavailable watched cards/details show actual closure reasons; completed NPC buyers use localized name pools. An empty active feed with a pending refresh shows its real countdown.

Days 8–11 market systems are implemented; human economic/fun balancing and broader release QA remain open. The game presentation/polish phase also remains required; these functional screens are not final game art or UI.


Player-owned resale listings now have their own timed attention and a 45-minute
sale window within the same queue. This is separate from the existing NPC-stock
lifetime. The displayed traffic is persisted simulated attention, and ordinary
price bands have probabilistic arrivals rather than a guaranteed immediate buyer.
Expired or withdrawn goods remain owned and can be relisted. See
LIVING_MARKETPLACE.md for pricing, liquidity, reply and migration details.


## Living-marketplace event sources

Buyer counter replies and own-listing expiry use the existing sale route and
preferences. A committed reply that will accept a player counter suppresses a
contradictory later expiry alert. Price changes, withdrawal and settlement cancel
stale requests through normal committed-state synchronization.

Watched competitor purchases and listing expirations now have localized market
alerts and exact listing routes. Earlier closure outcomes suppress later,
contradictory alerts. Firm quotes that defer a closure suppress its premature
forecast; reconciliation can later schedule the real rescheduled event. Silent
attention ticks never produce invented offers or urgency. Planner ordering,
withdrawal, accepting-counter and held-quote cases have domain coverage; the
shared native scheduling/tap pipeline remains covered by the actual UI test.
