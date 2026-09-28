import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/models/models.dart';
import '../l10n/app_localizations.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 40, this.showPresence = false});

  final AppUser? user;
  final double size;
  final bool showPresence;

  @override
  Widget build(BuildContext context) {
    final color = CtgColors.avatarColor(user?.id ?? '?');
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: Text(
        user?.initials ?? '?',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * .38,
        ),
      ),
    );
    if (!showPresence) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        PositionedDirectional(
          end: -1,
          bottom: -1,
          child: Container(
            width: size * .3,
            height: size * .3,
            decoration: BoxDecoration(
              color: (user?.online ?? false) ? CtgColors.greenSoft : CtgColors.greyLight,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.users, this.size = 26, this.max = 4});

  final List<AppUser> users;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = users.take(max).toList();
    final extra = users.length - shown.length;
    return SizedBox(
      height: size,
      width: shown.isEmpty ? 0 : size + (shown.length - 1) * size * .68 + (extra > 0 ? size * .7 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * size * .68,
              child: UserAvatar(user: shown[i], size: size),
            ),
          if (extra > 0)
            PositionedDirectional(
              start: shown.length * size * .68,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text('+$extra', style: TextStyle(fontSize: size * .34)),
              ),
            ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, this.icon, this.dense = true});

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 3 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 15, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 6, this.showLabel = false});

  final int value;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = value >= 100
        ? CtgColors.greenSoft
        : value >= 50
            ? CtgColors.green
            : CtgColors.chocolate;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: height,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text('$value%', style: Theme.of(context).textTheme.labelMedium),
        ],
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A rounded surface used as the card for tasks, events and members.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.onTap, this.padding, this.borderColor});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor ?? scheme.outlineVariant.withOpacity(.7)),
          ),
          child: child,
        ),
      ),
    );
  }
}

AppLocalizations tr(BuildContext context) => AppLocalizations.of(context);

/// Icon used for a named message reaction.
IconData reactionIcon(String code) => switch (code) {
      'ack' => Icons.thumb_up_alt_outlined,
      'agree' => Icons.check_outlined,
      'watching' => Icons.visibility_outlined,
      'blocker' => Icons.report_gmailerrorred_outlined,
      _ => Icons.task_alt_outlined,
    };
