# Game Center V1 setup — Project Flip

The approved shipped display name remains **Project Flip**. Findrove is a working recommendation only. Production bundle ID is unchanged: `gameproject.bilgenworks.ProjectFlip`. Identifiers below are brand-neutral and centralized in `CompetitionIDs`.

## Apple configuration (manual, requires the app owner's account)

1. Enable Game Center for the existing explicit App ID in Certificates, Identifiers & Profiles and for the app in App Store Connect. Regenerate signing profiles. The project includes `ProjectFlip/ProjectFlip.entitlements` with `com.apple.developer.game-center = true`; choose your signing team locally, never commit it.
2. Create recurring leaderboard **Weekly Trader**, ID `trading.weekly.v1`. Use integer scores, descending/best score, range **0–1,000,000**, no currency. Start anchor **2024-01-01 00:00:00 UTC (Monday)**, duration **7 days (604800 seconds)**, restart interval **7 days**, no gaps. If the console requires a future start, use a Monday at 00:00 UTC; the code validates the loaded occurrence against its UTC week before submitting. Configure score suffixes naturally in each locale (EN: points, TR: puan).
3. EN leaderboard display: **Weekly Trader**. TR: **Haftanın Tüccarı**. EN challenge: **Weekly Flip**. TR: **Haftanın Al-Satı**. Prepare leaderboard artwork, then submit Game Center resources with the app version as required by App Store Connect.
4. Create the 12 non-repeatable achievements listed below. Assign **10 points each**, total **120**. Show all initially, no hidden spoiler metadata. Supply Game Center achievement artwork. Use the supplied descriptions for both locked and earned states where the console requires separate fields; rephrase the earned form naturally if desired without changing its threshold.
5. Link the leaderboard and achievements to the app/version and complete any resource review requirements. There is no custom account service, Sign in with Apple integration, backend, ad SDK or economic rank prize.

## Runtime behavior and fairness

Authentication only starts when the user taps **Connect to Game Center**. No prompt on first launch, no prompt retry loop. After cancellation/failure, show a Settings sign-in hint. The system-supplied authentication controller and Game Center dashboard are presented through SwiftUI and dismissed via their supported delegate/callbacks. Dashboard buttons expose friends, global leaderboard and achievements; the in-game overview comes first.

Weekly Flip is offered after three completed market/client career sales. The challenge has its own bankroll (100,000 canonical cents, $1,000 value), inventory, expertise, receipts and timers. Starting content uses a common weekly seed and the same trading engines as career. Currency is presentation only. No wealth is transferred either way. Career clients, collection banking, consignment/recovery grants and developer cash controls are excluded from the challenge surface and rejected at its save boundary.

Period IDs are anchored UTC weeks, not seven days since joining. Completed sales must fall inside their week. Rollover freezes and archives the old durable result without resolving work after the deadline; the next entered week starts fresh. A manually finalized week cannot be reopened for more trading. **Only finalized results with at least one settled trade submit.** Retrying the same score is safe; acknowledgements are written after success and tied to the account that owns the run. Switching accounts cannot claim another account's weekly result.

Game Center cannot accept arbitrary backdated scores into expired occurrences. Results finalized/reconnected after the week closes remain local and are never submitted to the new week. The UI explains this deadline. Load the current `GKLeaderboard`, check its `startDate` and `duration`, then use the instance `submitScore` API. A configuration mismatch fails closed and preserves all local progress.

TraderScore v1 uses integer arithmetic: max(0, net realized profit) × 10000 / starting bankroll (cap 800000), plus aggregate portfolio return × 10000 with denominator at least the initial bankroll (cap 150000), plus 2500 per distinct inspected, meaningfully profitable model (cost ≥1000 cents and profit ≥100 cents; at most 20 models). If aggregate profit is nonpositive the score is zero. Final cap 1000000. Unsold stock, app time, repeated models and main-career wealth add no score. The score version is the Game Center context. Future formula changes require a new leaderboard/version, not silent comparison with v1.

Local validation rejects invalid or excessive amounts, duplicate settlements, out-of-period receipts, non-market grants, and cash that does not reconcile with starting capital, acquisitions, inspection, repairs, tools and receipts. Detected device-clock rollback pauses submission for that run. DEBUG logs include formula version, period and score, never account identity. This is still **client-authoritative offline competition**, not trusted anti-cheat. V1 grants only a local Challenge Finisher badge for finalizing at least one trade and the matching achievement. Top 10/100 claims are deferred: a live rank is not verified final placement. No money, items, discounts or multipliers are awarded.

## Persistence and sync

`<career-save-name>-competition/competition.json` holds the achievement journal and weekly summaries. `<weekly-v1-index>.json` in that folder contains the isolated trading snapshot. Main `save.json` is not modified by challenge trades. Writes are atomic and publish only after disk success; an unreadable competition file is never overwritten with a fresh one. The main career keeps running if the optional companion fails to load.

Achievement percentages are derived from persisted career facts and merge monotonically. Earned local progress survives relaunch. The queue retries on connection, foreground return, network restoration and explicit sync. Remote percentages merge without reducing local progress. Per-account acknowledgements are written only after GameKit success; replay is idempotent. A shared device's local career journal follows that career; each connected account may sync that journal. Competition score ownership is stricter and bound to one account per week.

## Achievements and bilingual metadata

