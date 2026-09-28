import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../core/mentions.dart';
import '../../core/theme.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.channelId, this.showBackButton = true});

  final String channelId;
  final bool showBackButton;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
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
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({
    String? text,
    MessageType type = MessageType.text,
    List<Attachment> attachments = const [],
    String? taskId,
    String? linkUrl,
  }) async {
    final me = ref.read(currentUserProvider);
    final body = (text ?? _controller.text).trim();
    if (me == null) return;
    final mentions = parseMentions(body, ref.read(usersProvider).value ?? const []);
    if (body.isEmpty && attachments.isEmpty && taskId == null && linkUrl == null) return;
    _controller.clear();
    await ref.read(chatRepositoryProvider).sendMessage(
          Message(
            id: '',
            channelId: widget.channelId,
            senderId: me.id,
            sentAt: DateTime.now(),
            type: type,
            text: body,
            attachments: attachments,
            taskId: taskId,
            linkUrl: linkUrl,
            mentions: mentions,
          ),
        );
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
    final messages = ref.watch(messagesProvider(widget.channelId)).value ?? const <Message>[];
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
                channel.isDm
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
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _Composer(
            controller: _controller,
            onSend: () => _send(),
            onAttach: (type) => _attach(type),
            onMention: _pickMention,
          ),
        ],
      ),
    );
  }

  /// Inserts "@Name" at the caret; [parseMentions] turns it into a real
  /// mention (and a notification) when the message is sent.
  Future<void> _pickMention() async {
    final me = ref.read(currentUserProvider);
    final channels = ref.read(channelsProvider).value ?? const <Channel>[];
    final channel = channels.where((c) => c.id == widget.channelId).firstOrNull;
    final usersById = ref.read(usersByIdProvider);
    final candidates = (channel?.memberIds ?? const <String>[])
        .where((id) => id != me?.id)
        .map((id) => usersById[id])
        .whereType<AppUser>()
        .toList();
    if (candidates.isEmpty) return;

    final picked = await showModalBottomSheet<AppUser>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final u in candidates)
            ListTile(
              leading: UserAvatar(user: u, size: 34, showPresence: true),
              title: Text(u.displayName),
              subtitle: Text(u.title),
              onTap: () => Navigator.of(context).pop(u),
            ),
        ],
      ),
    );
    if (picked == null) return;

    final handle = picked.displayName.split(' ').first;
    final text = _controller.text;
    final selection = _controller.selection;
    final at = selection.isValid ? selection.start : text.length;
    final prefix = text.substring(0, at);
    final suffix = text.substring(at);
    final needsSpace = prefix.isNotEmpty && !prefix.endsWith(' ');
    final insert = '${needsSpace ? ' ' : ''}@$handle ';
    _controller.text = '$prefix$insert$suffix';
    _controller.selection =
        TextSelection.collapsed(offset: (prefix + insert).length);
  }

  Future<void> _attach(MessageType type) async {
    // In the mock build attachments are simulated; phase 2 wires image_picker /
    // file_picker + Firebase Storage here (see docs/PLAN.md §5).
    switch (type) {
      case MessageType.image:
        await _send(
          text: '',
          type: MessageType.image,
          attachments: [
            Attachment(
              url: 'https://picsum.photos/seed/${DateTime.now().millisecond}/800/520',
              name: 'photo.jpg',
              mime: 'image/jpeg',
              sizeBytes: 480000,
            ),
          ],
        );
        break;
      case MessageType.file:
        await _send(
          text: '',
          type: MessageType.file,
          attachments: const [
            Attachment(
              url: '#',
              name: 'ctg-document.pdf',
              mime: 'application/pdf',
              sizeBytes: 182000,
            ),
          ],
        );
        break;
      case MessageType.audio:
        await _send(
          text: '',
          type: MessageType.audio,
          attachments: const [
            Attachment(
              url: '#',
              name: 'voice-note.m4a',
              mime: 'audio/mp4',
              sizeBytes: 320000,
              durationMs: 34000,
            ),
          ],
        );
        break;
      case MessageType.link:
        await _send(text: 'https://ctg.ma', type: MessageType.link, linkUrl: 'https://ctg.ma');
        break;
      case MessageType.taskRef:
        final tasks = ref.read(tasksProvider).value ?? const <Task>[];
        if (!mounted || tasks.isEmpty) return;
        final picked = await showModalBottomSheet<Task>(
          context: context,
          showDragHandle: true,
          builder: (_) => ListView(
            shrinkWrap: true,
            children: [
              for (final task in tasks)
                ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.key),
                  onTap: () => Navigator.of(context).pop(task),
                ),
            ],
          ),
        );
        if (picked != null) {
          await _send(text: picked.key, type: MessageType.taskRef, taskId: picked.id);
        }
        break;
      default:
        break;
    }
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
  });

  final Message message;
  final AppUser? sender;
  final bool isMine;
  final bool grouped;

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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTime(message.sentAt, locale),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
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

  void _showActions(BuildContext context, WidgetRef ref, String? uid) {
    final t = tr(context);
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

class _MessageBody extends ConsumerWidget {
  const _MessageBody({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    switch (message.type) {
      case MessageType.image:
        final a = message.attachments.first;
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
                Text(a.readableSize, style: Theme.of(context).textTheme.labelSmall),
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

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onMention,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<MessageType> onAttach;
  final VoidCallback onMention;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PopupMenuButton<MessageType>(
              icon: const Icon(Icons.add_circle_outline),
              onSelected: onAttach,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: MessageType.image,
                  child: ListTile(leading: const Icon(Icons.image_outlined), title: Text(t.attachImage)),
                ),
                PopupMenuItem(
                  value: MessageType.file,
                  child: ListTile(
                      leading: const Icon(Icons.attach_file), title: Text(t.attachFile)),
                ),
                PopupMenuItem(
                  value: MessageType.audio,
                  child: ListTile(
                      leading: const Icon(Icons.mic_none), title: Text(t.attachAudio)),
                ),
                PopupMenuItem(
                  value: MessageType.link,
                  child: ListTile(
                      leading: const Icon(Icons.link), title: Text(t.attachLink)),
                ),
                PopupMenuItem(
                  value: MessageType.taskRef,
                  child: ListTile(
                      leading: const Icon(Icons.task_alt), title: Text(t.linkTask)),
                ),
              ],
            ),
            IconButton(
              tooltip: t.mentionSomeone,
              icon: const Icon(Icons.alternate_email),
              onPressed: onMention,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: t.messageHint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              tooltip: t.send,
            ),
          ],
        ),
      ),
    );
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
