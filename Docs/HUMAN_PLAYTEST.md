# Unscripted human playtest

Purpose: find out whether the existing trading loop survives repetition. This
session records the current release candidate. Automated scenarios establish
working behavior; the answers below must come from a person playing freely.

## Prepare

- Record the checkpoint commit, device/iOS, language, build configuration and
  session start/end time. Normal Debug and Release builds now share production
  pacing; neither exposes developer tools in the player interface. Isolated UI
  tests explicitly opt into accelerated/instant timing and are not pacing evidence.
- Use a fresh save for a first-session evaluation. Keep a continuing save for
  return sessions. A fresh install on a dedicated test device is suitable; do not
  erase someone else's save. There is no player-facing reset/developer screen;
  prepare a separate test installation rather than modifying a continuing career.
- Do not use cash grants, forced replies, regeneration, virtual time or hidden
  truth during play. Leave sound and notification consent to the player.
- The facilitator observes without explaining prices, hidden condition or an
  optimal strategy. Record confusion and stalled moments before offering help.

## Current observation to retest

The latest quality pass addresses systematically weak ordinary resale exits,
unclear pre-purchase risk and the post-introduction pacing cliff. See
[the measured audit](QUALITY_PASS_2026_10_23.md). New ordinary seller margins and
buyer audiences are tuned; existing agreements, hidden truth and saved deadlines
are preserved. Use a fresh dedicated test career or naturally arriving stock to
judge the new rules without resetting the player's own save.

Record whether the player understands the uncertain resale/margin range before
buying, notices disclosed faults, compares repair cost with possible recovered
value, and can explain a win or loss. Observe whether the next career milestone
and fresh listings create a voluntary reason for one more trade. Do not reveal
private budgets or require a particular win/loss rate during play.

## Play freely

Browse and choose your own listings. Aim for at least five completed trades across
sessions, then decide whether you actually want another. Ask questions, bargain, inspect, repair,
hold or sell as-is as you wish. A loss is a useful observation, not a failed test.
Do not require every scenario or teach a strategy in the first session.

After the brief introduction, new seller replies sample 3–7 seconds before
urgency scaling. New delivery takes roughly 36–84 seconds and is included in the
agreed price; expert reports take 90 seconds. Existing booked deadlines remain
unchanged. Repairs remain immediate quoted decisions. Buyer observations sample
15–45 seconds before liquidity/category scaling; interest and a sale are never
guaranteed. A sale listing has a 45-minute window, and revising its price does not
reset that window. Offers retain their 18-minute response window.

While work is pending, follow a ready handoff or browse elsewhere. The market
admits fresh stock every 90 seconds while there is room below its 16-listing
shelf, without deleting live/watched listings to make space. Record whether the
player finds useful choices during waits. Accelerated test saves are not pacing
evidence. Start with a 20-minute free session and allow short return sessions.

At a natural seller reply, delivery, expert inspection or buyer wait, leave the app
and return later. If you consented to notifications, try returning through one
actual notification. Also reopen the app directly after an offline interval.
Keep the device clock unchanged. Notifications can be reviewed by category under
Profile; denial should not prevent normal play.

After the free session, note which existing situations occurred. Unseen situations
can be explored in later sessions without changing the economy or forcing outcomes:

| Situation | Seen? | What did the player expect, choose and feel? |
| --- | --- | --- |
| Good, mediocre and bad purchases | | |
| A realized loss | | |
| A repair that helped | | |
| A repair that was a poor investment | | |
| Seller rejection or walk-away | | |
| Buyer lowball, counter or withdrawal | | |
| Repeated browsing and multiple completed trades | | |
| Several pending trade processes at once | | |
| Traffic/favorites without an offer; expiry, repricing or withdrawal | | |
| Seller claims versus earned inspection evidence | | |
| Offline return and catch-up report | | |
| Actual notification return | | |
| Client model search versus unverified seller condition | | |
| Client budget versus purchase/report/repair costs and normal resale | | |
| Finishing a client story and choosing a cosmetic title | | |

## Ask before revealing simulation state

For each question, record the player's own words and a concrete example. “Not
observed” is a valid answer; do not replace it with an automated-test conclusion.

1. After one trade, did you want another? After several trades?
2. Were listings interesting to scan?
3. Could you explain why an item might be a good or bad deal?
4. Did negotiation feel meaningful?
5. Did buying feel risky?
6. Did inspection create suspense?
7. Did repair create a real decision?
8. Did selling create anticipation?
9. Did profit feel rewarding?
10. Did loss feel fair? Could you explain why you lost?
11. Did you find an obvious dominant strategy?
12. Was the game too easy, too slow or too generous? Give examples separately.
13. Was there too much information? Where?
14. Were notifications useful or annoying?
15. Did returning after being offline feel exciting?
16. Did the game still feel like a game after several trades?
17. Could you keep making useful decisions while another trade was pending?
18. Did views, favorites and buyer interest feel believable and responsive to price?
19. Did the uncertain price range help your judgment without solving the decision?
20. Could you distinguish the illustrative product photo from actual condition findings?

## Record only what is needed

No analytics SDK or logging service is needed. Use the existing cash/inventory
views and Sales → Trade history to record starting/ending cash, completed trade
count, wins/losses, inspection/repair charges and net results. Cash change alone
is not profit: unsold goods, incoming purchases and diagnostic-kit spending can
account for the difference.

| Trade / item | Buy | Inspect | Repair | Sell | Net | Decision / surprise |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

Retain the session save for developer inspection after the interview rather than
changing builds or editing the save during play. Normal player builds expose no
truth/debug tools. Keep this material away from
the player until their unprompted answers are recorded. Do not grant money to
rescue a stalled session; record the cause and stop if necessary.

Report observations, help required, blockers and hypotheses separately. Decide
the next change from actual observations. Online Game Center and monetization are outside this release candidate. The six shipping languages, career, eighteen client requests, cosmetic titles and local Weekly Flip are available to observe as they unlock.
