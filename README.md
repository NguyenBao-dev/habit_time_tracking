# Habit Time Tracking

Habit Time Tracking is a Flutter application designed to help users build consistent daily routines. Users can create and manage habits, track daily completion, review their progress through weekly analytics, and configure reminders.

## Features

- **User authentication:** Register and log in with a username, email, and password, with session persistence.
- **Habit dashboard:** View total habits, daily completion progress, and recent activity.
- **Habit management:** Create habits with custom names, icons, and colors; edit or delete existing habits.
- **Daily tracking:** Mark habits as completed and keep a record of completion activity.
- **Weekly analytics:** Review completion rates, compare weekly progress, and explore daily statistics.
- **Profile and settings:** Manage account details, country preferences, and application appearance.
- **Reminders:** Schedule notifications for daily, weekday, or weekend routines.
- **Light and dark themes:** Switch between themes with a consistent interface.

## Technology Stack

| Area | Technologies |
|------|-------------|
| Framework | Flutter |
| Language | Dart |
| Local storage | shared_preferences |
| Password hashing | crypto |
| HTTP requests | http |
| Notifications | flutter_local_notifications, flutter_timezone, timezone |
| State management | ChangeNotifier, ListenableBuilder |
| Typography | Inter |

## Requirements

- Flutter SDK
- Dart SDK `^3.8.1`
- Android Studio or Visual Studio Code
- Android emulator or a physical device
- Inter font files included in `assets/fonts/`
- REST Countries API key for the online country list (the application includes an offline fallback)

## Getting Started

Clone the repository:

```bash
git clone https://github.com/NguyenBao-dev/habit_time_tracking.git
cd habit_time_tracking
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run --dart-define=RESTCOUNTRIES_API_KEY=your_api_key_here
```

If Android build dependency validation blocks the build in your environment, you can also use:

```bash
flutter run \
  --dart-define=RESTCOUNTRIES_API_KEY=your_api_key_here \
  --android-skip-build-dependency-validation
```

Build an Android APK:

```bash
flutter build apk \
  --dart-define=RESTCOUNTRIES_API_KEY=your_api_key_here \
  --android-skip-build-dependency-validation
```

Do not commit a real API key to the repository. Supply it through your local run configuration or a secure CI secret.

## Project Structure

```text
habit_time_tracking/
├── android/                # Android platform configuration
├── assets/
│   ├── fonts/              # Inter font assets
│   └── screenshots/        # Application screenshots
├── ios/                    # iOS platform configuration
├── lib/
│   ├── main.dart           # Application entry point
│   └── ui/
│       ├── core/           # Shared theme and UI components
│       ├── auth/           # Authentication screens and logic
│       └── habit/          # Habit features, data and view models
├── test/                   # Tests
├── web/                    # Web platform configuration
├── pubspec.yaml            # Flutter dependencies and assets
└── README.md
```

## Screenshots

Application screenshots are available in the [`assets/screenshots`](https://github.com/NguyenBao-dev/habit_time_tracking/tree/master/assets/screenshots) directory.

## Data and Privacy

Habit records, account information, profile settings, and reminder preferences are stored locally on the device using `shared_preferences`. Passwords are stored as salted SHA-256 hashes. The country picker can request country data from the REST Countries API and falls back to a bundled offline list when the request is unavailable.

## License

This project is for educational and development purposes.
