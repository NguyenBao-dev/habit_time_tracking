import 'package:flutter/material.dart';

import '../../core/ui/theme.dart';
import '../view_models/auth_view_model.dart';
import 'auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final error = await widget.viewModel.register(
      username: _username.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // The user is now signed in: drop back to the auth gate, which shows
    // the signed-in experience.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl + AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  final busy = widget.viewModel.isBusy;
                  return Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Join us today',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AuthTextField(
                            label: 'Username',
                            hint: 'Enter username',
                            controller: _username,
                            enabled: !busy,
                            labelColor: labelColor,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newUsername],
                            validator: AuthValidators.username,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AuthTextField(
                            label: 'Email',
                            hint: 'name@example.com',
                            controller: _email,
                            enabled: !busy,
                            labelColor: labelColor,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: AuthValidators.email,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AuthTextField(
                            label: 'Password',
                            hint: '••••••••',
                            controller: _password,
                            enabled: !busy,
                            obscure: true,
                            labelColor: labelColor,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onSubmitted: _submit,
                            validator: AuthValidators.newPassword,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: busy ? null : _submit,
                            child: busy
                                ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                                : const Text('Register'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed:
                                busy ? null : () => Navigator.pop(context),
                                child: const Text('Log in'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}