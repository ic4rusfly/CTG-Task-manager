import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Search across every message the signed-in member can see.
class MessageSearchScreen extends ConsumerStatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  ConsumerState<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends ConsumerState<MessageSearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(messageSearchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final usersById = ref.watch(usersByIdProvider);
    final query = ref.watch(messageSearchQueryProvider);
    final search = ref.watch(messageSearchProvider);
    final hits = search.value ?? const <MessageHit>[];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.searchMessages,
            isDense: true,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => ref.read(messageSearchQueryProvider.notifier).state = v,
        ),
      ),
      body: query.trim().length < 2
          ? EmptyState(icon: Icons.search, message: t.searchMessages)
          : search.isLoading && hits.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : search.hasError
                  ? EmptyState(icon: Icons.error_outline, message: t.errorBody)
                  : hits.isEmpty
              ? EmptyState(icon: Icons.search_off, message: t.noResults)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: hits.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
                        child: Text(t.resultsCount(hits.length),
                            style: Theme.of(context).textTheme.labelSmall),
                      );
                    }
                    final hit = hits[i - 1];
                    final channel = hit.channel;
                    final peerId = channel.peerOf(ref.read(currentUserProvider)?.id ?? '');
                    final channelLabel = channel.isDm
                        ? (usersById[peerId]?.displayName ?? '')
                        : '# ${channel.name}';
                    return SoftCard(
                      onTap: () => context.go('/chat/${channel.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              UserAvatar(user: usersById[hit.message.senderId], size: 22),
                              const SizedBox(width: 8),
                              Text(usersById[hit.message.senderId]?.displayName ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.inChannel(channelLabel),
                                  style: Theme.of(context).textTheme.labelSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(formatRelative(hit.message.sentAt, locale, t),
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hit.message.text.isEmpty
                                ? hit.message.attachments.map((a) => a.name).join(', ')
                                : hit.message.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
