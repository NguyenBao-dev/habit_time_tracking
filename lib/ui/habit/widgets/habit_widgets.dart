import 'package:flutter/material.dart';
import '../../core/ui/theme.dart';
import '../data/habit.dart';

/// Round avatar showing a habit's icon on its chosen color.
class HabitAvatar extends StatelessWidget {
  const HabitAvatar({super.key, required this.habit, this.size = 44});

  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: habit.color, shape: BoxShape.circle),
      child: Icon(habit.icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Rounded-square tinted icon container (menu button, stat chips, ...).
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.size = 40,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HabitColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? colors.iconChipBackground,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: foreground ?? colors.iconChipForeground,
      ),
    );
  }
}

/// Section heading such as "Dashboard" or "Habits".
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "🕒 Daily" style subtitle used under habit names.
class HabitSubtitle extends StatelessWidget {
  const HabitSubtitle({super.key, this.extra});

  final String? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.schedule_rounded,
            size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            extra == null ? 'Daily' : 'Daily · $extra',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}