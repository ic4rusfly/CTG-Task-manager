import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/attachment_picker.dart';
import '../../core/mentions.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// The message composer, shared by the channel view and the thread view.
///
/// It owns everything a draft needs: text, mentions, attachment picking and
/// the upload to Cloud Storage (or to the in-memory store in the mock build).
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({
    super.key,
    required this.channelId,
    this.replyToId,
    this.hintText,
    this.onSent,
  });

  final String channelId;

  /// Set on the thread view: every message sent becomes a reply to this root.
  final String? replyToId;
  final String? hintText;
  final VoidCallback? onSent;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final _controller = TextEditingController();

  double? _progress;
  String? _uploadName;
  String? _error;
  Future<void> Function()? _retry;

  @override
  void dispose() {
    _controller.dispose();
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
    if (body.isEmpty && attachments.isEmpty && taskId == null && linkUrl == null) {
      return;
    }
    final mentions = parseMentions(body, ref.read(usersProvider).value ?? const []);
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
            replyToId: widget.replyToId,
            mentions: mentions,
          ),
        );
    widget.onSent?.call();
  }

  /// Picks a file, uploads it with a progress bar, then posts the message.
  Future<void> _pickAndUpload(PickKind kind, MessageType type) async {
    final picked = await pickAttachment(kind);
    if (picked == null || !mounted) return;
    await _upload(picked, type);
  }

  Future<void> _upload(PickedAttachment picked, MessageType type) async {
    final t = tr(context);
    setState(() {
      _uploadName = picked.name;
      _progress = 0;
      _error = null;
      _retry = null;
    });
    try {
      final attachment = await ref.read(mediaRepositoryProvider).upload(
            folder: 'chat/${widget.channelId}',
            fileName: picked.name,
            mime: picked.mime,
            bytes: picked.bytes,
            onProgress: (value) {
              if (mounted) setState(() => _progress = value);
            },
          );
      if (!mounted) return;
      setState(() {
        _progress = null;
        _uploadName = null;
      });
      await _send(text: '', type: type, attachments: [attachment]);
    } on MediaTooLargeException {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _uploadName = null;
        _error = t.fileTooLarge(readableBytes(MediaRepository.maxBytes));
        _retry = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _uploadName = null;
        _error = t.uploadFailed;
        _retry = () => _upload(picked, type);
      });
    }
  }

  Future<void> _attach(MessageType type) async {
    switch (type) {
      case MessageType.image:
        await _pickAndUpload(PickKind.image, MessageType.image);
      case MessageType.audio:
        await _pickAndUpload(PickKind.audio, MessageType.audio);
      case MessageType.file:
        await _pickAndUpload(PickKind.any, MessageType.file);
      case MessageType.link:
        await _promptLink();
      case MessageType.taskRef:
        await _pickTask();
      default:
        break;
    }
  }

  Future<void> _promptLink() async {
    final t = tr(context);
    final controller = TextEditingController(text: 'https://');
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.attachLink),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://ctg.ma'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(t.send),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty || url == 'https://') return;
    await _send(text: url, type: MessageType.link, linkUrl: url);
  }

  Future<void> _pickTask() async {
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
  }

  /// Inserts "@Name" at the caret; [parseMentions] turns it into a real
  /// mention (and a notification) when the message is sent.
  Future<void> _pickMention() async {
    final me = ref.read(currentUserProvider);
    final channels = ref.read(channelsProvider).value ?? const <Channel>[];
    final channel = channels.where((c) => c.id == widget.channelId).toList();
    final usersById = ref.read(usersByIdProvider);
    final candidates = (channel.isEmpty ? const <String>[] : channel.first.memberIds)
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
    _controller.selection = TextSelection.collapsed(offset: (prefix + insert).length);
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_progress != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.uploading}  ${_uploadName ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(value: _progress),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: scheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ),
                    if (_retry != null)
                      TextButton(
                        onPressed: () {
                          final retry = _retry!;
                          setState(() => _error = null);
                          retry();
                        },
                        child: Text(t.retry),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: t.close,
                      onPressed: () => setState(() {
                        _error = null;
                        _retry = null;
                      }),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<MessageType>(
                  icon: const Icon(Icons.add_circle_outline),
                  onSelected: _attach,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: MessageType.image,
                      child: ListTile(
                          leading: const Icon(Icons.image_outlined),
                          title: Text(t.attachImage)),
                    ),
                    PopupMenuItem(
                      value: MessageType.file,
                      child: ListTile(
                          leading: const Icon(Icons.attach_file),
                          title: Text(t.attachFile)),
                    ),
                    PopupMenuItem(
                      value: MessageType.audio,
                      child: ListTile(
                          leading: const Icon(Icons.mic_none),
                          title: Text(t.attachAudio)),
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
                  onPressed: _pickMention,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? t.messageHint,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: () => _send(),
                  icon: const Icon(Icons.send),
                  tooltip: t.send,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
