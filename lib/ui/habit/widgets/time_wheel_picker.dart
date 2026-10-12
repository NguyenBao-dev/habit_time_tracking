import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/theme.dart';

class TimeWheelPicker extends StatefulWidget {
  const TimeWheelPicker({
    super.key,
    required this.hour24,
    required this.minute,
    required this.onChanged,
  });

  final int hour24;
  final int minute;
  final void Function(int hour24, int minute) onChanged;

  @override
  State<TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  static List<int> _minutes = new List<int>.generate(59, (i) => i + 1);
  static const double _itemExtent = 48;

  static final _hourLabels = [
    for (var h = 1; h <= 12; h++) h.toString().padLeft(2, '0'),
  ];
  static final _minuteLabels = [
    for (final m in _minutes) m.toString().padLeft(2, '0'),
  ];
  static const _periodLabels = ['AM', 'PM'];

  late int _hourIdx;
  late int _minuteIdx;
  late int _periodIdx;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;

  @override
  void initState() {
    super.initState();
    final h12 = widget.hour24 % 12 == 0 ? 12 : widget.hour24 % 12;
    _hourIdx = h12 - 1;
    _minuteIdx = (widget.minute / 15).round() % 4;
    _periodIdx = widget.hour24 >= 12 ? 1 : 0;

    _hourController = FixedExtentScrollController(initialItem: _hourIdx);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIdx);
    _periodController = FixedExtentScrollController(initialItem: _periodIdx);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _emit() {
    final h12 = _hourIdx + 1;
    final hour24 = (h12 % 12) + (_periodIdx == 1 ? 12 : 0);
    widget.onChanged(hour24, _minutes[_minuteIdx]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Wheel(
          controller: _hourController,
          labels: _hourLabels,
          selected: _hourIdx,
          width: 84,
          onSelected: (i) {
            setState(() => _hourIdx = i);
            _emit();
          },
        ),
        SizedBox(
          width: 28,
          child: Center(
            child: Text(':', style: theme.textTheme.headlineSmall),
          ),
        ),
        _Wheel(
          controller: _minuteController,
          labels: _minuteLabels,
          selected: _minuteIdx,
          width: 84,
          onSelected: (i) {
            setState(() => _minuteIdx = i);
            _emit();
          },
        ),
        const SizedBox(width: AppSpacing.md),
        _Wheel(
          controller: _periodController,
          labels: _periodLabels,
          selected: _periodIdx,
          width: 76,
          onSelected: (i) {
            setState(() => _periodIdx = i);
            _emit();
          },
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.labels,
    required this.selected,
    required this.width,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final List<String> labels;
  final int selected;
  final double width;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<HabitColors>()!;

    return SizedBox(
      width: width,
      height: _TimeWheelPickerState._itemExtent * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Highlight behind the centre row.
          Container(
            height: _TimeWheelPickerState._itemExtent - 4,
            decoration: BoxDecoration(
              color: colors.iconChipBackground,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _TimeWheelPickerState._itemExtent,
            diameterRatio: 4,
            perspective: 0.0015,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              // The looping delegate reports unbounded indexes.
              onSelected(index % labels.length);
            },
            childDelegate: ListWheelChildLoopingListDelegate(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Center(
                    child: Text(
                      labels[i],
                      style: i == selected
                          ? theme.textTheme.headlineSmall?.copyWith(
                        color: colors.iconChipForeground,
                      )
                          : theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}