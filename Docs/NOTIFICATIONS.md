# Local notifications and routing

Only persisted future game events can produce requests. The identifier is exactly `GameEvent.id`. Seller reply results and buyer offers are committed simulation outcomes before they are scheduled; generic overpriced-interest retries and expiry housekeeping do not invent offers or urgency. Content uses first-class Turkish/English templates, locale-formatted money and a concrete expiry time. At most 48 earliest eligible events are scheduled.

Five category preferences are saved independently: offers/negotiations, shipping/inspection, auctions, market events and client requests. Only currently implemented event systems generate alerts. Native authorization is never requested on first launch: the explicit enable control remains disabled until an asynchronous event exists. Denial does not block the game; Settings explains how to change the OS choice. Choosing Later suppresses the contextual prompt while preserving manual settings access.

Synchronization runs after persisted commits and on foreground/locale changes. A serialized worker coalesces revisions, so an older asynchronous scheduling pass cannot finish after a newer pass and leave obsolete requests behind. Requests with stable identifiers are replaced, obsolete owned requests/delivered entries are removed, and category changes re-plan immediately. Scheduling failures are logged in DEBUG and exposed in notification settings without blocking core play.

Notification responses carry a bounded Codable route identifying the conversation, owned item or resale listing. Routes are decoded and validated; a no-longer-owned/missing target opens a handled-event explanation with trade history access. The cold-load inbox retains a tap until the local save finishes loading, and notification destinations take precedence over the while-away summary. The routed sheet has a localized explicit close control.

## Runtime verification

43 unit tests pass, including notification source validity, IDs, category filtering, no fabricated overpriced offers, locale-specific text, route decoding and preference migration. The UI category test toggles the actual switch control, persists the choice, relaunches and opens the exact conversation through the same route inbox. The native test grants permission where required, backgrounds the app, observes a real iOS banner and taps it to open the correct conversation and purchase action. Its actual banner attachment was visually inspected. English fast trading and real-timer Turkish relaunch trading also remain verified. Simulator evidence is iOS 27.2; physical-device/older-runtime release validation remains required.

## Native callback crash regression

The first async `didReceive` implementation caused SIGABRT when tapping the real notification: UIKit state-restoration frames were reached from the compiler-generated Objective-C completion on a cooperative worker. A minimized native-delivery/tap test reproduced the crash in 12.6 seconds; a synthetic route alone did not reproduce it. Completion-handler delegate methods now explicitly finish once on the main actor, with only Sendable strings crossing into routing. No unchecked framework conformances or error suppression were added. The minimized scenario passed in 16.7 seconds and the original permission/navigation scenario passed afterward. Foreground presentation uses the same completion boundary and remains quiet while the game is open.

Repro/regression command: `xcodebuild -project ProjectFlip.xcodeproj -scheme ProjectFlip -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -parallel-testing-enabled NO -only-testing:ProjectFlipUITests/ProjectFlipUITests/testNativeNotificationDeliveryAndTapRouting CODE_SIGNING_ALLOWED=NO test`.

Primary references: [Apple delegate API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate), [Apple DTS explanation of the async executor transition](https://developer.apple.com/forums/thread/735651). The installed SDK header and our captured native crash/green native test establish the behavior for this project.
