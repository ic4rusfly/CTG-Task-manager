import 'package:ctg_hub/data/mock/mock_db.dart';
import 'package:ctg_hub/data/mock/mock_repositories.dart';
import 'package:ctg_hub/domain/models/models.dart';
import 'package:ctg_hub/features/tasks/task_card.dart';
import 'package:ctg_hub/l10n/app_localizations.dart';
import 'package:ctg_hub/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget with the localisation delegates and a signed-in member.
Widget harness(Widget child, {Locale locale = const Locale('en'), MockDb? db}) {
  final database = db ?? MockDb();
  final auth = MockAuthRepository(database);
  auth.signInAs('u1');

  return ProviderScope(
    overrides: [
      mockDbProvider.overrideWithValue(database),
      authRepositoryProvider.overrideWithValue(auth),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('task card shows the key, title and progress', (tester) async {
    final db = MockDb();
    final task = db.tasks.firstWhere((t) => t.id == 'k1');

    await tester.pumpWidget(harness(TaskCard(task: task), db: db));
    await tester.pumpAndSettle();

    expect(find.text('CTG-101'), findsOneWidget);
    expect(find.text('Finalize CTG Day agenda'), findsOneWidget);
    expect(find.text('${task.effectiveProgress}%'), findsOneWidget);
  });

  testWidgets('Arabic renders right to left', (tester) async {
    final db = MockDb();
    await tester.pumpWidget(harness(
      Builder(
        builder: (context) => Text(AppLocalizations.of(context).tasks),
      ),
      locale: const Locale('ar'),
      db: db,
    ));
    await tester.pumpAndSettle();

    expect(find.text('المهام'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('المهام'))), TextDirection.rtl);
  });

  testWidgets('French labels are used when the locale is fr', (tester) async {
    await tester.pumpWidget(harness(
      Builder(builder: (context) => Text(AppLocalizations.of(context).newTask)),
      locale: const Locale('fr'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle tâche'), findsOneWidget);
  });
}
