import 'package:flutter/widgets.dart';

/// Breakpoints shared by every adaptive screen.
class Breakpoints {
  static const compact = 700.0;
  static const expanded = 1100.0;
}

bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < Breakpoints.compact;

bool isExpanded(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
