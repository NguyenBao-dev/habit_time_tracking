import 'package:flutter/material.dart';

import '../../auth/view_models/auth_view_model.dart';
import '../../core/ui/theme.dart';
import '../data/habit.dart';
import '../data/notification_service.dart';
import '../data/settings_storage.dart';
import '../view_models/habit_view_model.dart';
import '../view_models/notification_view_model.dart';
import 'habit_widgets.dart';
import 'time_wheel_picker.dart';

/// Reminder settings: master switch, which habits, what time, how often.
/// Edits are a draft until "Save notification settings" is tapped.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.authViewModel,
    required this.habitViewModel,
  });

  final AuthViewModel authViewModel;
  final HabitViewModel habitViewModel;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationViewModel _vm = NotificationViewModel(
    username: widget.authViewModel.currentUser ?? '',
  );

  bool _ready = false;
  bool _saving = false;

  // Draft values.
  bool _enabled = true;
  Set<String> _selected = {};
  int _hour = 7;
  int _minute = 30;
  RepeatRule _repeat = RepeatRule.everyDay;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _vm.load();
    if (!mounted) return;
    final s = _vm.settings;
    final existing = widget.habitViewModel.habits.map((h) => h.id).toSet();
    setState(() {
      _enabled = s.enabled;
      // Drop habits that were deleted since the last save.
      _selected = s.habitIds.where(existing.contains).toSet();
      _hour = s.hour;
      _minute = s.minute;
      _repeat = s.repeat;
      _ready = true;
    });
  }

  void _toggleHabit(String id, bool selected) {
    setState(() {
      _selected = {..._selected};
      if (selected) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  void _toggleAll(bool selectAll) {
    final ids = widget.habitViewModel.habits.map((h) => h.id);
    setState(() => _selected = selectAll ? ids.toSet() : <String>{});
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_enabled && _selected.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Choose at least one habit.')),
        );
      return;
    }

    setState(() => _saving = true);

    final settings = NotificationSettings(
      enabled: _enabled,
      habitIds: _selected,
      hour: _hour,
      minute: _minute,
      repeat: _repeat,
    );
    final service = NotificationService.instance;

    var message = 'Notification settings saved';
    if (_enabled) {
      // Triggered by the user tapping Save, which is the right moment to
      // show the OS permission prompt.
      final granted = await service.requestPermission();
      if (!granted) {
        message = 'Saved, but notifications are blocked for this app. '
            'Turn them on in system settings.';
      }
    }

    await _vm.save(settings);
    // Replaces whatever was scheduled before (or cancels it if switched off).
    await service.sync(settings, widget.habitViewModel.habits);

    if (!mounted) return;
    setState(() => _saving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// "Local time · Asia/Ho_Chi_Minh", as in the wireframe. Falls back to the
  /// abbreviation and UTC offset if the IANA name isn't available.
  String get _timeZoneLabel {
    final iana = NotificationService.instance.timeZoneName;
    if (iana != null) return 'Local time · $iana';

    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final h = offset.inHours.abs().toString().padLeft(2, '0');
    final m = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return 'Local time · ${now.timeZoneName} (UTC$sign$h:$m)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: BackButton(),
        ),
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: !_ready
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListenableBuilder(
              listenable: widget.habitViewModel,
              builder: (context, _) {
                final habits = widget.habitViewModel.habits;
                final selectedCount =
                    habits.where((h) => _selected.contains(h.id)).length;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _RemindersCard(
                      enabled: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Everything below is dimmed and inert while
                    // reminders are switched off.
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _enabled ? 1 : 0.5,
                      child: IgnorePointer(
                        ignoring: !_enabled,
                        child: Column(
                          children: [
                            _ChooseHabitsCard(
                              habits: habits,
                              selected: _selected,
                              selectedCount: selectedCount,
                              onToggle: _toggleHabit,
                              onToggleAll: _toggleAll,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _TimeCard(
                              hour: _hour,
                              minute: _minute,
                              timeZoneLabel: _timeZoneLabel,
                              repeat: _repeat,
                              saving: _saving,
                              onTimeChanged: (h, m) => setState(() {
                                _hour = h;
                                _minute = m;
                              }),
                              onRepeatChanged: (r) =>
                                  setState(() => _repeat = r),
                              onSave: _save,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // When off, the dimmed card's button is inert, so
                    // offer a way to persist "off" as well.
                    if (!_enabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: const Text('Save notification settings'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Reminders

class _RemindersCard extends StatelessWidget {
  const _RemindersCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            IconChip(
              icon: Icons.notifications_active_outlined,
              size: 48,
              background: colors.positive.withValues(alpha: 0.14),
              foreground: colors.positive,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Habit reminders', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Receive a gentle nudge at your chosen time.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------- Choose habits

class _ChooseHabitsCard extends StatelessWidget {
  const _ChooseHabitsCard({
    required this.habits,
    required this.selected,
    required this.selectedCount,
    required this.onToggle,
    required this.onToggleAll,
  });

  final List<Habit> habits;
  final Set<String> selected;
  final int selectedCount;
  final void Function(String id, bool selected) onToggle;
  final ValueChanged<bool> onToggleAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = habits.isNotEmpty && selectedCount == habits.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                      Text('Choose habits',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '$selectedCount of ${habits.length} selected',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (habits.isNotEmpty)
                  TextButton(
                    onPressed: () => onToggleAll(!allSelected),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(allSelected ? 'Clear all' : 'Select all'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (habits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'No habits yet. Add a habit to set a reminder.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              for (var i = 0; i < habits.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _HabitCheckRow(
                  habit: habits[i],
                  checked: selected.contains(habits[i].id),
                  onChanged: (v) => onToggle(habits[i].id, v),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _HabitCheckRow extends StatelessWidget {
  const _HabitCheckRow({
    required this.habit,
    required this.checked,
    required this.onChanged,
  });

  final Habit habit;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
        child: Row(
          children: [
            HabitAvatar(habit: habit, size: 40),
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
            Checkbox(
              value: checked,
              onChanged: (v) => onChanged(v ?? false),
              // Wireframe uses the primary colour for the checked box.
              fillColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                    ? scheme.primary
                    : Colors.transparent,
              ),
              checkColor: scheme.onPrimary,
              visualDensity: VisualDensity.comfortable,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Time

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.hour,
    required this.minute,
    required this.timeZoneLabel,
    required this.repeat,
    required this.saving,
    required this.onTimeChanged,
    required this.onRepeatChanged,
    required this.onSave,
  });

  final int hour;
  final int minute;
  final String timeZoneLabel;
  final RepeatRule repeat;
  final bool saving;
  final void Function(int hour24, int minute) onTimeChanged;
  final ValueChanged<RepeatRule> onRepeatChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                      Text('Notification time',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('Applies to selected habits',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _TimeChip(label: formatTime(hour, minute)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TimeWheelPicker(
                hour24: hour,
                minute: minute,
                onChanged: onTimeChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(timeZoneLabel, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.repeat_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Repeat',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<RepeatRule>(
                  initialValue: repeat,
                  onSelected: onRepeatChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  itemBuilder: (context) => [
                    for (final rule in RepeatRule.values)
                      PopupMenuItem(value: rule, child: Text(rule.label)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          repeat.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            ElevatedButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
                  : const Text('Save notification settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: colors.positive.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: colors.positive),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.positive,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}