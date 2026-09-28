import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        children: [
          SectionHeader(t.language),
          for (final code in ['en', 'fr', 'ar'])
            RadioListTile<String>(
              value: code,
              groupValue: locale.languageCode,
              title: Text(languageLabel(code)),
              subtitle: Text(code == 'ar' ? 'RTL' : 'LTR'),
              onChanged: (v) async {
                if (v == null) return;
                ref.read(localeOverrideProvider.notifier).state = Locale(v);
                if (me != null) {
                  await ref.read(userRepositoryProvider).setLocale(me.id, v);
                }
              },
            ),
          SectionHeader(t.theme),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeMode,
            title: Text(t.themeSystem),
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeMode,
            title: Text(t.themeLight),
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeMode,
            title: Text(t.themeDark),
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          SectionHeader(t.account),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(t.signOut),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
