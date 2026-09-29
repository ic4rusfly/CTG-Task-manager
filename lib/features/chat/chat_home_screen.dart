import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';

/// Chat entry point: a single pane on phones, master/detail on tablets,
/// desktop and web.
class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key, this.channelId});

  final String? channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    if (isCompact(context)) {
      return channelId == null
          ? const ChannelsScreen()
          : ChatScreen(channelId: channelId!);
    }

    final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
    final effectiveId = channelId ?? (channels.isEmpty ? null : channels.first.id);

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: ChannelsScreen(
            selectedId: effectiveId,
            onSelect: (id) => context.go('/chat/$id'),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: effectiveId == null
              ? Scaffold(
                  body: EmptyState(icon: Icons.forum_outlined, message: t.channels),
                )
              : ChatScreen(
                  key: ValueKey(effectiveId),
                  channelId: effectiveId,
                  showBackButton: false,
                ),
        ),
      ],
    );
  }
}
