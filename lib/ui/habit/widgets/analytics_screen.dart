import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/ui/theme.dart';
import '../data/habit_stats.dart';
import '../view_models/habit_view_model.dart';
import 'habit_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.viewModel});

  final HabitViewModel viewModel;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  /// 0 = this week, -1 = last week.
  int _weekOffset = 0;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: BackButton(),
        ),
        title: const Text('Analytics'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final habits = widget.viewModel.habits;
            final stats = WeekStats.compute(habits, weekOffset: _weekOffset);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _MetricsRow(stats: stats),
                    const SizedBox(height: AppSpacing.md),
                    _WeeklyCard(
                      stats: stats,
                      weekOffset: _weekOffset,
                      onWeekChanged: (v) => setState(() => _weekOffset = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RecentActivityCard(
                      items: recentActivity(
                        habits,
                        limit: _showAll ? 50 : 3,
                      ),
                      showAll: _showAll,
                      onToggleAll: () => setState(() => _showAll = !_showAll),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RecordBanner(
                      message: recordMessage(habits),
                      values: WeekStats.compute(habits).daily,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Metrics

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.stats});

  final WeekStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;
    final delta = stats.delta;
    final deltaColor = delta >= 0 ? colors.positive : theme.colorScheme.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Progress',
            icon: Icons.trending_up_rounded,
            value: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${stats.percent}%',
                    style: theme.textTheme.headlineMedium),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${delta >= 0 ? '+' : ''}$delta%',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: deltaColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricCard(
            label: 'Completed',
            icon: Icons.check_circle_outline_rounded,
            chipBackground: theme.colorScheme.secondaryContainer,
            chipForeground: theme.colorScheme.onSecondaryContainer,
            value: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${stats.completed}',
                    style: theme.textTheme.headlineMedium),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'of ${stats.possible}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colors.positive),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.value,
    this.chipBackground,
    this.chipForeground,
  });

  final String label;
  final IconData icon;
  final Widget value;
  final Color? chipBackground;
  final Color? chipForeground;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                IconChip(
                  icon: icon,
                  size: 30,
                  background: chipBackground,
                  foreground: chipForeground,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            value,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- Weekly chart

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({
    required this.stats,
    required this.weekOffset,
    required this.onWeekChanged,
  });

  final WeekStats stats;
  final int weekOffset;
  final ValueChanged<int> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly progress',
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 2),
                      Text('Habit completion by day',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  initialValue: weekOffset,
                  onSelected: onWeekChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 0, child: Text('This week')),
                    PopupMenuItem(value: -1, child: Text('Last week')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 4,
                      vertical: AppSpacing.sm - 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.iconChipBackground,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekOffset == 0 ? 'This week' : 'Last week',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.iconChipForeground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: colors.iconChipForeground),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Row(
              children: [
                _LegendDot(color: colors.chartBar, label: 'Completed'),
                const SizedBox(width: AppSpacing.md),
                _LegendDot(color: colors.chartGoal, label: 'Goal'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _WeekChart(stats: stats),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Bars show habits completed per day; a day that hits the goal (every habit
/// done) is highlighted and gets a goal dot.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.stats});

  final WeekStats stats;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const double _maxBar = 150;

  bool _goalMet(int i) => stats.goal > 0 && stats.daily[i] >= stats.goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;

    return Column(
      children: [
        Container(
          height: _maxBar + 20,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_goalMet(i)) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.chartGoal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 22,
                        height: stats.goal == 0
                            ? 6
                            : math.max(
                          6,
                          _maxBar *
                              (stats.daily[i] / stats.goal)
                                  .clamp(0.0, 1.0),
                        ),
                        decoration: BoxDecoration(
                          color: _goalMet(i)
                              ? colors.chartBarHighlight
                              : colors.chartBar,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _goalMet(i)
                        ? colors.chartBarHighlight
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                    _goalMet(i) ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------ Recent activity

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.items,
    required this.showAll,
    required this.onToggleAll,
  });

  final List<HabitActivity> items;
  final bool showAll;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Recent activity',
                      style: theme.textTheme.headlineSmall),
                ),
                TextButton(
                  onPressed: onToggleAll,
                  child: Text(showAll ? 'Show less' : 'See all'),
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Nothing yet. Check off a habit to see it here.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: AppSpacing.lg),
                _ActivityRow(item: items[i]),
              ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final HabitActivity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HabitAvatar(habit: item.habit),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.habit.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              HabitSubtitle(extra: timeAgo(item.time)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Done',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- Banner

class _RecordBanner extends StatelessWidget {
  const _RecordBanner({required this.message, required this.values});

  final String message;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.bannerAccent,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.deepBlue),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best week this month',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.bannerForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.bannerForeground.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 56,
            height: 28,
            child: CustomPaint(
              painter: _SparklinePainter(values, colors.bannerAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = math.max(1, values.reduce(math.max));
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - 2 - (size.height - 4) * values[i] / maxV;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => true;
}