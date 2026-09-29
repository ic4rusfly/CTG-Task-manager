import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../domain/push_service.dart';
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
          SectionHeader(t.notifications),
          const _PushTile(),
          SectionHeader(t.account),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(t.signOut),
            onTap: () async {
              final me = ref.read(currentUserProvider);
              if (me != null) {
                await ref.read(pushServiceProvider).unregister(me.id);
              }
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}

/// Push permission and device registration, with the same wording in all
/// three languages.
class _PushTile extends ConsumerWidget {
  const _PushTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final permission = ref.watch(pushPermissionProvider);
    final status = permission.value ?? PushPermission.notDetermined;

    final subtitle = switch (status) {
      PushPermission.granted => t.deviceRegistered,
      PushPermission.denied => t.pushBlocked,
      PushPermission.unsupported => t.pushUnsupported,
      PushPermission.notDetermined => t.pushOnThisDevice,
    };

    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: Text(t.pushNotifications),
      subtitle: Text(subtitle),
      value: status == PushPermission.granted,
      onChanged: me == null ||
              status == PushPermission.denied ||
              status == PushPermission.unsupported
          ? null
          : (wanted) async {
              final push = ref.read(pushServiceProvider);
              if (wanted) {
                await push.register(me.id);
              } else {
                await push.unregister(me.id);
              }
              ref.invalidate(pushPermissionProvider);
            },
    );
  }
}
