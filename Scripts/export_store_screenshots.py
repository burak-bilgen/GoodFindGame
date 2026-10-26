#!/usr/bin/env python3
"""Select actual passing gameplay captures; never resize, redraw or fabricate UI."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('result', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
result = args.result.resolve()
output = args.output.resolve()
if output.exists():
    raise SystemExit('Choose a fresh output directory to preserve any reviewed screenshot set.')
subprocess.run(['python3', str(root / 'Scripts/check_test_result.py'), str(result)], check=True)
selection = {}
for code, locale, test in [('en','en-US','English'), ('tr','tr','Turkish')]:
    selection[locale] = (f'ProjectFlipUITests/testFirstTrade{test}()', [f'market {code}', f'listing {code}', f'inspection {code}', f'buyer offer {code}', f'trade result {code}'])
for code, locale, test in [('de','de-DE','GermanAndFrench'), ('fr','fr-FR','GermanAndFrench'), ('es','es-ES','SpanishAndItalian'), ('it','it','SpanishAndItalian')]:
    selection[locale] = (f'LanguageUITests/testCompleteTrade{test}()', [f'Market {code}', [f'Listing {code}', f'Trade appraisal {code}'], f'Inspection decision {code}', f'Buyer decision {code}', f'Trade outcome {code}'])
labels = ['market', 'deal', 'inspection', 'buyer', 'outcome']
records = []
with tempfile.TemporaryDirectory(prefix='ProjectFlip-store-export-') as directory:
    staging = Path(directory)
    subprocess.run(['xcrun','xcresulttool','export','attachments','--path',str(result),'--output-path',str(staging),'--filter','*.png'], check=True, stdout=subprocess.DEVNULL)
    manifest = json.loads((staging / 'manifest.json').read_text())
    chosen = []
    for locale, (test, names) in selection.items():
        attachments = [a for entry in manifest if entry['testIdentifier'] == test for a in entry['attachments']]
        for index, prefixes in enumerate(names):
            entry = None
            for prefix in ([prefixes] if isinstance(prefixes, str) else prefixes):
                matches = {a['exportedFileName']: a for a in attachments if a['suggestedHumanReadableName'].lower().startswith(prefix.lower() + '_')}
                if len(matches) > 1:
                    raise SystemExit(f'{locale}: ambiguous {prefix!r} captures')
                if matches:
                    entry = next(iter(matches.values()))
                    break
            if entry is None:
                raise SystemExit(f'{locale}: no capture for {prefixes!r}')
            source = staging / entry['exportedFileName']
            info = subprocess.check_output(['sips','-g','pixelWidth','-g','pixelHeight','-g','hasAlpha',str(source)],text=True)
            size = tuple(int(x) for x in re.findall(r'pixel(?:Width|Height): (\d+)',info))
            if size not in [(1179,2556),(1206,2622)] or 'hasAlpha: no' not in info:
                raise SystemExit(f'{locale}: capture must be an opaque accepted medium Dynamic Island portrait size, got {size}')
            chosen.append((source, Path(locale) / f'{index+1:02d}-{labels[index]}.png', entry, size))
    output.mkdir(parents=True)
    for source, destination, entry, size in chosen:
        target = output / destination
        target.parent.mkdir(exist_ok=True)
        shutil.copyfile(source,target)
        records.append({'path': str(destination), 'sourceAttachment': entry['suggestedHumanReadableName'], 'device': entry['deviceName'], 'pixels': size, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()})
(output / 'provenance.json').write_text(json.dumps({'result': str(result), 'policy': 'Unmodified actual simulator gameplay captures from passing tests. No generated UI, composites or fabricated outcomes.', 'screenshots': records},ensure_ascii=False,indent=2)+'\n')
print(f'Exported {len(records)} opaque screenshots in six languages to {output}')
