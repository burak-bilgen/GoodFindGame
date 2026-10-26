#!/usr/bin/env python3
"""Fail closed on incomplete App Store contact metadata or archive privacy settings."""
import argparse
import json
import plistlib
import subprocess
from pathlib import Path
from urllib.request import Request, urlopen

parser = argparse.ArgumentParser()
parser.add_argument('--app', type=Path)
parser.add_argument('--check-urls', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
subprocess.run(['python3', str(root / 'Scripts/check_localization.py')], check=True)
subprocess.run(['python3', str(root / 'Scripts/check_assets.py')], check=True)
publisher_check = subprocess.run(['python3', str(root / 'Scripts/configure_publisher.py'), '--check'], capture_output=True, text=True)
errors = []
catalog = json.loads((root / 'ProjectFlip/Resources/Localizable.xcstrings').read_text())['strings']
brand = catalog['notifications.title']['localizations']['en']['stringUnit']['value']
if publisher_check.returncode:
    errors.append(publisher_check.stderr.strip() or publisher_check.stdout.strip())
for locale in ['en-US', 'tr', 'de-DE', 'fr-FR', 'es-ES', 'it']:
    path = root / 'Release/AppStore' / (locale + '.json')
    data = json.loads(path.read_text())
    if data.get('name') != brand:
        raise SystemExit(f'{path.name}: store name must match the packaged brand {brand}')
    for key, limit in [('name', 30), ('subtitle', 30), ('keywords', 100), ('promotionalText', 170), ('description', 4000)]:
        if not isinstance(data.get(key), str) or not 0 < len(data[key]) <= limit:
            raise SystemExit(f'{path.name}: invalid {key}')
if args.check_urls and publisher_check.returncode == 0:
    config = json.loads((root / 'Release/Publisher.json').read_text())
    for key in ['privacyPolicyURL', 'supportURL']:
        request = Request(config[key], headers={'User-Agent': 'ProjectFlip-Release-Check/1.0'})
        with urlopen(request, timeout=20) as response:
            if response.status != 200 or response.url.split(':')[0] != 'https':
                raise SystemExit(f'{key}: public HTTPS page must return 200')
if args.app:
    app = args.app.resolve()
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if info.get('CFBundleDisplayName') != brand:
        raise SystemExit('Archive display name is stale; rebuild with the current brand')
    for language in ['en', 'tr', 'de', 'fr', 'es', 'it']:
        folder = app / (language + '.lproj')
        if not (folder / 'Localizable.strings').is_file() or not (folder / 'Localizable.stringsdict').is_file():
            raise SystemExit(f'Archive is missing complete {language} resources; rebuild')
        strings = plistlib.loads((folder / 'Localizable.strings').read_bytes())
        plurals = plistlib.loads((folder / 'Localizable.stringsdict').read_bytes())
        for key, entry in catalog.items():
            translation = entry['localizations'][language]
            if 'stringUnit' in translation:
                if strings.get(key) != translation['stringUnit']['value']:
                    raise SystemExit(f'Archive has stale/missing {language} text for {key}; rebuild')
            else:
                for form, unit in translation['variations']['plural'].items():
                    if plurals.get(key, {}).get('value', {}).get(form) != unit['stringUnit']['value']:
                        raise SystemExit(f'Archive has stale/missing {language} plural {key}/{form}; rebuild')
    print(f'Validated all {len(catalog)} current catalog keys in six packaged languages.')
    if info.get('CFBundleIdentifier') != 'gameproject.bilgenworks.ProjectFlip':
        raise SystemExit('Unexpected production bundle identifier')
    if info.get('ITSAppUsesNonExemptEncryption') not in [False, 'NO']:
        raise SystemExit('Review the export compliance declaration')
    privacy = plistlib.loads((app / 'PrivacyInfo.xcprivacy').read_bytes())
    if privacy.get('NSPrivacyTracking') or privacy.get('NSPrivacyCollectedDataTypes'):
        raise SystemExit('Privacy declarations changed: review App Store privacy answers')
    if not any(x.get('NSPrivacyAccessedAPIType') == 'NSPrivacyAccessedAPICategoryUserDefaults' and 'CA92.1' in x.get('NSPrivacyAccessedAPITypeReasons', []) for x in privacy.get('NSPrivacyAccessedAPITypes', [])):
        raise SystemExit('Missing UserDefaults required-reason declaration')
    configured = json.loads((root / 'Release/Publisher.json').read_text())
    for key, field in [('PrivacyPolicyURL', 'privacyPolicyURL'), ('SupportURL', 'supportURL'), ('SupportEmail', 'supportEmail')]:
        if not info.get(key):
            errors.append(f'Archive is missing {key}; apply the publisher configuration and rebuild')
        elif info[key] != configured.get(field):
            errors.append(f'Archive {key} does not match the current publisher configuration; rebuild')
    if info.get('OnlineCompetitionEnabled') not in [False, 'NO']:
        errors.append('Online competition must remain disabled until signed sandbox acceptance')
    signature = subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], capture_output=True, text=True)
    if signature.returncode:
        errors.append('Archive is unsigned or its signature is invalid. Sign with the publisher Apple Developer account before upload.')
    else:
        details = subprocess.run(['codesign', '--display', '--verbose=4', str(app)], capture_output=True, text=True)
        if 'Signature=adhoc' in details.stderr or 'Authority=Apple ' not in details.stderr:
            errors.append('An ad-hoc/local signature is insufficient; use the publisher Apple signing identity.')
        if not (app / 'embedded.mobileprovision').is_file():
            errors.append('Archive has no embedded provisioning profile; sign and validate it in Xcode.')
    if info.get('UIDeviceFamily') != [1]:
        raise SystemExit('Device families changed: recheck required screenshots')
    if info.get('MinimumOSVersion') != '26.0':
        raise SystemExit('Minimum OS changed: rerun platform acceptance')
if errors:
    raise SystemExit('\n'.join(errors))
print('Local release metadata checks passed. Signing, App Store account fields and review submission remain separate checks.')
