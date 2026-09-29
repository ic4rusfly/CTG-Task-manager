import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'chat_composer.dart';
import 'chat_screen.dart';

/// One message and everything said in reply to it.
class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.channelId, required this.rootId});

  final String channelId;
  final String rootId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _scroll = ScrollController();

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
    final channel =
        channels.where((c) => c.id == widget.channelId).toList();
    final root = ref.watch(
      messageProvider((channelId: widget.channelId, messageId: widget.rootId)),
    );
    final replies = ref
            .watch(threadProvider(
                (channelId: widget.channelId, rootId: widget.rootId)))
            .value ??
        const <Message>[];

    final subtitle = channel.isEmpty
        ? ''
        : channel.first.isDm
            ? (usersById[channel.first.peerOf(me?.id ?? '')]?.displayName ?? '')
            : '# ${channel.first.name}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: t.close,
          onPressed: () => GoRouter.of(context).go('/chat/${widget.channelId}'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.thread, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: root == null
                ? EmptyState(icon: Icons.forum_outlined, message: t.messageDeleted)
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    children: [
                      MessageBubble(
                        message: root,
                        sender: usersById[root.senderId],
                        isMine: root.senderId == me?.id,
                        showThread: false,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                t.repliesCount(replies.length),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      for (var i = 0; i < replies.length; i++)
                        MessageBubble(
                          message: replies[i],
                          sender: usersById[replies[i].senderId],
                          isMine: replies[i].senderId == me?.id,
                          grouped: i > 0 &&
                              replies[i - 1].senderId == replies[i].senderId &&
                              replies[i]
                                      .sentAt
                                      .difference(replies[i - 1].sentAt)
                                      .inMinutes <
                                  5,
                          showThread: false,
                        ),
                    ],
                  ),
          ),
          ChatComposer(
            channelId: widget.channelId,
            replyToId: widget.rootId,
            hintText: t.threadReplyHint,
            onSent: _scrollToEnd,
          ),
        ],
      ),
    );
  }
}
