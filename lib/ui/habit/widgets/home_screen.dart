import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth/view_models/auth_view_model.dart';
import '../../core/ui/theme.dart';
import '../data/habit.dart';
import '../data/habit_stats.dart';
import '../data/notification_service.dart';
import '../view_models/habit_view_model.dart';
import '../view_models/appearance_view_model.dart';
import 'add_habit_screen.dart';
import 'analytics_screen.dart';
import 'app_drawer.dart';
import 'habit_widgets.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authViewModel,
    required this.appearance,
  });

  final AuthViewModel authViewModel;
  final AppearanceViewModel appearance;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HabitViewModel _vm =
  HabitViewModel(username: widget.authViewModel.currentUser ?? '');
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Identifies the habit list (ids + names) the reminders were last built
  /// from. Null until the first sync after sign-in.
  String? _reminderSignature;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_syncReminders);
    _vm.load(); // notifies when done, which triggers the first sync
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  /// Keeps the scheduled reminders in step with the habit list: runs on
  /// sign-in/app start (re-reading the time zone too) and whenever a habit is
  /// added, renamed or deleted. Checking a habit off doesn't change the
  /// signature, so it doesn't reschedule anything.
  void _syncReminders() {
    if (!_vm.isLoaded) return;
    final habits = _vm.habits;
    final signature = habits.map((h) => '${h.id}:${h.name}').join('|');
    if (signature == _reminderSignature) return;
    _reminderSignature = signature;

    unawaited(NotificationService.instance.syncForUser(
      widget.authViewModel.currentUser ?? '',
      habits,
    ));
  }

  /// Reminders belong to the signed-in user, so stop them on log out.
  Future<void> _logout() async {
    await NotificationService.instance.cancelReminders();
    await widget.authViewModel.logout();
  }

  void _openAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AnalyticsScreen(viewModel: _vm)),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          authViewModel: widget.authViewModel,
          appearance: widget.appearance,
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          authViewModel: widget.authViewModel,
          habitViewModel: _vm,
        ),
      ),
    );
  }

  void _openAdd() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AddHabitScreen(viewModel: _vm)),
    );
  }

  void _openEdit(Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddHabitScreen(viewModel: _vm, habit: habit),
      ),
    );
  }

  /// Swipe right = update (opens the form), swipe left = delete (confirms).
  Future<bool> _confirmDismiss(Habit habit, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      _openEdit(habit);
      return false; // keep the row in place
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          '"${habit.name}" and its history will be removed. '
              'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _onDeleted(Habit habit) {
    _vm.delete(habit.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Deleted "${habit.name}"')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onSettings: _openSettings,
        onNotifications: _openNotifications,
        onLogout: _logout,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add habit',
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
        onPressed: _openAdd,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (!_vm.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    96, // room for the FAB
                  ),
                  children: [
                    _HeaderCard(
                      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Dashboard(viewModel: _vm, onTap: _openAnalytics),
                    const SizedBox(height: AppSpacing.md),
                    const SectionTitle('Habits'),
                    _HabitsCard(
                      habits: _vm.habits,
                      onToggle: _vm.toggleToday,
                      confirmDismiss: _confirmDismiss,
                      onDeleted: _onDeleted,
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

// --------------------------------------------------------------- Header

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Here's what's happening today.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Open menu',
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                onTap: onMenu,
                child: const IconChip(icon: Icons.menu_rounded, size: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Dashboard

/// The whole dashboard block (title, stats, recent activity) is one tap
/// target that opens Analytics.
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.viewModel, required this.onTap});

  final HabitViewModel viewModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = viewModel.habits;
    final activity = recentActivity(habits, limit: 2);

    return Semantics(
      button: true,
      label: 'Dashboard. Opens analytics.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              'Dashboard',
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total habits',
                    value: '${habits.length}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    label: 'Done today',
                    value: '${viewModel.doneToday}',
                    suffix: ' / ${habits.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm + 4),
                    if (activity.isEmpty)
                      Text(
                        'Nothing yet. Check off a habit to see it here.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      for (final item in activity)
                        Padding(
                          padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                          child: Row(
                            children: [
                              const IconChip(
                                icon: Icons.check_rounded,
                                size: 36,
                              ),
                              const SizedBox(width: AppSpacing.sm + 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.habit.name} completed',
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Text(
                                      timeAgo(item.time),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.suffix});

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text.rich(
              TextSpan(
                text: value,
                style: theme.textTheme.headlineMedium,
                children: [
                  if (suffix != null)
                    TextSpan(text: suffix, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- Habits

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({
    required this.habits,
    required this.onToggle,
    required this.confirmDismiss,
    required this.onDeleted,
  });

  final List<Habit> habits;
  final void Function(String id) onToggle;
  final Future<bool> Function(Habit habit, DismissDirection direction)
  confirmDismiss;
  final void Function(Habit habit) onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (habits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No habits yet. Tap + to add your first one.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias, // clips the swipe backgrounds
      child: Column(
        children: [
          for (var i = 0; i < habits.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Dismissible(
              key: ValueKey(habits[i].id),
              confirmDismiss: (direction) =>
                  confirmDismiss(habits[i], direction),
              onDismissed: (_) => onDeleted(habits[i]),
              background: const _SwipeBackground(
                color: AppColors.steelBlue,
                icon: Icons.edit_outlined,
                label: 'Update',
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: const _SwipeBackground(
                color: AppColors.error,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                alignment: Alignment.centerRight,
              ),
              child: _HabitRow(
                habit: habits[i],
                onToggle: () => onToggle(habits[i].id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.onToggle});

  final Habit habit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;
    final done = habit.isDoneOn(DateTime.now());

    return Container(
      // Opaque so the swipe backgrounds don't show through.
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          HabitAvatar(habit: habit),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const HabitSubtitle(),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: done ? 'Mark ${habit.name} not done' : 'Mark ${habit.name} done',
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: done
                      ? colors.positive
                      : colors.positive.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: done
                      ? theme.colorScheme.onPrimary
                      : colors.positive.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}