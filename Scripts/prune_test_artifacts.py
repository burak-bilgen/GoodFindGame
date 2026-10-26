#!/usr/bin/env python3
"""Keep final/comprehensive checkpoints; retain summaries and PNG evidence before pruning intermediates."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('root', type=Path)
parser.add_argument('--apply', action='store_true')
args = parser.parse_args()
root = args.root.resolve()
if root.name != 'Artifacts' or not root.is_dir():
    raise SystemExit('Expected the project Artifacts directory')
records = []
for path in sorted(root.rglob('*.xcresult')):
    if path.is_symlink() or not path.is_dir():
        continue
    result = subprocess.run(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(path), '--compact'], capture_output=True, text=True)
    if result.returncode:
        continue  # Unknown/unreadable bundles are retained.
    summary = json.loads(result.stdout)
    size = sum(x.stat().st_size for x in path.rglob('*') if x.is_file())
    records.append({'path': path, 'summary': summary, 'size': size, 'time': path.stat().st_mtime})
keep = set()
for parent in {x['path'].parent for x in records}:
    group = [x for x in records if x['path'].parent == parent]
    passed = [x for x in group if x['summary'].get('result') == 'Passed' and not x['summary'].get('runtimeWarnings')]
    failed = [x for x in group if x['summary'].get('result') != 'Passed']
    if passed:
        keep.add(max(passed, key=lambda x: x['time'])['path'])
        keep.add(max(passed, key=lambda x: (x['summary'].get('passedTests', 0), x['time']))['path'])
    if failed:
        keep.add(max(failed, key=lambda x: x['time'])['path'])
removed = []
for item in records:
    path = item['path']
    if path in keep:
        continue
    # Only prune superseded siblings with another retained checkpoint in the same folder.
    if not any(x.parent == path.parent for x in keep):
        continue
    record = {'path': str(path.relative_to(root)), 'bytes': item['size'], 'result': item['summary'].get('result')}
    print(('Prune' if args.apply else 'Would prune'), record)
    if args.apply:
        evidence = path.parent / 'checkpoint-summaries' / path.stem
        evidence.mkdir(parents=True, exist_ok=True)
        (evidence / 'summary.json').write_text(json.dumps(item['summary'], ensure_ascii=False, indent=2) + '\n')
        tests = subprocess.run(['xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path', str(path), '--compact'], capture_output=True, text=True, check=True)
        (evidence / 'tests.json').write_text(tests.stdout)
        subprocess.run(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(path), '--output-path', str(evidence / 'screenshots'), '--filter', '*.png'], check=True, stdout=subprocess.DEVNULL)
        if root not in path.resolve().parents or path.suffix != '.xcresult':
            raise SystemExit('Refusing unexpected path')
        shutil.rmtree(path)
    removed.append(record)
report = {'applied': args.apply, 'retained': [str(x.relative_to(root)) for x in sorted(keep)], 'pruned': removed, 'bundleBytesRemoved': sum(x['bytes'] for x in removed)}
if args.apply:
    (root / 'cleanup-2026-10-24.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f"{'Removed' if args.apply else 'Eligible'}: {len(removed)} bundles, {report['bundleBytesRemoved'] / 1024**3:.2f} GiB; PNG evidence and summaries preserved on apply.")
