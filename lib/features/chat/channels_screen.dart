import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key, this.selectedId, this.onSelect});

  final String? selectedId;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
    final rooms = channels.where((c) => !c.isDm).toList();
    final dms = channels.where((c) => c.isDm).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.chat),
        actions: [
          IconButton(
            tooltip: t.newChannel,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _showNewConversationSheet(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionHeader(t.channels),
          for (final c in rooms)
            _ChannelTile(
              channel: c,
              selected: c.id == selectedId,
              onTap: () => _open(context, c.id),
            ),
          SectionHeader(t.directMessages),
          for (final c in dms)
            _ChannelTile(
              channel: c,
              peer: ref.watch(usersByIdProvider)[c.peerOf(me?.id ?? '')],
              selected: c.id == selectedId,
              onTap: () => _open(context, c.id),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, String id) {
    if (onSelect != null) {
      onSelect!(id);
    } else {
      context.go('/chat/$id');
    }
  }

  static Future<void> _showNewConversationSheet(BuildContext context, WidgetRef ref) async {
    final t = tr(context);
    final me = ref.read(currentUserProvider);
    final users = (ref.read(usersProvider).value ?? const <AppUser>[])
        .where((u) => u.id != me?.id)
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(t.newMessage, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final u in users)
              ListTile(
                leading: UserAvatar(user: u, size: 36, showPresence: true),
                title: Text(u.displayName),
                subtitle: Text(u.title),
                onTap: () async {
                  final channel =
                      await ref.read(chatRepositoryProvider).openDm(me!.id, u.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.go('/chat/${channel.id}');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends ConsumerWidget {
  const _ChannelTile({required this.channel, this.peer, this.selected = false, this.onTap});

  final Channel channel;
  final AppUser? peer;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final unread = ref.watch(unreadCountProvider(channel.id));
    final title = channel.isDm ? (peer?.displayName ?? '') : '# ${channel.name}';

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(.08),
        leading: channel.isDm
            ? UserAvatar(user: peer, size: 40, showPresence: true)
            : CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  channel.type == ChannelType.private ? Icons.lock_outline : Icons.tag,
                  size: 20,
                ),
              ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          channel.lastMessageText.isEmpty ? channel.topic : channel.lastMessageText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (channel.lastMessageAt != null)
              Text(
                formatRelative(channel.lastMessageAt!, locale, t),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            const SizedBox(height: 4),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
