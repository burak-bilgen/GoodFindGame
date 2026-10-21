# Living marketplace — scoped game-feel follow-up

The owner's additional playable-experience direction authorizes condition-aware
art, believable asynchronous pacing, price-sensitive attention, uncertain value
presentation and parallel trade management. Broader progression, rare variants,
collections, client requests, Game Center, monetization and analytics remain paused.
The clean checkpoint e38f821 remains the reference before this scoped extension.

## Existing-system audit

The saved event queue already handles delayed seller replies, reserved goods in
transit, expert inspections, buyer arrivals/expiry, offline catch-up and genuine
notifications. Purchase removes the new item from usable inventory until delivery.
The first trade is compressed; production later uses minutes. At the preceding clean checkpoint, normal DEBUG builds
used seconds, which made human play feel instant. Resale counters also
start at a price-derived nonzero count, buyer proposals use one fixed discount,
and price estimates are precise amounts. These are the focused behavior gaps.

Artwork is original Canvas geometry, but repeats generic silhouettes without
instance condition. Extend the existing art and saved queue rather than replace
them. No logistics service, photography simulation or rarity system is introduced.

## Checkpoint 1: evidence-aware product illustration

Added material edges, side depth, consistent shallow perspective, lens/glass
layers and a handheld silhouette. Deterministic per-instance surface wear layers
cover excellent/good/fair/poor presentation without duplicating bitmap assets.
Listing art consumes seller claims only and is explicitly labeled unverified.
Uninspected owned goods reveal no hidden condition. Inspected pictures can show
only already-discovered visible faults; repaired faults disappear. Battery wear,
internal faults and unearned lens findings cannot leak into pictures. Condition
and finding overlays remain separate so future seller photo framing need not
receive hidden truth. The inspection reveal shows one evidence image rather than
repeating a large header image above it.

Validation: 94 unit tests and both connected English/Turkish trades pass. Both UI
journeys pass again after the final duplicate-image cleanup, with no recorded
runtime warnings. Debug/Release builds pass; 453 translation keys validate.
Initial and final screen captures/results are outside Git under
../../Artifacts/LivingMarketplace-2026-10-21/art*.

These are illustrated fictional products, not photorealistic photographs. The
scalable material/evidence layer is implemented; seller-dependent photo quality
and interactive rotation remain future presentation possibilities, not new systems.


## Checkpoint 2: asynchronous marketplace rhythm

Normal Debug and Release now share production pacing. Accelerated seconds and
instant timing require a valid isolated UI-test save; the normal player cannot
accidentally enter instant mode by passing that flag alone. The first trade stays
compressed. Existing reserved shipments remain inaccessible until delivery.
Standard delivery is explicit, included in the agreed price, and later takes
roughly 3–7 minutes. No pickup chooser, extra shipping fee or logistics subsystem
was added. Paid expert inspection remains asynchronous; repair remains an
explicit immediate service decision.

New resale listings start at zero views, zero favorites and no offers. Two saved
attention observations precede each possible buyer arrival. The existing queue
samples traffic, favorites, offer probability and delay using price, actual item
condition/value, current demand, category audience and existing reputation.
Reasonable prices can still fail to attract an offer; favorites can go nowhere.
Absurd prices can receive no offers. No hidden liquidity score or future traffic
is exposed. Views/favorites shown in the UI are persisted simulation results.

Listings have a 45-minute window, visible under activity rather than a wall of
primary timers. Offers never promise a window beyond the listing's end. Repricing
cancels stale pending outcomes, retains historical attention and the original end
time. Expiry and withdrawal retain the item without granting cash; the player
can review and relist. Untimed legacy listings get one full window at migration,
respecting already-booked commitments and preserving their counters and truth.
The existing bounded catch-up remains responsible for offline processing.

Seller urgency affects response timing. New asking prices have wider archetype
bands, while consuming the same pricing RNG draw and preserving the introductory
price and saved item truth. Existing saves keep their recorded asking prices.
Buyers have varied openings, budgets and concise archetype-specific dialogue;
collectors can value high condition more, and resellers protect margin. The first
introductory buyer remains approachable. No rarity or reputation expansion was
introduced.

Buyer counters book a real reply instead of settling on submission. Pending UI
labels the old amount as the previous offer, disables conflicting decisions,
closes the editor and keeps a hunt action available. Replies focus the actual
counter or payoff. Late counters that cannot receive a reply before closure are
explained without falsely claiming the still-acceptable offer is already closed.
Settlement remains exactly once. A previously committed accepting reply suppresses
a contradictory future expiry notification.

Current pricing screens show rounded uncertain ranges, narrowed by existing
category knowledge and professional inspection while keeping a nonzero spread.
These use known evidence, never hidden faults. Model reference ranges are also
uncertain. Asking-price suggestions sample the range instead of promising a fast
sale or optimal amount. The input's conditional result uses the actual entered
ask minus recorded acquisition/service costs; it is not realized profit. Public
demand and category audience add context without exposing the model's score.

The market's compact horizontal status strip routes to genuine pending seller
replies, shipments, expert reports and live sales. Shipping, negotiation and
buyer-wait screens let the player return to browsing without cancelling work.
Uninspected inventory keeps the seller picture until earned inspection replaces
it with observed condition; message previews retain the seller's presentation.

Native plans cover genuine buyer replies, own-listing expiry and watched-listing
sales/expiry using existing typed routes and preferences. Earlier competing
closures suppress obsolete alerts. Firm-quote-held watched closures are not
prematurely advertised; the next reconciliation can schedule their actual
rescheduled event. Attention alone creates no alert and no invented urgency.

## Verification and limits

Final validation completed overnight on 22 October 2026:

- Debug test build and Release simulator build pass.
- All 107 unit tests and all 53 distinct UI tests pass: 160 cases, zero failures,
  zero skips and zero recorded runtime warnings in `complete.xcresult`.
- The 52 existing/extended UI journeys ran in two shards. An additional normal-
  production-timing journey passed with a seller reply, shipment, expert report
  and live resale listing pending while the player browsed another opportunity.
  It used real UI purchases, without cash grants, forced outcomes or clock advances.
- English and Turkish journeys include connected trades, asynchronous responses,
  listing expiry/relist/withdrawal, offline return, notification routes and losses.
  All 489 localization keys validate in both languages.
- The final compiler cleanup only renames an unused binding to `_`, preserving
  the same lookup/guard. All 107 units and both builds were rechecked afterward;
  the full UI run predates only that behavior-neutral cleanup. The sole earlier
  source addition was the passing production-paced UI journey. Source hashes and
  equivalence checks accompany the evidence.
- No Swift compiler warnings remain. Xcode's benign App Intents metadata warning
  remains because the app does not use App Intents.
- The main Docs brief retains its original SHA-256:
  `3c25a9763af35e494c9c6d340f4784ef59759f85133bcb46dd351d7487aeb582`.

Local results, 185 unmodified captures, `gallery.html`, source hashes and clearly
separate diagnosis evidence live outside the checkout in
../../Artifacts/LivingMarketplace-2026-10-21/. The existing clean checkpoint's
SwiftUI invalid-frame fix remains healthy: none is recorded in the final runs.

This is a scoped game-feel implementation, not a claim of human enjoyment,
commercial retention or measured economic balance. No unscripted human session,
physical-device/iOS 17 runtime, physical audio/haptics or broad VoiceOver QA is
claimed. Fictional art remains illustrated; seller-dependent photography,
interactive rotation, pickup options and timed repairs were not built. Those
possibilities do not authorize another milestone. The human playtest guide is
updated for the actual new pacing and parallel-trade questions.
