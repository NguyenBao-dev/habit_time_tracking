import 'package:flutter/material.dart';

import '../../core/ui/theme.dart';

/// "HABIT" wordmark. Deep blue in light mode, lime in dark mode.
class HabitLogo extends StatelessWidget {
  const HabitLogo({super.key, this.fontSize = 56});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<HabitColors>()!.logo;
    return Text(
      'HABIT',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        height: 1,
        color: color,
      ),
    );
  }
}