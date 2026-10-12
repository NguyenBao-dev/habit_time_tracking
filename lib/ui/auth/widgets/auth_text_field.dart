import 'package:flutter/material.dart';

import '../../core/ui/theme.dart';

/// Labelled text field used on the auth screens. The label sits above the
/// field, as in the wireframe. Visuals come from the theme's
/// `InputDecorationTheme`.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.labelColor,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;
  final Color? labelColor;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: widget.labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _hidden,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          autocorrect: false,
          enableSuggestions: !widget.obscure,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.obscure
                ? IconButton(
              tooltip: _hidden ? 'Show password' : 'Hide password',
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            )
                : null,
          ),
        ),
      ],
    );
  }
}