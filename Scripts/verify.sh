#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 Scripts/check_localization.py
python3 Scripts/check_assets.py
xcodebuild -version
if [[ -z "${TEST_DESTINATION:-}" ]]; then
  simulator_id="$(xcrun simctl list devices available --json | python3 -c 'import json,sys; d=json.load(sys.stdin); phones=[v for k,vs in d["devices"].items() if ".iOS-" in k for v in vs if v.get("isAvailable") and v["name"].startswith("iPhone")]; assert phones, "Install an iPhone simulator runtime"; print(phones[0]["udid"])')"
  TEST_DESTINATION="platform=iOS Simulator,id=$simulator_id"
fi
result_root="${RESULT_ROOT:-$(mktemp -d /tmp/ProjectFlip-verify.XXXXXX)}"
mkdir -p "$result_root"
# Keep complete simulator evidence for CI and local investigation.
xcodebuild -project ProjectFlip.xcodeproj -scheme ProjectFlip -destination "$TEST_DESTINATION" \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO \
  -resultBundlePath "$result_root/tests.xcresult" test > "$result_root/tests.log" 2>&1
python3 Scripts/check_test_result.py "$result_root/tests.xcresult"
xcodebuild -project ProjectFlip.xcodeproj -scheme ProjectFlip -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build > "$result_root/release.log" 2>&1
printf 'Verification evidence: %s\n' "$result_root"
