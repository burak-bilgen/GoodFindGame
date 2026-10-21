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
The first trade is compressed; production later uses minutes. Normal DEBUG builds
currently use seconds, which makes human play feel instant. Resale counters also
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
