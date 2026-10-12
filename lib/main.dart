import 'package:flutter/material.dart';
import 'package:habit_time_tracking/ui/core/ui/theme.dart';

import 'ui/auth/view_models/auth_view_model.dart';
import 'ui/auth/widgets/login_screen.dart';
import 'ui/habit/data/notification_service.dart';
import 'ui/habit/view_models/appearance_view_model.dart';
import 'ui/habit/widgets/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sets up the notification plugin and the device time zone.
  await NotificationService.instance.init();
  runApp(const HabitApp());
}

class HabitApp extends StatefulWidget {
  const HabitApp({super.key});

  @override
  State<HabitApp> createState() => _HabitAppState();
}

class _HabitAppState extends State<HabitApp> {
  final _authViewModel = AuthViewModel();
  final _appearance = AppearanceViewModel();

  @override
  void initState() {
    super.initState();
    _authViewModel.initialize();
    _appearance.load();
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds the app when Settings > Dark Mode is saved.
    return ListenableBuilder(
      listenable: _appearance,
      builder: (context, _) => MaterialApp(
        title: 'Habit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _appearance.themeMode, // system until the user chooses
        home: _AuthGate(
          viewModel: _authViewModel,
          appearance: _appearance,
        ),
      ),
    );
  }
}

/// Shows the login screen until a user is signed in, then the Home screen.
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.viewModel, required this.appearance});

  final AuthViewModel viewModel;
  final AppearanceViewModel appearance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.isInitialized) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (viewModel.isAuthenticated) {
          // Keyed by user so switching accounts gets a fresh habit list.
          return HomeScreen(
            key: ValueKey(viewModel.currentUser),
            authViewModel: viewModel,
            appearance: appearance,
          );
        }
        return LoginScreen(viewModel: viewModel);
      },
    );
  }
}