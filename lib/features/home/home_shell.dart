import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Bottom navigation on phones, a navigation rail from tablet size up.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final showAdmin = me?.canAssign ?? false;

    final destinations = <_Destination>[
      _Destination(t.chat, Icons.forum_outlined, Icons.forum),
      _Destination(t.tasks, Icons.task_alt_outlined, Icons.task_alt),
      _Destination(t.agenda, Icons.calendar_month_outlined, Icons.calendar_month),
      _Destination(t.members, Icons.people_outline, Icons.people),
      _Destination(t.profile, Icons.person_outline, Icons.person),
      if (showAdmin)
        _Destination(t.admin, Icons.shield_outlined, Icons.shield),
    ];

    void go(int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );

    if (isCompact(context)) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex.clamp(0, destinations.length - 1),
          onDestinationSelected: go,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExpanded(context),
            minExtendedWidth: 190,
            selectedIndex: navigationShell.currentIndex.clamp(0, destinations.length - 1),
            onDestinationSelected: go,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CtgColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('CTG',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: t.settings,
                    onPressed: () => context.go('/settings'),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
