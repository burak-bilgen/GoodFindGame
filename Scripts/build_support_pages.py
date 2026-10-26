#!/usr/bin/env python3
"""Build static, tracker-free publisher pages from the same localized in-app copy."""
import html
import json
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
strings = json.loads((root / 'ProjectFlip/Resources/Localizable.xcstrings').read_text())['strings']
publisher = json.loads((root / 'Release/Publisher.json').read_text())
out = root / 'Release/Website'; out.mkdir(exist_ok=True)
brand = html.escape(strings['notifications.title']['localizations']['en']['stringUnit']['value'])
style = 'body{margin:0;background:#0e110f;color:#f2f0e0;font:17px/1.65 system-ui,sans-serif}main{max-width:760px;margin:auto;padding:48px 24px}a{color:#b3d9a6}nav{display:flex;flex-wrap:wrap;gap:16px}h1{line-height:1.2}section{background:#1b1f1d;padding:24px;border-radius:16px;margin:24px 0}footer{color:#b5bfb5}img{border-radius:22%;width:80px;height:80px}'
for language in ['en', 'tr', 'de', 'fr', 'es', 'it']:
    def text(key):
        return html.escape(strings[key]['localizations'][language]['stringUnit']['value'])
    language_label = {'en': 'Language', 'tr': 'Dil', 'de': 'Sprache', 'fr': 'Langue', 'es': 'Idioma', 'it': 'Lingua'}[language]
    for page, keys, title in [('privacy', ['privacy.local', 'privacy.tracking', 'privacy.apple', 'privacy.control', 'privacy.support'], 'privacy.title'), ('support', ['support.play', 'support.saves'], 'support.title')]:
        navigation = ' '.join(f'<a href="{page}-{code}.html" lang="{code}">{label}</a>' for code, label in [('en','English'),('tr','Türkçe'),('de','Deutsch'),('fr','Français'),('es','Español'),('it','Italiano')])
        sections = ''.join('<section><p>'+text(key)+'</p></section>' for key in keys)
        contact = ''
        if publisher.get('supportEmail'):
            address = html.escape(publisher['supportEmail'], quote=True)
            contact = f'<p><a href="mailto:{address}">{text("support.contact")}: {address}</a></p>'
        body = f'<!doctype html><html lang="{language}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{brand} — {text(title)}</title><style>{style}</style><main><img src="icon.png" alt="{brand}"><h1>{brand} — {text(title)}</h1><nav aria-label="{language_label}">{navigation}</nav>{sections}{contact}<footer><nav><a href="support-{language}.html">{text("support.title")}</a><a href="privacy-{language}.html">{text("privacy.title")}</a><a href="https://www.apple.com/legal/privacy/">{text("privacy.applePolicy")}</a></nav><p>2026-10-25 · {brand} 1.0</p></footer></main></html>'
        (out / f'{page}-{language}.html').write_text(body)
shutil.copyfile(out / 'support-en.html', out / 'index.html')
shutil.copyfile(root / 'ProjectFlip/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png', out / 'icon.png')
print('Built six-language static support and privacy pages. Verify the published URLs before configuring the app.')
