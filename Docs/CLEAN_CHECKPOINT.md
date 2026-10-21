# Clean checkpoint and human gameplay validation — 21 October 2026

Historical checkpoint e38f821. The owner subsequently authorized the scoped
[living-marketplace follow-up](LIVING_MARKETPLACE.md); its current verification
supersedes the pacing and feature state recorded here.

This checkpoint stabilizes the existing trading game. The broader V1 backlog
remains paused. Human enjoyment, fairness, pacing and repeat-play retention are
questions for the next playtest, not conclusions from automated tests.

## Changes

- Marked the decorative unknown-condition question mark as verbatim text. Removed
  its empty extracted catalog entry without changing the 451 translated entries.
  Subsequent builds no longer recreate that invalid key.
- Kept the pending original controller/card/price-tag app icon and its reproducible
  renderer. The 1024×1024 PNG is opaque; regeneration produces the same SHA-256.
- Moved numeric-entry Done actions from keyboard accessory toolbars to the
  navigation bar while their fields are focused. This preserves localized keyboard
  dismissal across market filters, seller offers, resale pricing and buyer counters.
- Removed the obsolete root master brief. The corrected 2,712-line brief under
  Docs remains unchanged, including its auction stretch restriction and corrected
  First 72 Hours section reference. Updated stale current-status and category-fact
  notes while preserving dated verification history.
- Added a focused repeated-keyboard regression and a test-result check that fails
  on recorded runtime warnings even when an XCTest interaction passes.
- Prepared HUMAN_PLAYTEST.md for unassisted repeated trading and post-session
  observation. Existing DEBUG reset/state/truth tools and normal trade history
  suffice; no new gameplay, economy, timer, save or analytics system was added.

## Runtime-warning diagnosis

The original English watch/filter journey passed its interaction but recorded
“Invalid frame dimension (negative or non-finite).” Focusing a newly expanded
price field reproduced it in a minimal launch → expand → focus scenario.

Removing the keyboard toolbar's spacer alone did not help. Replacing its group
with one keyboard toolbar item also retained the warning. Moving the same Done
action to the navigation bar removed it. The evidence isolates the triggering
keyboard-toolbar presentation path; it does not claim a diagnosis of private
SwiftUI framework internals.

The permanent UI regression opens the price keyboard twice, enters text, dismisses
it through the navigation action and verifies both dismissal and retained input.
The original English/Turkish filters and connected trades also pass afterward.
The focused verification contains 92 unit tests and five UI scenarios, all passing
with zero recorded runtime warnings.

## Final verification

| Check | Result |
| --- | --- |
| Debug simulator build | Passed |
| Release simulator build (arm64 and x86_64) | Passed |
| Full unit suite | 92 tests in 23 suites passed |
| Full UI suite | 50/50 passed; zero failures or skips |
| Runtime warnings in the full UI result | Zero; invalid-frame warning resolved |
| Focused unit/UI verification | 97/97 passed; zero runtime warnings |
| Localization after builds | All 451 keys validate in English and Turkish |
| Normal Release launch | English and Turkish return screens visually reviewed |
| Release DEBUG/test hooks | Checked markers absent from the compiled binary |
| Compiled target | iPhone, portrait, iOS 17 minimum |
| Build/test inputs | All 91 recorded inputs unchanged after verification |

The full UI suite ran in two isolated iPhone 18 Pro / iOS 27.2 Simulator sessions,
25 scenarios each. Their merged result was checked against all 50 test methods in
the source: no omissions, failures, skips or recorded runtime warnings. This
includes five consecutive trades; localized complete trades, repairs and losses;
large Turkish text; dark/reduced-motion play; actual notification delivery/tap;
offline/relaunch reports; market changes; and continued trading after a first sale.
The temporary additional simulator was removed afterward.

The normal Release build was left running in Turkish on the original simulator.
Its existing normal save was retained; test-save/instant flags were not passed.
Both normal-launch captures show that save's genuine offline return report.

Local evidence is outside the checkout at
`../../Artifacts/CleanCheckpoint-2026-10-21/`: Debug/Release logs,
`frame-regression.xcresult` (92 unit + five UI tests), `full-ui.xcresult` (all
50 UI scenarios), JSON summaries and exact-coverage verification, localization
output, input hashes and unmodified screenshots. `diagnosis/` contains the red
reproductions and one-variable probes, including the first warning-free result.
See that directory's README.md for the evidence index.

The main Docs brief's unchanged SHA-256 is
`3c25a9763af35e494c9c6d340f4784ef59759f85133bcb46dd351d7487aeb582`.

## Playtest boundary

Use [the human playtest guide](HUMAN_PLAYTEST.md). A normal Release session keeps
hidden simulation information out of the player interface and uses production
timing after the accelerated introduction. DEBUG has faster timers; UI tests use
isolated saves and some explicitly opt into instant timing.

The existing automated coverage includes repeated trades, gains/losses, seller
rejection, buyer counters, worthwhile and uneconomical repairs, offline catch-up,
notification routes and repeated browsing. It establishes that these situations
are supported, not that their balance or emotional effect has been validated.

Physical iPhone and iOS 17 runtime testing, physical audio/haptics, broad VoiceOver
testing and unscripted human play remain unverified. Device installation requires
the owner's local signing team; no signing identity is committed. A player can
exhaust their funds through bad decisions; record a stalled session rather than
adding recovery systems or granting rescue cash during the playtest.

The non-blocking Xcode App Intents metadata-extraction warning remains because the
app has no App Intents dependency. It is separate from the SwiftUI runtime warning.
No progression, Game Center, monetization, collections, client requests or other
major feature milestone starts automatically after this checkpoint.