| Identifier | English title / description | Turkish title / description |
| --- | --- | --- |
| `trading.achievement.firstFlip.v1` | **First Flip** — Complete your first profitable trade. | **İlk Kârlı Satış** — İlk kârlı al-satını tamamla. |
| `trading.achievement.naturalTrader.v1` | **Natural Trader** — Earn at least 100% return on a trade costing $10 or more. | **Doğuştan Tüccar** — En az 10 $ maliyetli bir al-satta %100 veya daha fazla getiri kazan. |
| `trading.achievement.thatHurt.v1` | **That Hurt** — Lose at least $10 on a trade costing $50 or more. | **Bu Biraz Acıttı** — En az 50 $ maliyetli bir al-satta en az 10 $ zarar et. |
| `trading.achievement.detective.v1` | **Detective** — Discover a hidden defect in five different listings before buying. | **Dedektif** — Beş farklı ilanda satın almadan önce gizli bir kusur öğren. |
| `trading.achievement.negotiator.v1` | **Negotiator** — Buy an item for at least 20% below the seller’s asking price. | **Pazarlık Ustası** — Bir ürünü satıcının ilan fiyatından en az %20 ucuza al. |
| `trading.achievement.collector.v1` | **Collector** — Complete your first collection. | **Koleksiyoncu** — İlk koleksiyonunu tamamla. |
| `trading.achievement.trustedTrader.v1` | **Trusted Trader** — Complete ten inspected trades in your career. | **Güvenilir Tüccar** — Kariyerinde incelemesini yaptığın on ürünü sat. |
| `trading.achievement.specialist.v1` | **Specialist** — Reach expertise level 3 in one category. | **İşin Uzmanı** — Bir kategoride 3. uzmanlık seviyesine ulaş. |
| `trading.achievement.bigLeague.v1` | **Big League** — Reach the highest career stage. | **Büyük Lig** — En yüksek kariyer aşamasına ulaş. |
| `trading.achievement.comeback.v1` | **Comeback** — Use recovery commissions and rebuild your cash to $75. | **Yeniden Ayağa Kalk** — Toparlanma işlerinden gelir kazanarak nakdini yeniden 75 $ seviyesine çıkar. |
| `trading.achievement.versatile.v1` | **Versatile Trader** — Profit from five different product models. | **Çok Yönlü Tüccar** — Beş farklı ürün modelini kârla sat. |
| `trading.achievement.weeklyFinisher.v1` | **Challenge Finisher** — Finalize a weekly challenge with at least one completed trade. | **Mücadele Tamamlayıcısı** — En az bir al-sat tamamladığın haftalık mücadelenin sonucunu kesinleştir. |

## Sandbox and release acceptance

- Use a correctly signed development build with Game Center enabled and resources configured in the matching app/environment. Test on an actual device and a supported simulator; this unsigned local build cannot prove live account/resource behavior.
- Test a fresh player without signing in: no Apple modal, all career actions and notifications work, weekly challenge can be played offline after onboarding.
- Connect deliberately; complete and cancel the system UI. Test authentication failure, restricted accounts, Settings sign-out and return, and account switching. Confirm there is no automatic reprompt loop.
- With two accounts that are Game Center friends, finalize comparable weekly runs and confirm submissions, global/friends rank, dashboard return and the score-version context. Check a deliberately mismatched recurring start/duration refuses submission.
- Complete an achievement offline, kill/relaunch, reconnect and verify exactly retained progress. Interrupt network and change accounts during sync; local progress remains and the next sync is idempotent.
- Exercise the Monday 00:00 UTC boundary, timezone changes and clock rollback. Late results stay local; no result leaks to another occurrence or career. Use injected fixtures/domain tests to cover dates, not a production time-travel button.
- Review Turkish and English on standard and accessibility text sizes, VoiceOver order/percentages, Reduce Motion, dark mode, status labels and sheet dismissal. Automated tests cover accessibility labels and larger layouts; a physical-device VoiceOver pass is still required.
- Do not announce real ranks or claim live Game Center verification until the owner completes this signed sandbox pass. No Apple credentials or App Store Connect resources were created by this implementation.

## Deferred integrations

Direct friend challenges and Game Center Activities are deferred in V1 to keep iOS 17 support and scope focused. `CompetitionRoute.activity(identifier:)` recognizes the reserved future identifier `trading.activity.weekly.v1`; it is an internal adapter seam, not a registered activity or URL scheme. No Camera/Retro activity is advertised. A future authenticated GameKit listener can map a verified supported activity to this route and present its challenge context, with availability guards and matching App Store Connect configuration. Do not treat unrecognized activities as permission to enter a different economy.

## Apple references

- [Authenticating a player](https://developer.apple.com/documentation/gamekit/authenticating-a-player)
- [Creating recurring leaderboards](https://developer.apple.com/documentation/gamekit/creating-recurring-leaderboards)
- [Recurring leaderboard entries use allTime](https://developer.apple.com/documentation/gamekit/gkleaderboard/loadentries(for:timescope:range:completionhandler:))
- [Rewarding players with achievements](https://developer.apple.com/documentation/gamekit/rewarding-players-with-achievements)
- [Manage leaderboards in App Store Connect](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-leaderboards/)

Implementation compiles against the installed SDK with iOS 26 deployment. Runtime API usage is limited to APIs available on that target; newer Challenge/Activity APIs are not called.

Current presentation (2026-10-23): leaderboard and achievement screens use GKAccessPoint triggers. The authentication controller remains an optional sign-in sheet. Selecting a signing team in Xcode does not configure App Store Connect resources or verify a live leaderboard.
