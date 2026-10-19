# Market demand and valuation

The first completed player resale unlocks a saved version-one market calendar. The first demand movement starts 12 simulation hours later. One movement starts per simulation day, lasts 14–18 hours, and changes either one category or one fictional model by 5–12% in either direction. Intervals between movements return to baseline; changes do not compound. These are initial balance defaults, still subject to playtesting.

The calendar saves its seed, anchor, version and scope pools. Its pure deterministic forecast can price an offer at its actual future arrival time, including across a trend boundary. Time zones do not change the schedule. Simulation time normalization handles clock rollback. A future content expansion cannot reroll an existing scope pool.

A market-cycle event records the actual trend and schedules its end and the next cycle. After a long absence, preparation cancels stale cycle ticks and schedules only the latest elapsed cycle. Fixed work still resolves chronologically. Historical buyer offers can query the calendar at their own timestamps; they do not accidentally use today's trend. Fourteen processed trends are retained. No currency, inventory or realized profit is granted by a demand movement.

Current demand affects buyer willingness, initial resale attention, estimates based on revealed defects, excellent-condition reference values, and newly generated NPC listing prices. Existing seller asking prices and already-issued buyer offers remain firm. A trend does not reveal hidden defects or guarantee a sale.

Market → trends shows active demand and processed history, scope, signed percentage, reason, start/end and remaining time. Return reports link to the real trend. Market-category local notification plans derive from the actual pending cycle and route to that trend after catch-up. Disabling the category removes those requests through the existing notification synchronizer. This milestone tests the planner and routes; real native notification delivery was previously verified for the shared mechanism, not separately by waiting 12 hours for a market movement.

Competition, listing lifetimes, seller price drops and automatic feed replenishment remain the next market-depth work. The game presentation/polish phase also remains open; these functional screens are not final game art or UI.
