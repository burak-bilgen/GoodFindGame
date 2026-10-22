# Fairer repeated trading

22 October 2026. Human feedback changed from predictable/easy to random/frustrating.
This correction targets that observed overcorrection, without adding systems.

## Reproductions and decisions

The fixed 96-buyer sample withdrew 16 buyers on a first 1% counter despite room
in their private budgets. Remove the first-counter walk coin flip. Buyer
personality now bounds a modest concession; some accept, others improve a little
or explicitly hold their price. Partial replies do not disclose the full private
budget. An extreme demand relative to both the asking price and standing offer
can still end talks. After a counter/hold, the buyer explicitly gives a final
offer; another raise ends the conversation. Taking the standing price remains
safe, including in older saved conversations. The introductory trade keeps its
approachable first reply.

The first seller minimum could increase when patience dropped, so an improving
player bid missed a previously sufficient price. A sampled regression reproduced
this. Fatigue now affects conversation closure, not the monetary floor. New stock
and existing saved reservation prices are unchanged; professional inventory still
does not universally accept 80% of clean value.

A 0.1% price change across the 110%-of-value threshold raised attention delay
from 0.9 to 1.44 and cut offer probability from 65 to 35. Piecewise interpolation
now makes price sensitivity gradual. The same sample changes delay from 0.9000
to 0.9018 and keeps rounded chance at 65. Higher prices still attract less
attention, cheap stock still moves faster, views/favorites remain simulated, and
interest can still produce no offer. No optimal price or private budget is shown.

Production reply sampling changes from 120–600s to 30–90s, with existing seller
urgency scaling retained. Buyer attention sampling changes from 180–420s to
60–180s before existing price/category/reputation scaling. These are sampling
intervals, not promised time-to-sale. Shipments, expert inspection, offer windows
and first-trade compression retain their existing durations. Existing queued
events are not rescheduled; new work uses the adjusted timing.

## Verification

- Red runs: red.xcresult and seller-red.xcresult reproduce the four regressions.
- Final Debug test run: all 121 unit tests and five relevant UI journeys pass,
  zero failures/skips/runtime warnings. UI covers EN/TR buyer counters, five
  consecutive trades, concurrent production-timing trades and native notification
  delivery/tap routing. Release simulator build passes.
- Counter forecasts, saved replay, offline settlement, held-price acceptance,
  final-offer withdrawal, expired-listing notifications and exactly-once cash
  settlement share the actual decision path and pass.
- 540 English/Turkish keys validate. The main brief remains byte-for-byte intact.
- Evidence: ../../Artifacts/FairTrading-2026-10-22/final.xcresult and release.log.

This is an implemented correction with automated evidence, not human acceptance
of fairness or pace. Unscripted repeat-trade testing is still required. The next
authorized work is the queued game-style interface and animation pass; progression,
Game Center, monetization, collections and analytics remain paused.
