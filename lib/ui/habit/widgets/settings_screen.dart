import 'package:flutter/material.dart';

import '../../auth/view_models/auth_view_model.dart';
import '../../core/ui/theme.dart';
import '../data/country_repository.dart';
import '../data/settings_storage.dart';
import '../view_models/appearance_view_model.dart';
import '../view_models/settings_view_model.dart';
import 'country_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.authViewModel,
    required this.appearance,
  });

  final AuthViewModel authViewModel;
  final AppearanceViewModel appearance;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsViewModel _vm = SettingsViewModel(
    username: widget.authViewModel.currentUser ?? '',
  );
  final _countryKey = GlobalKey();

  bool _ready = false;
  bool _saving = false;

  // Draft values.
  String _fullName = '';
  String _email = '';
  String? _newPassword;
  Country? _country;
  bool _dark = false;

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
    final p = _vm.profile;
    setState(() {
      _fullName = p.fullName;
      _email = widget.authViewModel.currentEmail ?? '';
      _country = p.countryName == null
          ? null
          : Country(name: p.countryName!, code: p.countryCode ?? '');
      _dark = widget.appearance.isDark(context);
      _ready = true;
    });
  }

  // ----------------------------------------------------------- Editing

  Future<String?> _showSheet(Widget sheet) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => sheet,
    );
  }

  Future<void> _editName() async {
    final value = await _showSheet(_TextEditSheet(
      title: 'Full name',
      label: 'Full name',
      hint: 'Enter your full name',
      initial: _fullName,
      capitalization: TextCapitalization.words,
      keyboardType: TextInputType.name,
      autofillHints: const [AutofillHints.name],
      validator: (v) => AuthValidators.required(v, 'name'),
    ));
    if (value != null) setState(() => _fullName = value);
  }

  Future<void> _editEmail() async {
    final value = await _showSheet(_TextEditSheet(
      title: 'Email address',
      label: 'Email address',
      hint: 'name@example.com',
      initial: _email,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: AuthValidators.email,
    ));
    if (value != null) setState(() => _email = value);
  }

  Future<void> _editPassword() async {
    final value = await _showSheet(
      _PasswordSheet(verify: widget.authViewModel.verifyPassword),
    );
    if (value != null) setState(() => _newPassword = value);
  }

  Future<void> _pickCountry() async {
    FocusScope.of(context).unfocus();
    final picked = await showCountryPicker(
      context,
      anchorKey: _countryKey,
      selectedCode: _country?.code,
      selectedName: _country?.name,
    );
    if (picked != null) setState(() => _country = picked);
  }

  // ------------------------------------------------------------- Save

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    String? error;
    final emailChanged =
        _email.trim().toLowerCase() !=
            (widget.authViewModel.currentEmail ?? '').trim().toLowerCase();

    if (emailChanged || _newPassword != null) {
      error = await widget.authViewModel.updateAccount(
        email: emailChanged ? _email : null,
        newPassword: _newPassword,
      );
    }

    if (error == null) {
      await _vm.save(ProfileSettings(
        fullName: _fullName,
        countryName: _country?.name,
        countryCode: _country?.code,
      ));
      await widget.appearance.setDarkMode(_dark);
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _newPassword = null;
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'Settings saved')));
  }

  // ------------------------------------------------------------ Build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: BackButton(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: !_ready
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _SectionCard(
                  title: 'Profile',
                  children: [
                    _FieldTile(
                      label: 'Full name',
                      value: _fullName.isEmpty
                          ? 'Add your name'
                          : _fullName,
                      muted: _fullName.isEmpty,
                      onTap: _editName,
                    ),
                    _FieldTile(
                      label: 'Email address',
                      value: _email,
                      onTap: _editEmail,
                    ),
                    _FieldTile(
                      label: 'Password',
                      value: _newPassword == null
                          ? '••••••••••••'
                          : '•' * _newPassword!.length,
                      onTap: _editPassword,
                    ),
                    _FieldTile(
                      key: _countryKey,
                      label: 'Country',
                      value: _country?.name ?? 'Select country',
                      muted: _country == null,
                      onTap: _pickCountry,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Preferences',
                  children: [
                    _FieldTile(
                      label: 'Appearance',
                      value: 'Dark Mode',
                      onTap: () => setState(() => _dark = !_dark),
                      trailing: Switch(
                        value: _dark,
                        onChanged: (v) => setState(() => _dark = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Pieces

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm + 4),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm + 4),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Tinted row with a small caps label above the value (Full name, Email...).
class _FieldTile extends StatelessWidget {
  const _FieldTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
    this.muted = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: muted
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.onSurfaceVariant
                        : AppColors.steelBlue,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- Edit sheets

/// Bottom sheet with one text field. Pops with the trimmed value.
class _TextEditSheet extends StatefulWidget {
  const _TextEditSheet({
    required this.title,
    required this.label,
    required this.hint,
    required this.initial,
    required this.validator,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final String title;
  final String label;
  final String hint;
  final String initial;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;

  @override
  State<_TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends State<_TextEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
  TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.capitalization,
              autofillHints: widget.autofillHints,
              textInputAction: TextInputAction.done,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(hintText: widget.hint),
              validator: widget.validator,
              onFieldSubmitted: (_) => _done(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: _done, child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}

/// Asks for the current password, then the new one. Pops with the new
/// password; nothing is written until the user taps Save on the screen.
class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({required this.verify});

  final Future<bool> Function(String password) verify;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNext = true;
  bool _checking = false;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _checking = true);
    final ok = await widget.verify(_current.text);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _checking = false;
        _currentError = 'Incorrect password';
      });
      return;
    }
    Navigator.of(context).pop(_next.text);
  }

  Widget _toggle(bool hidden, VoidCallback onPressed) => IconButton(
    tooltip: hidden ? 'Show password' : 'Hide password',
    style: IconButton.styleFrom(backgroundColor: Colors.transparent),
    icon: Icon(
      hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    onPressed: onPressed,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
    theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change password', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Text('Current password', style: label),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _current,
              autofocus: true,
              obscureText: _hideCurrent,
              enabled: !_checking,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodyLarge,
              onChanged: (_) {
                if (_currentError != null) setState(() => _currentError = null);
              },
              decoration: InputDecoration(
                hintText: 'Enter current password',
                errorText: _currentError,
                suffixIcon: _toggle(
                  _hideCurrent,
                      () => setState(() => _hideCurrent = !_hideCurrent),
                ),
              ),
              validator: (v) => AuthValidators.required(v, 'current password'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('New password', style: label),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _next,
              obscureText: _hideNext,
              enabled: !_checking,
              textInputAction: TextInputAction.done,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                suffixIcon: _toggle(
                  _hideNext,
                      () => setState(() => _hideNext = !_hideNext),
                ),
              ),
              validator: AuthValidators.newPassword,
              onFieldSubmitted: (_) => _done(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _checking ? null : _done,
              child: _checking
                  ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
                  : const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}