#!/usr/bin/env python3
"""Generate lib/l10n/app_localizations.dart from the ARB files.

Usage:  python3 tool/gen_l10n.py

app_en.arb is the source of truth; the script fails if app_fr.arb or
app_ar.arb is missing a key, which is what the CI translation check runs.
"""
import collections
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
L10N = ROOT / 'lib' / 'l10n'
LOCALES = ['en', 'fr', 'ar']

HEADER = """// GENERATED FILE - do not edit by hand.
//
// Regenerate with:  python3 tool/gen_l10n.py
// Source of truth:  lib/l10n/app_en.arb  (+ app_fr.arb, app_ar.arb)
//
// A dependency-free localization delegate: it behaves like `flutter gen-l10n`
// output but needs no code-generation step to build the app.
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  Map<String, String> get _s => _strings[localeName] ?? _strings['en']!;

  String _get(String key) => _s[key] ?? _strings['en']![key] ?? key;
"""

FOOTER = r"""
  /// Minimal ICU plural support for the few plural keys we use.
  String _plural(String key, int count) {
    final raw = _get(key);
    final match = RegExp(r'\{count,\s*plural,\s*(.*)\}\s*$', dotAll: true).firstMatch(raw);
    if (match == null) return raw.replaceAll('{count}', '$count');
    final body = match.group(1)!;
    final cases = <String, String>{};
    final re = RegExp(r'(=\d+|zero|one|two|few|many|other)\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}');
    for (final m in re.allMatches(body)) {
      cases[m.group(1)!] = m.group(2)!;
    }
    String? pick = cases['=$count'];
    pick ??= _category(count, cases);
    pick ??= cases['other'] ?? raw;
    return pick.replaceAll('{count}', '$count');
  }

  String? _category(int count, Map<String, String> cases) {
    if (localeName == 'ar') {
      if (count == 0) return cases['zero'];
      if (count == 1) return cases['one'];
      if (count == 2) return cases['two'];
      final mod100 = count % 100;
      if (mod100 >= 3 && mod100 <= 10) return cases['few'];
      if (mod100 >= 11) return cases['many'];
      return cases['other'];
    }
    if (count == 1) return cases['one'];
    return cases['other'];
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
"""


def dq(s: str) -> str:
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$') + "'"


def main() -> int:
    data = {l: json.load(open(L10N / f'app_{l}.arb', encoding='utf-8'),
                         object_pairs_hook=collections.OrderedDict) for l in LOCALES}
    en = data['en']
    keys = [k for k in en if not k.startswith('@')]
    for loc in LOCALES:
        gaps = [k for k in keys if k not in data[loc]]
        if gaps:
            print(f'ERROR: {loc} is missing: {", ".join(gaps)}', file=sys.stderr)
            return 1

    params = {k: list(en['@' + k]['placeholders'].keys())
              for k in keys if '@' + k in en and 'placeholders' in en['@' + k]}
    plural_keys = {k for k in params if '{count, plural' in en[k]}

    out = [HEADER]
    for k in keys:
        if k not in params:
            out.append(f"  String get {k} => _get('{k}');")
    out.append('')
    for k, ps in params.items():
        sig = ', '.join(
            ('int ' + p if en['@' + k]['placeholders'][p].get('type') == 'int' else 'Object ' + p)
            for p in ps)
        if k in plural_keys:
            out.append(f"  String {k}({sig}) => _plural('{k}', {ps[0]});")
        else:
            body = [f'  String {k}({sig}) {{', f"    var s = _get('{k}');"]
            for p in ps:
                body.append(f"    s = s.replaceAll('{{{p}}}', '${p}');")
            body.append('    return s;')
            body.append('  }')
            out.append('\n'.join(body))
    out.append(FOOTER)
    out.append('const _strings = <String, Map<String, String>>{')
    for loc in LOCALES:
        out.append(f"  '{loc}': <String, String>{{")
        for k in keys:
            out.append(f'    {dq(k)}: {dq(data[loc][k])},')
        out.append('  },')
    out.append('};')
    (L10N / 'app_localizations.dart').write_text('\n'.join(out) + '\n', encoding='utf-8')
    print(f'generated app_localizations.dart ({len(keys)} keys x {len(LOCALES)} locales)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
