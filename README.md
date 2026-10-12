# Habit Time Tracking

A Flutter mobile app for building daily habits. Users register, add habits, check them off each day, review weekly analytics, and get scheduled reminders. This is a Mobile App Development capstone project.

## Features

- **Authentication:** register and log in with a username, email and password. Passwords are stored as salted SHA-256 hashes, and the session is restored on launch.
- **Home dashboard:** total habits, done today, recent activity, and a habit list with one-tap check-off.
- **Habit management:** add habits with a name, icon and color. Swipe right to edit and swipe left to delete (with confirmation).
- **Analytics:** weekly completion percentage, comparison to the previous week, a Mon-Sun bar chart, recent activity, and a "Best week this month" banner.
- **Settings:** full name, email, password change (verifies the current password), country, and Dark Mode.
- **Notifications:** daily, weekday or weekend reminders at a chosen time for selected habits.
- **Country picker:** loads countries from the REST Countries v5 API and falls back to a bundled offline list.
- **Theming:** light and dark themes using the Inter font and the project palette.

User stories are in `Habit_Time_Tracking_User_Stories.md`.

## Tech stack

| Area | Package |
|------|---------|
| Framework | Flutter (Dart SDK `^3.8.1`) |
| Local storage | `shared_preferences` |
| Password hashing | `crypto` |
| HTTP | `http` |
| Reminders | `flutter_local_notifications`, `flutter_timezone`, `timezone` |
| State | `ChangeNotifier` view models with `ListenableBuilder` |

## Project structure

```
lib/
├── main.dart                      # App entry, theme mode, auth gate
└── ui/
    ├── core/ui/theme.dart         # Colors, spacing, radii, light/dark themes
    ├── auth/
    │   ├── view_models/           # AuthViewModel, validators
    │   └── widgets/               # Login, Register, AuthTextField, HabitLogo
    └── habit/
        ├── data/                  # Habit model, storage, stats, countries,
        │                          # settings storage, notification service
        ├── view_models/           # Habit, Settings, Notification, Appearance
        └── widgets/               # Home, Add/Edit Habit, Analytics, Settings,
                                   # Notifications, Drawer, pickers
```

Adjust the folders above if your layout differs.

## Prerequisites

- Flutter SDK with Dart `^3.8.1` (run `flutter --version` to check)
- Android Studio and/or Xcode, plus a device or emulator
- A free REST Countries API key: https://restcountries.com/sign-up
- Inter font files in `assets/fonts/` (declared in `pubspec.yaml`):
  `Inter-Regular.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf`, `Inter-ExtraBold.ttf`, `Inter-Black.ttf`

## Getting started

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the app
flutter run \
  --dart-define=RESTCOUNTRIES_API_KEY=your_api_key_here \
  --android-skip-build-dependency-validation
```

Do not commit your real API key. Keep it in your terminal history, IDE run configuration, or a CI secret.

### Run flags

| Flag | Purpose |
|------|---------|
| `--dart-define=RESTCOUNTRIES_API_KEY=<key>` | Supplies the REST Countries API key at build time. The app reads it with `String.fromEnvironment`. If it is missing or the request fails, the country picker shows the bundled offline list and a **Retry** button. |
| `--android-skip-build-dependency-validation` | Tells Flutter to skip its Android build dependency validation step (Gradle/AGP/Kotlin/JDK version checks). Use it only if that validation blocks an otherwise working Android build. |

### Building

Pass the same flags when building:

```bash
flutter build apk \
  --dart-define=RESTCOUNTRIES_API_KEY=your_api_key_here \
  --android-skip-build-dependency-validation
```

### Android Studio / VS Code

Add the flags under **Run > Edit Configurations > Additional run args** (Android Studio) or `args` in `.vscode/launch.json`:

```json
{
  "name": "habit_time_tracking",
  "request": "launch",
  "type": "dart",
  "args": [
    "--dart-define=RESTCOUNTRIES_API_KEY=your_api_key_here",
    "--android-skip-build-dependency-validation"
  ]
}
```

## Notifications setup

- Reminders are supported on **Android, iOS and macOS**. On web and desktop the notification calls do nothing.
- The permission prompt appears when the user taps **Save notification settings** with reminders on, not at launch.
- On Android 12+, the user may be sent to the system "Alarms & reminders" page to allow exact alarms. If declined, reminders still fire with inexact timing.
- Make sure the Android manifest declares the notification, exact alarm and boot permissions required by `flutter_local_notifications`, and that its Gradle setup matches the plugin's current installation guide.
- Use the in-code `showTestNotification()` helper to verify permissions and the channel without waiting for the scheduled time.

## Data and privacy

All data is stored locally on the device with `shared_preferences`, keyed per user (`habits.{username}`, `profile.{username}`, `notifications.{username}`). The only network call is the optional country list request. Nothing else leaves the device.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Country picker says "Showing offline list." | Check that `RESTCOUNTRIES_API_KEY` is set, the key is valid, and the device is online, then tap **Retry**. The debug console logs the exact cause. |
| Text looks different from the design | Confirm the Inter font files exist in `assets/fonts/` and run `flutter clean && flutter pub get`. |
| Android build fails on dependency validation | Run with `--android-skip-build-dependency-validation`, or update Gradle/AGP/JDK to the versions Flutter expects. |
| No reminders appear | Allow notifications for the app in system settings, select at least one habit, and save with reminders on. |
| Wrong reminder time | Check the "Local time · ..." caption on the Notifications screen to confirm the detected time zone. |

## License

Capstone project for educational use.
