#!/usr/bin/env python3
"""Emit prototype/i18n.js from the same ARB files the Flutter app uses,
so the clickable prototype can never drift from the real translations."""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
LOCALES = ['en', 'fr', 'ar']

bundle = {}
for loc in LOCALES:
    data = json.load(open(ROOT / 'lib' / 'l10n' / f'app_{loc}.arb', encoding='utf-8'))
    bundle[loc] = {k: v for k, v in data.items() if not k.startswith('@')}

out = ROOT / 'prototype' / 'i18n.js'
out.write_text(
    '// GENERATED from lib/l10n/*.arb by tool/gen_prototype_i18n.py - do not edit.\n'
    'window.I18N = ' + json.dumps(bundle, ensure_ascii=False, indent=2) + ';\n',
    encoding='utf-8')
print('wrote', out.relative_to(ROOT))
