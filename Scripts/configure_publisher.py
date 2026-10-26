#!/usr/bin/env python3
"""Apply verified publisher contact details to the app and static release pages."""
import argparse
import json
import plistlib
import re
from pathlib import Path
from urllib.parse import urlparse

parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
config = json.loads((root / 'Release/Publisher.json').read_text())
errors = []
for key in ['privacyPolicyURL', 'supportURL']:
    value = config.get(key)
    parsed = urlparse(value or '')
    if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password:
        errors.append(f'{key}: provide the public HTTPS URL in Release/Publisher.json')
email = config.get('supportEmail')
if not isinstance(email, str) or not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', email):
    errors.append('supportEmail: provide the real support address in Release/Publisher.json')
if errors:
    raise SystemExit('\n'.join(errors))
if not args.check:
    # Xcode's generated plist accepts known build keys but can omit custom
    # INFOPLIST_KEY_* settings. Merge publisher keys from an explicit source.
    source = root / 'Configuration/AppInfo.plist'
    info = plistlib.loads(source.read_bytes())
    for key, field in [('PrivacyPolicyURL', 'privacyPolicyURL'), ('SupportURL', 'supportURL'), ('SupportEmail', 'supportEmail')]:
        info[key] = config[field]
    source.write_bytes(plistlib.dumps(info, sort_keys=True))
print('Publisher contact details validated.' if args.check else 'Publisher contact details applied. Rebuild the archive before submission.')
