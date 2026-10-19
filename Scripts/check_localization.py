"""Validate catalog completeness before committing localized content."""
import json
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
    for language in ("en", "tr"):
        translations = list(units(entry.get("localizations", {}).get(language, {})))
        if not translations or any(unit.get("state") != "translated" or not unit.get("value") or unit.get("value") == key for unit in translations):
            errors.append(f"{key}: missing {language} translation")
if errors:
    raise SystemExit("\n".join(errors))
print(f"Validated {len(data['strings'])} keys in Turkish and English.")
