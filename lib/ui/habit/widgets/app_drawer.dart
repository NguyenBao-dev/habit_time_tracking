import 'package:flutter/material.dart';
import '../../core/ui/theme.dart';
import 'habit_widgets.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.onSettings,
    required this.onNotifications,
    required this.onLogout,
  });

  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;

  void _close(BuildContext context) => Navigator.of(context).pop();

  void _go(BuildContext context, VoidCallback action) {
    _close(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: 290,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    onTap: () => _close(context),
                    child: Semantics(
                      button: true,
                      label: 'Close menu',
                      child: IconChip(icon: Icons.close_rounded, size: 44),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Text('Menu', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DrawerItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: true,
                onTap: () => _close(context),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _DrawerItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => _go(context, onSettings),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _DrawerItem(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => _go(context, onNotifications),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Log out',
                onTap: () => _go(context, onLogout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        side: selected
            ? BorderSide.none
            : BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              IconChip(
                icon: icon,
                size: 36,
                // The selected row gets a "lifted" chip, as in the wireframe.
                background: selected ? cardColor : null,
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}