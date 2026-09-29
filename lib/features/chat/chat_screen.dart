import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/attachment_picker.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../core/mentions.dart';
import '../../core/receipts.dart';
import '../../core/theme.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'chat_composer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.channelId, this.showBackButton = true});

  final String channelId;
  final bool showBackButton;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) _markRead();
  }

  void _markRead() {
    final me = ref.read(currentUserProvider);
    if (me != null) {
      ref.read(chatRepositoryProvider).markRead(widget.channelId, me.id);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _scrollToEnd() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final usersById = ref.watch(usersByIdProvider);
    final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
    final channel = channels.where((c) => c.id == widget.channelId).firstOrNull;
    final all = ref.watch(messagesProvider(widget.channelId)).value ?? const <Message>[];
    // Thread replies live in their own view, not in the channel timeline.
    final messages = all.where((m) => m.replyToId == null).toList();
    final peer = channel?.isDm == true ? usersById[channel!.peerOf(me?.id ?? '')] : null;
    final title = channel == null
        ? ''
        : channel.isDm
            ? (peer?.displayName ?? '')
            : '# ${channel.name}';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (channel != null)
              Text(
                me != null && me.mutedChannels.contains(channel.id)
                    ? t.muted
                    : channel.isDm
                        ? (peer?.online == true ? t.online : t.offline)
                        : (channel.topic.isEmpty
                            ? t.membersCount(channel.memberIds.length)
                            : channel.topic),
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (channel != null)
            IconButton(
              tooltip: me != null && me.mutedChannels.contains(channel.id)
                  ? t.unmute
                  : t.mute,
              icon: Icon(
                me != null && me.mutedChannels.contains(channel.id)
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_none,
              ),
              onPressed: me == null
                  ? null
                  : () async {
                      final muted = me.mutedChannels.contains(channel.id);
                      await ref
                          .read(userRepositoryProvider)
                          .setChannelMuted(me.id, channel.id, !muted);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(muted ? t.unmute : t.mutedHint),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
            ),
          if (channel != null && !channel.isDm)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: t.members,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final id in channel.memberIds)
                      ListTile(
                        leading: UserAvatar(user: usersById[id], size: 36, showPresence: true),
                        title: Text(usersById[id]?.displayName ?? id),
                        subtitle: Text(usersById[id]?.title ?? ''),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? EmptyState(icon: Icons.forum_outlined, message: t.messageHint)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final prev = i == 0 ? null : messages[i - 1];
                      final newDay = prev == null ||
                          !DateUtils.isSameDay(prev.sentAt, m.sentAt);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (newDay) _DaySeparator(date: m.sentAt),
                          MessageBubble(
                            message: m,
                            sender: usersById[m.senderId],
                            isMine: m.senderId == me?.id,
                            grouped: !newDay &&
                                prev?.senderId == m.senderId &&
                                m.sentAt.difference(prev!.sentAt).inMinutes < 5,
                            // Read receipts only under the last message I sent.
                            showReceipt: channel != null &&
                                m.senderId == me?.id &&
                                i == messages.length - 1,
                            channel: channel,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          ChatComposer(
            channelId: widget.channelId,
            onSent: _scrollToEnd,
          ),
        ],
      ),
    );
  }

}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final label = DateUtils.isSameDay(date, now)
        ? t.today
        : DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))
            ? t.yesterday
            : formatDay(date, locale);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.isMine,
    this.grouped = false,
    this.showThread = true,
    this.showReceipt = false,
    this.channel,
  });

  final Message message;
  final AppUser? sender;
  final bool isMine;
  final bool grouped;

  /// Thread affordances are hidden inside the thread view itself.
  final bool showThread;

  /// Shows "Seen by N" under the last message the member sent.
  final bool showReceipt;
  final Channel? channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final me = ref.watch(currentUserProvider);
    final bubbleColor = isMine ? scheme.primary.withOpacity(.12) : scheme.surface;

    return Padding(
      padding: EdgeInsets.only(top: grouped ? 2 : 10),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine)
            SizedBox(
              width: 40,
              child: grouped ? null : UserAvatar(user: sender, size: 34),
            ),
          if (!isMine) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showActions(context, ref, me?.id),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!grouped && !isMine)
                      Text(
                        sender?.displayName ?? '',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CtgColors.avatarColor(sender?.id ?? ''),
                            ),
                      ),
                    if (message.deleted)
                      Text(t.messageDeleted,
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: scheme.outline))
                    else ...[
                      _MessageBody(message: message),
                      if (message.text.isNotEmpty &&
                          message.type != MessageType.taskRef &&
                          message.type != MessageType.link)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: _MessageText(
                            text: message.text,
                            highlightForMe: message.mentions.contains(me?.id),
                          ),
                        ),
                    ],
                    const SizedBox(height: 4),
                    if (showReceipt && channel != null)
                      _Receipt(channel: channel!, message: message),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTime(message.sentAt, locale),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (message.editedAt != null && !message.deleted) ...[
                          const SizedBox(width: 6),
                          Text(
                            t.edited,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: scheme.outline,
                                ),
                          ),
                        ],
                        if (showThread && message.threadCount > 0) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => GoRouter.of(context).go(
                                '/chat/${message.channelId}/thread/${message.id}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.forum_outlined,
                                    size: 12, color: scheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  t.repliesCount(message.threadCount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (message.reactions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 4,
                            children: [
                              for (final entry in message.reactions.entries)
                                InkWell(
                                  onTap: () => ref.read(chatRepositoryProvider).toggleReaction(
                                        message.channelId,
                                        message.id,
                                        entry.key,
                                        me?.id ?? '',
                                      ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: scheme.outlineVariant),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(reactionIcon(entry.key),
                                            size: 12, color: scheme.onSurface),
                                        const SizedBox(width: 4),
                                        Text('${entry.value.length}',
                                            style: const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lets the author rewrite a message; the bubble then shows "edited".
  Future<void> _editMessage(BuildContext context, WidgetRef ref) async {
    final t = tr(context);
    final controller = TextEditingController(text: message.text);
    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.editMessage),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 6,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(t.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated == null || updated.isEmpty || updated == message.text) return;
    await ref
        .read(chatRepositoryProvider)
        .editMessage(message.channelId, message.id, updated);
  }

  void _showActions(BuildContext context, WidgetRef ref, String? uid) {
    final t = tr(context);
    final router = GoRouter.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final code in kReactionCodes)
                  ActionChip(
                    avatar: Icon(reactionIcon(code), size: 16),
                    label: Text(reactionLabel(t, code)),
                    onPressed: () {
                      ref.read(chatRepositoryProvider).toggleReaction(
                          message.channelId, message.id, code, uid ?? '');
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            if (showThread && !message.deleted)
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: Text(t.replyInThread),
                onTap: () {
                  Navigator.of(context).pop();
                  router.go('/chat/${message.channelId}/thread/${message.id}');
                },
              ),
            if (isMine && !message.deleted && message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(t.edit),
                onTap: () {
                  Navigator.of(context).pop();
                  _editMessage(context, ref);
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(t.deleteMessage),
                onTap: () {
                  ref
                      .read(chatRepositoryProvider)
                      .deleteMessage(message.channelId, message.id);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// "Sent" / "Seen" / "Seen by N members", from channels/{id}.lastReadAt.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.channel, required this.message});

  final Channel channel;
  final Message message;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final scheme = Theme.of(context).colorScheme;
    final readers = seenBy(channel, message);
    final everyone = seenByAll(channel, message);

    final label = readers.isEmpty
        ? t.sent
        : channel.isDm || everyone
            ? t.seen
            : t.seenByCount(readers.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            readers.isEmpty ? Icons.check : Icons.done_all,
            size: 12,
            color: everyone ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: everyone ? scheme.primary : scheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _MessageBody extends ConsumerWidget {
  const _MessageBody({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    switch (message.type) {
      case MessageType.image:
        final a = message.attachments.first;
        final local = ref.watch(mediaRepositoryProvider).localBytes(a.url);
        if (local != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(local, width: 320, fit: BoxFit.cover),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            a.url,
            width: 320,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 320,
              height: 180,
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined),
            ),
          ),
        );
      case MessageType.file:
        final a = message.attachments.first;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(a.readableSize.isEmpty ? readableBytes(a.sizeBytes) : a.readableSize,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        );
      case MessageType.audio:
        final a = message.attachments.first;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline, size: 32),
            const SizedBox(width: 8),
            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                value: .0,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 8),
            Text(formatDuration(a.durationMs ?? 0),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        );
      case MessageType.link:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: BorderDirectional(
              start: BorderSide(color: scheme.primary, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.text.isNotEmpty) Text(message.text),
              Text(
                message.linkUrl ?? '',
                style: TextStyle(color: scheme.primary, decoration: TextDecoration.underline),
              ),
            ],
          ),
        );
      case MessageType.taskRef:
        final task = ref.watch(taskProvider(message.taskId ?? ''));
        if (task == null) return Text(message.text);
        return InkWell(
          onTap: () => GoRouter.of(context).go('/tasks/${task.id}'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16),
                    const SizedBox(width: 6),
                    Text(task.key,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(task.title),
                const SizedBox(height: 6),
                SizedBox(width: 220, child: ProgressBar(value: task.effectiveProgress, showLabel: true)),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Renders message text with "@mentions" highlighted, and tints the whole line
/// when the signed-in member is the one being mentioned.
class _MessageText extends ConsumerWidget {
  const _MessageText({required this.text, this.highlightForMe = false});

  final String text;
  final bool highlightForMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider).value ?? const <AppUser>[];
    final scheme = Theme.of(context).colorScheme;
    final segments = splitMentions(text, users);
    if (segments.length == 1 && !segments.first.isMention) return Text(text);

    return Container(
      padding: highlightForMe
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : EdgeInsets.zero,
      decoration: highlightForMe
          ? BoxDecoration(
              color: scheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            for (final segment in segments)
              TextSpan(
                text: segment.text,
                style: segment.isMention
                    ? TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
