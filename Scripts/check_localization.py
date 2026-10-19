"""Validate catalog completeness before committing localized content."""
import json
from pathlib import Path

catalog = Path(__file__).resolve().parents[1] / "ProjectFlip/Resources/Localizable.xcstrings"
data = json.loads(catalog.read_text())
errors = []
for key, entry in data["strings"].items():
    if not entry.get("comment"):
        errors.append(f"{key}: missing translator context")
    for language in ("en", "tr"):
        unit = entry.get("localizations", {}).get(language, {}).get("stringUnit", {})
        if unit.get("state") != "translated" or not unit.get("value") or unit.get("value") == key:
            errors.append(f"{key}: missing {language} translation")
if errors:
    raise SystemExit("\n".join(errors))
print(f"Validated {len(data['strings'])} keys in Turkish and English.")
