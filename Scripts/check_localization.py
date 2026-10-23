"""Validate catalog completeness before committing localized content."""
import json
import re
from pathlib import Path

catalog = Path(__file__).resolve().parents[1] / "ProjectFlip/Resources/Localizable.xcstrings"
data = json.loads(catalog.read_text())
def units(value):
    if "stringUnit" in value:
        yield value["stringUnit"]
    for child in value.get("variations", {}).values():
        for variant in child.values():
            yield from units(variant)

errors = []
for key, entry in data["strings"].items():
    if not entry.get("comment"):
        errors.append(f"{key}: missing translator context")
    # GameText resolves semantic intents dynamically; automatic extraction cannot see them.
    if entry.get("extractionState") != "manual":
        errors.append(f"{key}: use manual extraction so dynamic gameplay copy cannot become stale")
    for language in ("en", "tr", "de", "fr"):
        translations = list(units(entry.get("localizations", {}).get(language, {})))
        reference_units = list(units(entry.get("localizations", {}).get("en", {})))
        reference = sorted(re.findall(r"%(?:[0-9]+\$)?(?:lld|ld|d|@|f)", reference_units[0]["value"])) if reference_units else []
        for unit in translations:
            if sorted(re.findall(r"%(?:[0-9]+\$)?(?:lld|ld|d|@|f)", unit.get("value", ""))) != reference:
                errors.append(f"{key}: mismatched {language} format arguments")
        if not translations or any(unit.get("state") != "translated" or not unit.get("value") or unit.get("value") == key for unit in translations):
            errors.append(f"{key}: missing {language} translation")
if errors:
    raise SystemExit("\n".join(errors))
print(f"Validated {len(data['strings'])} keys in English, Turkish, German and French.")
