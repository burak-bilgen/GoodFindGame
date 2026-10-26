#!/usr/bin/env python3
"""Validate every packaged image, manifest association and App Store icon."""
import json
import re
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
assets = root / 'ProjectFlip/Resources/Assets.xcassets'
errors = []
count = 0
for folder in sorted(assets.glob('*.imageset')):
    info = json.loads((folder / 'Contents.json').read_text())
    names = [x['filename'] for x in info['images'] if x.get('filename')]
    if not names:
        errors.append(f'{folder.name}: no packaged photograph')
    for name in names:
        image = folder / name
        if not image.is_file():
            errors.append(f'{folder.name}: missing {name}')
            continue
        props = subprocess.check_output(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', str(image)], text=True)
        size = [int(v) for v in re.findall(r'pixel(?:Width|Height): (\d+)', props)]
        if len(size) != 2 or min(size) < 500 or size[0] != size[1]:
            errors.append(f'{folder.name}: photograph must be square and at least 500px, got {size}')
        count += 1
    extra = [x.name for x in folder.iterdir() if x.suffix.lower() in {'.jpg', '.jpeg', '.png'} and x.name not in names]
    if extra:
        errors.append(f'{folder.name}: unused image files: {extra}')
icon = assets / 'AppIcon.appiconset/AppIcon.png'
props = subprocess.check_output(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', '-g', 'hasAlpha', str(icon)], text=True)
if 'pixelWidth: 1024' not in props or 'pixelHeight: 1024' not in props or 'hasAlpha: no' not in props:
    errors.append('App icon must be an opaque 1024×1024 image')
for category in ['home', 'furniture', 'everyday']:
    for index in range(10):
        if not (assets / f'Product-model-{category}-{index}.imageset/photo.jpg').is_file():
            errors.append(f'Missing model photograph: {category}-{index}')
if errors:
    raise SystemExit('\n'.join(errors))
print(f'Validated {count} product photographs and the opaque 1024px app icon.')
