import 'package:flutter/material.dart';
import '../../core/ui/theme.dart';
import '../data/habit.dart';
import '../view_models/habit_view_model.dart';
import 'habit_widgets.dart';

/// Creates a habit, or edits one when [habit] is provided (name, icon and
/// color are pre-filled).
class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key, required this.viewModel, this.habit});

  final HabitViewModel viewModel;
  final Habit? habit;

  bool get isEditing => habit != null;

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
  TextEditingController(text: widget.habit?.name ?? '');
  late String _iconKey = widget.habit?.iconKey ?? HabitIcons.defaultKey;
  late Color _color = widget.habit?.color ?? AppColors.habitColors.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);

    if (widget.isEditing) {
      await widget.viewModel.update(
        widget.habit!.id,
        name: _name.text,
        iconKey: _iconKey,
        color: _color,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Habit updated')));
    } else {
      await widget.viewModel.add(
        name: _name.text,
        iconKey: _iconKey,
        color: _color,
      );
      if (!mounted) return;
      // Stay on the screen so the new habit appears under "Existing habits".
      _name.clear();
      setState(() {
        _iconKey = HabitIcons.defaultKey;
        _color = AppColors.habitColors.first;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Habit added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = theme.textTheme.labelLarge;

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: BackButton(),
        ),
        title: Text(widget.isEditing ? 'Edit Habit' : 'Add Habit'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.md + 4),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Habit name', style: label),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        maxLength: 40,
                        style: theme.textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'Enter habit name',
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a habit name'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Icon picker', style: label),
                const SizedBox(height: AppSpacing.sm + 4),
                Wrap(
                  spacing: AppSpacing.sm + 4,
                  runSpacing: AppSpacing.sm + 4,
                  children: [
                    for (final entry in HabitIcons.all.entries)
                      _IconOption(
                        icon: entry.value,
                        selected: entry.key == _iconKey,
                        onTap: () => setState(() => _iconKey = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Color picker', style: label),
                const SizedBox(height: AppSpacing.sm + 4),
                Wrap(
                  spacing: AppSpacing.sm + 4,
                  runSpacing: AppSpacing.sm + 4,
                  children: [
                    for (final c in AppColors.habitColors)
                      _ColorOption(
                        color: c,
                        selected: c.toARGB32() == _color.toARGB32(),
                        onTap: () => setState(() => _color = c),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.isEditing ? 'Save changes' : 'Add habit'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Existing habits', style: label),
                const SizedBox(height: AppSpacing.sm + 4),
                ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) =>
                      _ExistingHabits(habits: widget.viewModel.habits),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : Theme.of(context)
                .extension<HabitColors>()!
                .iconChipBackground,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Icon(
            icon,
            color: selected
                ? scheme.onPrimary
                : Theme.of(context)
                .extension<HabitColors>()!
                .iconChipForeground,
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
              color: Theme.of(context).colorScheme.onSurface,
              width: 2,
            )
                : null,
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _ExistingHabits extends StatelessWidget {
  const _ExistingHabits({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (habits.isEmpty) {
      return Text('No habits yet.', style: theme.textTheme.bodyMedium);
    }

    return Column(
      children: [
        for (final habit in habits)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
                child: Row(
                  children: [
                    HabitAvatar(habit: habit, size: 40),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Text(
                        habit.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      'Daily',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}