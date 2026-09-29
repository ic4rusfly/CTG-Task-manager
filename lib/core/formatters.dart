import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

String formatDay(DateTime date, String locale) =>
    DateFormat.yMMMMd(locale).format(date);

String formatShortDay(DateTime date, String locale) =>
    DateFormat.MMMd(locale).format(date);

String formatTime(DateTime date, String locale) =>
    DateFormat.Hm(locale).format(date);

String formatDayTime(DateTime date, String locale) =>
    '${DateFormat.MMMd(locale).format(date)} · ${DateFormat.Hm(locale).format(date)}';

/// "now / 5m / 3h / 2d / 12 Mar"
String formatRelative(DateTime date, String locale, AppLocalizations t) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return t.justNow;
  if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return t.daysAgo(diff.inDays);
  return formatShortDay(date, locale);
}

String formatDuration(int ms) {
  final d = Duration(milliseconds: ms);
  final m = d.inMinutes.remainder(60).toString();
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
