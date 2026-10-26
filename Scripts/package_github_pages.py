#!/usr/bin/env python3
"""Package only the public publisher website for an isolated Pages repository."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
website = root / 'Release/Website'
files = sorted(website.glob('*.html')) + [website / 'icon.png']
assert len(files) == 14 and all(p.is_file() for p in files), 'Rebuild all six website languages first'
output = root.parent / 'Artifacts/Pazlume-v1-2026-10-25/Pazlume-GitHub-Pages.zip'
output.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(output, 'w', compression=ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, path.name)
    archive.writestr('.nojekyll', '')
print(output)
