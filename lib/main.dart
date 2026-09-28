import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Date/number formatting for en, fr and ar.
  await initializeDateFormatting();

  // Phase 1 — Firebase bootstrap goes here:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // and the repository providers in lib/providers/providers.dart are overridden
  // with their Firestore implementations.

  runApp(const ProviderScope(child: CtgApp()));
}
