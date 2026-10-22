# Trading challenge — observed follow-up

22 October 2026. The owner played and reported “Trading feels too predictable or
easy”, then identified several sources: bargaining, reliable resale profit and
maximizing buyer offers. This authorizes tuning those existing rules. It does not
authorize progression, monetization or retention systems.

## Reproduction before changes

TradingChallengeTests exercised actual negotiation engines with fixed inputs:

- 74/74 clean professional sellers accepted 80%-of-fair-value bids.
- 96/96 first raises from 90 to 99, with private budgets of 100, settled safely.
- 32/32 first counter probes above budget returned the exact private maximum.

The three regression tests failed on the committed baseline. The red result and
logs are retained under ../../Artifacts/TradingChallenge-2026-10-22/.

Ranked causes: (1) every seller used the same deeply discounted floor formula;
(2) any under-budget buyer raise auto-accepted; (3) first buyer counters exposed
all remaining budget and seller counters always bisected their floor-to-ask gap.
Price-sensitive traffic already has non-guaranteed outcomes, so no extra timers
or reduced buyer arrivals are needed to address this report.

## Targeted changes

New stock uses personality-specific floors drawn from an independent seeded
stream. Professional, stubborn and collector sellers protect more value; urgency,
mispricing and ignorance can still create bargains. Clueless and manipulative
sellers anchor their floor to their own asking price, preserving the existing
separation between seller beliefs and hidden item truth. The introductory price,
existing saved prices/floors, and subsequent item/asking-price RNG draws remain
unchanged.

Seller concessions retain a variable share of the remaining gap, influenced by
urgency, bargaining skill and existing counter history. The same saved negotiation
replays the same answer. A fixed halfway equation no longer reveals the floor.

Later buyer raises can lose the buyer even below their private maximum. Firmness,
the size of the raise and previous pushes affect that risk. A standing offer can
still be accepted reliably. Partial concessions leave some budget unrevealed;
withdrawal exposes no unused budget. The first introductory buyer retains its
approachable teaching behavior. There is no new timer or hidden-state UI.

A single deterministic response decision serves settlement and notification
forecasting. Saved offer identity and attempt count prevent reload rerolls.
Native plans must retain listing-expiry alerts when a pending counter will not
settle the sale. Dialogue must describe a concession, not claim it is a buyer's
exact maximum.

## Acceptance

Require deterministic replay, safe standing-offer acceptance, both lost buyers
and improved sales across fixed samples, continuing bargain/loss opportunities,
no changed saved truth, queue/notification agreement and current EN/TR playability.
The tests establish removal of these dominant strategies; they do not establish
ideal economic balance or fun. A follow-up human session is still required.

## Targeted evidence

The same challenge samples now report 0/74 professional acceptances at 80% value,
74 improved buyer sales and 22 withdrawals out of 96 raises, and no full-budget
revelation in the 32 concession probes. A 500-listing sample retains 69 listings
below 85% of true value and 189 above 115%, so this is not a blanket price increase.
Those are developer diagnostics using truth, never player-facing deal labels.

All 115 units passed in the targeted full-unit run, including safe standing-offer
acceptance, deterministic replay, exactly-once settlement, native expiry forecasts
and continuing bargains/loss risks. A temporary differential probe compared 4,000
generated listings with the preceding commit: item truth, asking prices, seller
profiles and claims all match; the complete introductory listing also matches.
The probe source/result is archived outside the checkout and removed from the
shipping test target after verification.

Final checkpoint: all 115 unit tests and all 53 distinct UI tests pass (168
cases), with zero failures, skips or recorded runtime warnings. Debug test builds
and Release simulator build pass; all 489 EN/TR keys validate. Both counter UI
journeys, five consecutive trades, actual notification return, loss/repair,
offline return and normal-timing parallel processes are covered. All application
and test inputs remained unchanged throughout the full run. The master brief is
byte-for-byte intact. Evidence: complete.xcresult, complete-summary.json,
source-proof.json, release.log and gallery.html under the artifact directory.

The counters now describe a revised offer in both languages rather than claiming
it is an exact maximum. Targeted correctness is established; ideal difficulty
and enjoyment need another unscripted human session.
