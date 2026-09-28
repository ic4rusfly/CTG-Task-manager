import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/env.dart';
import 'data/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Date and number formatting for en, fr and ar.
  await initializeDateFormatting();

  // Default build: in-memory mock repositories, no backend required.
  // --dart-define=BACKEND=firebase swaps in Firestore/Auth (see lib/core/env.dart).
  final overrides = Env.useFirebase ? await initializeFirebase() : const <Override>[];

  runApp(ProviderScope(overrides: overrides, child: const CtgApp()));
}
