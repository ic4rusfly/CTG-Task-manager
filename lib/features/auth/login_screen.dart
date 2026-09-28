import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/mock/mock_repositories.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'yasmine@ctg.ma');
  final _password = TextEditingController(text: 'demo1234');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
    } catch (_) {
      if (mounted) setState(() => _error = tr(context).unknownUser);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final users = ref.watch(usersProvider).value ?? const [];
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CtgColors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('CTG',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    const SizedBox(width: 12),
                    Text(t.appName, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: t.email,
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: t.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: CtgColors.maroon)),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _busy ? null : _signIn,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.signIn),
                ),
                const SizedBox(height: 26),
                Text(t.demoSignInHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final u in users)
                      ActionChip(
                        avatar: UserAvatar(user: u, size: 22),
                        label: Text('${u.displayName.split(' ').first} · ${roleLabel(t, u.role)}'),
                        onPressed: () async {
                          final repo = ref.read(authRepositoryProvider);
                          if (repo is MockAuthRepository) await repo.signInAs(u.id);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('EN')),
                    ButtonSegment(value: 'fr', label: Text('FR')),
                    ButtonSegment(value: 'ar', label: Text('AR')),
                  ],
                  selected: {locale.languageCode},
                  onSelectionChanged: (s) => ref
                      .read(localeOverrideProvider.notifier)
                      .state = Locale(s.first),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
