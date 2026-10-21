# Offline simulation foundation

The queue is authoritative game state. Events carry immutable typed outcomes, creation/deadline timestamps, a stable save-scoped sequence identifier and a persisted seed. Seller and buyer results are computed before their arrival so future notification content can describe an actual scheduled outcome. Revisions must cancel obsolete events before replacing them.

The resolver processes due events by deadline then sequence. A response may schedule an expiry and the same catch-up pass resolves that child if it is also due. Completed/cancelled events never resolve again. Inventory delivery and inspection completion do not charge a second time. Unowned inspection targets and settled listing work are cancelled. Keep all pending events and at most 200 settled queue records; monotonically increasing sequences prevent reuse even after history pruning. New/reset saves have distinct simulation IDs.

Clock anchors have separate meanings: `lastKnownWallClock` is the last observed device timestamp; `lastSimulationAt` is the nondecreasing normalized simulation timestamp. Positive observed elapsed time advances the simulation anchor. A backward correction contributes zero elapsed once and records the new raw anchor, allowing subsequent seconds to progress normally. Dates are absolute instants, so timezone/DST presentation changes do not alter durations. UI countdowns and notification trigger intervals must use `deadline - effectiveSimulationNow`, projected onto the current device time, rather than blindly comparing normalized deadlines to a corrected raw clock.

All fixed pending deliveries/reports are processed even after long absences. Generated buyer arrivals are capped per catch-up; after the cap the next real interest event is scheduled after the effective return time. Elapsed time alone never mints cash. A queued buyer reply may settle a previously authorized player counteroffer exactly once. Implausibly priced listings receive interest retries without fabricated buyer offers/notifications.

Integration status: live gameplay commands now schedule seller replies/questions, shipping, paid expert inspections and buyer arrivals. Store transactions resolve due work before a decision and again afterward (the instant test configuration exercises the same queue path). Active polling only writes when work is due or clock correction is needed; scene transitions record catch-up anchors. The grouped return report is persisted until acknowledged and routes into relevant items/conversations/listings. Capacity includes paid inbound shipments. A failed user action still preserves completed catch-up work. Event-backed local notifications and exact-object routes are implemented (see NOTIFICATIONS.md). DEBUG virtual-time controls now advance 30 minutes or one day and use the same catch-up/report pipeline. The device clock is unchanged; clock anchors recover naturally afterward.

Notification API reference checked before integration: [Apple local notification scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app), [authorization API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)).


## Living-marketplace integration

Normal Debug and Release use production pacing. Valid isolated test saves can
explicitly select accelerated or instant timing; both still use this queue.
The first trade is compressed. Subsequent standard delivery has a small saved
3–7 minute spread, and seller urgency varies the reply delay.

Player resale attention uses saved, silent listingAttention events before the
possible buyerOffer/buyerInterest outcome. UI counts change only when those events
resolve. Buyer counter replies use buyerReply, with a saved offer identity and
attempt guard. Original offer expiry is cancelled when a reply is booked; a
reply cannot be promised beyond the listing's remaining window. The immutable
buyer budget determines the outcome without repricing a held offer. Only a
previously authorized accepted counter can settle while the player is away.

Player listing expiry and withdrawal cancel stale work without cash or item
grants. New listings have a 45-minute window; a legacy untimed listing receives
one full window without changing existing item truth, counters or held commitments.
Price revision cancels obsolete queued outcomes and reschedules against the same
expiry. Long-absence generation remains capped and fixed delivery/report work is
still processed. See LIVING_MARKETPLACE.md for the current verification record.
