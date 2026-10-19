# Project Flip

Original offline-first iPhone trading game. Internal codename; final branding requires clearance.

Open `ProjectFlip.xcodeproj`. Requires Xcode with Swift 6 support; deployment target iOS 17, portrait iPhone. No external dependencies or signing team is stored. Select your personal team locally for device builds.

```sh
python3 Scripts/check_localization.py
xcodebuild -project ProjectFlip.xcodeproj -scheme ProjectFlip -destination 'platform=iOS Simulator,name=iPhone 18 Pro' CODE_SIGNING_ALLOWED=NO test
```

See Docs for requirements and milestone status. Localization uses semantic keys in a String Catalog; English and Turkish are first-class languages. Keep simulation independent of UI and locale.
