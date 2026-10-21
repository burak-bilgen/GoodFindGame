# Unscripted human playtest

Purpose: find out whether the existing trading loop survives repetition. This
session does not authorize any new V1 feature work. Automated scenarios establish
working behavior; the answers below must come from a person playing freely.

## Prepare

- Record the checkpoint commit, device/iOS, language, build configuration and
  session start/end time. Use a normal Release build for realistic pacing:
  DEBUG has accelerated timers, and UI tests explicitly use isolated/instant saves.
- Use a fresh save for a first-session evaluation. Keep a continuing save for
  return sessions. A fresh install on a dedicated test device is suitable; do not
  erase someone else's save. DEBUG Profile → Developer tools offers a confirmed
  reset when needed before the session.
- Do not use cash grants, forced replies, regeneration, virtual time or hidden
  truth during play. Leave sound and notification consent to the player.
- The facilitator observes without explaining prices, hidden condition or an
  optimal strategy. Record confusion and stalled moments before offering help.

## Play freely

Browse and choose your own listings. Aim for at least five completed trades across
sessions, then decide whether you actually want another. Ask questions, bargain, inspect, repair,
hold or sell as-is as you wish. A loss is a useful observation, not a failed test.
Do not require every scenario or teach a strategy in the first session.

After the accelerated introduction, normal Release pacing is 2–10 minutes for a
seller reply, five minutes for delivery, 15 minutes for an expert inspection and
3–7 minutes for buyer interest. Plan short return sessions as well as continuous
play. Record whether these waits help or hurt; do not use DEBUG timing to decide
whether production is too slow.

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
| Offline return and catch-up report | | |
| Actual notification return | | |

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

## Record only what is needed

No analytics SDK or logging service is needed. Use the existing cash/inventory
views and Profile → Trade history to record starting/ending cash, completed trade
count, wins/losses, inspection/repair charges and net results. Cash change alone
is not profit: unsold goods, incoming purchases and diagnostic-kit spending can
account for the difference.

| Trade / item | Buy | Inspect | Repair | Sell | Net | Decision / surprise |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

Existing DEBUG tools can reveal simulation truth after the interview. If using a
Release session, retain its save for later developer inspection rather than
changing builds or editing the save during play. Keep this material away from
the player until their unprompted answers are recorded. Do not grant money to
rescue a stalled session; record the cause and stop if necessary.

Report observations, help required, blockers and hypotheses separately. Decide
the next change from actual observations. Progression, Game Center, monetization,
collections, client requests and other new systems remain paused.
