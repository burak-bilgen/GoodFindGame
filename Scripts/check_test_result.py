#!/usr/bin/env python3
"""Fail a simulator checkpoint on test failures or recorded runtime warnings."""
import json
import subprocess
import sys

if len(sys.argv) != 2:
    sys.exit("Usage: python3 Scripts/check_test_result.py <result.xcresult>")

summary = json.loads(subprocess.check_output([
    "xcrun", "xcresulttool", "get", "test-results", "summary",
    "--path", sys.argv[1], "--compact",
], text=True))
print(f"{summary['result']}: {summary['passedTests']} passed, "
      f"{summary['failedTests']} failed, {summary['skippedTests']} skipped")
warnings = summary.get("runtimeWarnings", [])
for warning in warnings:
    print(f"Runtime warning: {warning['message']}")
if summary["result"] != "Passed" or not summary["passedTests"] or warnings:
    sys.exit(1)
print("No recorded runtime warnings.")
