# Unscripted human playtest

Purpose: find out whether the existing trading loop survives repetition. This
session does not authorize any new V1 feature work. Automated scenarios establish
working behavior; the answers below must come from a person playing freely.

## Prepare

- Record the checkpoint commit, device/iOS, language, build configuration and
  session start/end time. Normal Debug and Release builds now share production
  pacing; Release keeps developer tools out of the player interface. Isolated UI
  tests explicitly opt into accelerated/instant timing and are not pacing evidence.
- Use a fresh save for a first-session evaluation. Keep a continuing save for
  return sessions. A fresh install on a dedicated test device is suitable; do not
  erase someone else's save. DEBUG Profile → Developer tools offers a confirmed
  reset when needed before the session.
- Do not use cash grants, forced replies, regeneration, virtual time or hidden
  truth during play. Leave sound and notification consent to the player.
- The facilitator observes without explaining prices, hidden condition or an
  optimal strategy. Record confusion and stalled moments before offering help.

## Current observation to retest

The owner reported that several parts of trading felt too predictable/easy.
The targeted response is recorded in TRADING_CHALLENGE.md: stronger personality-
dependent floors for newly generated stock, variable seller concessions and
buyer raises that can lose the buyer instead of revealing a free exact maximum.
A standing offer remains safe to accept. Previously saved prices and seller
floors are preserved; use a fresh evaluation save or naturally arriving stock to
judge the new floors. Never reset or regenerate stock during the observed session.

Record whether bargaining now rewards judgment, whether ordinary purchases can
lose money, whether asking for more is a real choice, and whether lost buyers
feel understandable rather than arbitrary. Do not require a particular win/loss
rate or reveal private budgets during play.

## Play freely

Browse and choose your own listings. Aim for at least five completed trades across
sessions, then decide whether you actually want another. Ask questions, bargain, inspect, repair,
hold or sell as-is as you wish. A loss is a useful observation, not a failed test.
Do not require every scenario or teach a strategy in the first session.

After the accelerated introduction, seller replies vary with urgency and take
minutes. Standard delivery takes roughly 3–7 minutes and is included in the agreed
price; expert inspection takes 15 minutes. Attention develops over time, with
price and audience affecting pace and no guaranteed buyer. Buyer counter replies
are also delayed. A sale listing has a 45-minute window and can end without a
sale; revising the price does not reset that window. Plan short return sessions
as well as continuous play. Record whether these waits help or hurt; do not use
accelerated test launches to decide whether normal play is too slow.

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
| Seller picture versus earned inspection evidence | | |
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
17. Could you keep making useful decisions while another trade was pending?
18. Did views, favorites and buyer interest feel believable and responsive to price?
19. Did the uncertain price range help your judgment without solving the decision?
20. Did the listing picture and inspection picture communicate condition clearly?

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
