import 'package:flutter/material.dart';

import '../../core/ui/theme.dart';
import '../view_models/auth_view_model.dart';
import 'auth_text_field.dart';
import 'habit_logo.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final error = await widget.viewModel.login(
      username: _username.text,
      password: _password.text,
    );
    if (!mounted) return;

    // On success the auth gate swaps this screen out, so only errors need UI.
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(viewModel: widget.viewModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) {
                      final busy = widget.viewModel.isBusy;
                      return Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(child: HabitLogo()),
                              const SizedBox(height: AppSpacing.xl + AppSpacing.md),
                              Text('Welcome back',
                                  style: theme.textTheme.displaySmall),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Sign in to continue to your account.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AuthTextField(
                                label: 'Username',
                                hint: 'Enter your username',
                                controller: _username,
                                enabled: !busy,
                                labelColor: labelColor,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                validator: (v) =>
                                    AuthValidators.required(v, 'username'),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AuthTextField(
                                label: 'Password',
                                hint: 'Enter your password',
                                controller: _password,
                                enabled: !busy,
                                obscure: true,
                                labelColor: labelColor,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: _submit,
                                validator: (v) =>
                                    AuthValidators.required(v, 'password'),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: busy ? null : _submit,
                                child: busy
                                    ? const _ButtonSpinner()
                                    : const Text('Log in'),
                              ),
                              const SizedBox(height: AppSpacing.md - 4),
                              OutlinedButton(
                                onPressed: busy ? null : _openRegister,
                                child: const Text('Register'),
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
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
}