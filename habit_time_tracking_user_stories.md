# Habit Time Tracking App: User Stories

**Project:** habit_time_tracking (Flutter, Mobile App Development Capstone)
**Source:** the provided Dart code and the Habit wireframe. Screen names, labels and behaviors come from the code.

**Story format:** *As a [user], I want [goal], so that [benefit].*
Acceptance criteria are verifiable statements, with the implementing file in parentheses.

> **Assumption:** "Detail Screen" is interpreted as the **Analytics** screen (reached by tapping the Dashboard on Home). Add/Edit Habit is covered under Home.

**Design tokens**
- Light: Deep Blue `#05668D` primary, Ice White `#EBF2FA` background, Green `#679436` success.
- Dark: Deep Blue background, Steel Blue `#427AA1` cards, Lime `#A5BE00` accent and primary buttons.
- Font Inter. Spacing 4/8/16/24/32. Radii: card 20, field/button 14, chip 12.
- Content is centered, max width 440 (auth) or 560 (app screens).

---

## Epic 1: Login Screen (`login_screen.dart`, `auth_text_field.dart`, `habit_logo.dart`)

| ID | User Story |
|----|-----------|
| LOGIN-1 | As a returning user, I want to see the HABIT logo and a "Welcome back" heading, so that I know I'm on the right screen. |
| LOGIN-2 | As a returning user, I want to enter my username and password, so that I can sign in. |
| LOGIN-3 | As a user, I want to show or hide my password, so that I can check what I typed. |
| LOGIN-4 | As a user, I want clear messages for empty fields or wrong credentials, so that I can fix problems quickly. |
| LOGIN-5 | As a user, I want the app to keep me signed in, so that I don't log in on every launch. |
| LOGIN-6 | As a new user, I want a Register button, so that I can create an account. |
| LOGIN-7 | As a user, I want the screen to follow light/dark mode, so that it matches my device and preference. |

**Acceptance criteria**
- **LOGIN-1:** The "HABIT" wordmark (size 56, weight 900) is centered, deep blue in light mode and lime in dark. Below it: "Welcome back" and "Sign in to continue to your account."
- **LOGIN-2:** Labelled fields (label above input): **Username** ("Enter your username") and **Password** ("Enter your password"). A full-width primary **Log in** button (height 54). "Done" on the keyboard submits. OS autofill hints are set. On success the auth gate swaps in Home. Username matching is case-insensitive; the password is checked against a salted SHA-256 hash.
- **LOGIN-3:** Eye icon with tooltips "Show password" / "Hide password"; obscured by default.
- **LOGIN-4:** Empty fields show "Please enter your username/password". Wrong credentials show a snackbar "Incorrect username or password." Unexpected errors show "Something went wrong. Please try again." The keyboard dismisses on submit and on drag.
- **LOGIN-5:** A spinner shows while the saved session is checked. A valid session goes to Home; a session for a deleted account is cleared and Login is shown.
- **LOGIN-6:** A secondary (outlined) **Register** button opens Registration.
- **LOGIN-7:** While signing in, fields and buttons are disabled and Log in shows a spinner. All styling comes from the theme in both modes.

---

## Epic 2: Registration Screen (`register_screen.dart`, `auth_view_model.dart`)

| ID | User Story |
|----|-----------|
| REG-1 | As a new user, I want a "Create Account / Join us today" screen, so that I know I'm signing up. |
| REG-2 | As a new user, I want to enter a username, email and password, so that I can create an account. |
| REG-3 | As a new user, I want my inputs validated, so that I know what's wrong before submitting. |
| REG-4 | As a new user, I want to be told if my username or email is taken, so that I can choose another. |
| REG-5 | As a new user, I want to be signed in automatically, so that I can start right away. |
| REG-6 | As an existing user, I want a "Log in" link, so that I can go back to sign in. |

**Acceptance criteria**
- **REG-2:** Fields: **Username** ("Enter username"), **Email** ("name@example.com", email keyboard), **Password** ("••••••••", show/hide). A full-width **Register** button with a spinner while busy; inputs disabled while busy. Autofill hints for new username, email and password.
- **REG-3:** Username is required, at least 3 characters, letters/numbers/"."/"_" only. Email is required and must be valid ("Enter a valid email address"). Password is required, at least 6 characters.
- **REG-4:** Duplicate username: "That username is already taken." Duplicate email: "An account with that email already exists." Usernames are compared case-insensitively.
- **REG-5:** The user is saved with a random salt and hashed password (no plain text). The session is saved and the screen pops to the auth gate, which shows Home.
- **REG-6:** "Already have an account?" followed by an underlined **Log in** link that returns to Login.

---

## Epic 3: Home Screen (`home_screen.dart`, `habit_widgets.dart`, `add_habit_screen.dart`, `app_drawer.dart`)

| ID | User Story |
|----|-----------|
| HOME-1 | As a user, I want a welcome header with a menu button, so that I can orient myself and open the menu. |
| HOME-2 | As a user, I want to see total habits and how many I finished today, so that I see daily progress at a glance. |
| HOME-3 | As a user, I want to see my latest check-offs, so that I get a quick sense of recent activity. |
| HOME-4 | As a user, I want to see all my habits in a list, so that I can work through them during the day. |
| HOME-5 | As a user, I want to tap a button to mark a habit done or undo it, so that I can track today. |
| HOME-6 | As a user, I want to add a habit with a name, icon and color, so that I can personalize my tracking. |
| HOME-7 | As a user, I want to swipe right to edit a habit, so that I can change its name, icon or color. |
| HOME-8 | As a user, I want to swipe left to delete a habit with a confirmation, so that I don't delete one by accident. |
| HOME-9 | As a new user, I want a helpful empty state, so that I know what to do first. |

**Acceptance criteria**
- **HOME-1:** A card shows "Welcome back", "Here's what's happening today.", and a 44 px menu icon chip that opens the drawer.
- **HOME-2:** The Dashboard has two stat cards: **Total habits** (e.g. `5`) and **Done today** (e.g. `3 / 5`). The whole Dashboard block (title, stats, recent activity) is tappable and opens Analytics, with a chevron as the cue.
- **HOME-3:** The latest 2 completions show a check chip, "{Habit} completed", and a relative time ("Just now", "5 min ago", "2 hours ago", "Yesterday", "N days ago"). Empty: "Nothing yet. Check off a habit to see it here."
- **HOME-4/5:** Each row has a colored circular avatar with the habit icon, the name, and a "Daily" subtitle with a clock icon. A rounded-square check button is dimmed when not done and solid green when done (180 ms animation), with screen-reader labels. Tapping toggles today's completion and records the time.
- **HOME-6:** A circular FAB (tooltip "Add habit") opens **Add Habit**: **Habit name** (required, max 40), **Icon picker** (star, moon, drop, book, pulse, wind), **Color picker** (6 swatches, selected shows a check). **Add habit** saves, resets the form, stays on screen, shows "Habit added", and lists the habit under **Existing habits**. Empty name: "Please enter a habit name".
- **HOME-7:** Swipe right shows a steel-blue "Update" background and opens the form titled **Edit Habit**, pre-filled. **Save changes** returns to Home with "Habit updated". The row stays in place.
- **HOME-8:** Swipe left shows a red "Delete" background and a **Delete habit?** dialog (history removed, can't be undone) with Cancel and Delete. Confirming shows `Deleted "{name}"`.
- **HOME-9:** "No habits yet. Tap + to add your first one."

---

## Epic 4: Detail Screen: Analytics (`analytics_screen.dart`, `habit_stats.dart`)

| ID | User Story |
|----|-----------|
| DET-1 | As a user, I want to open detailed analytics from the Dashboard, so that I can see progress beyond today. |
| DET-2 | As a user, I want my weekly completion % compared to the previous week, so that I know if I'm improving. |
| DET-3 | As a user, I want completions out of the possible total, so that I understand my consistency. |
| DET-4 | As a user, I want a Mon–Sun bar chart, so that I can see which days I do well. |
| DET-5 | As a user, I want to switch between this week and last week, so that I can review the past. |
| DET-6 | As a user, I want days where I finish every habit highlighted, so that I feel rewarded. |
| DET-7 | As a user, I want to expand my recent activity, so that I can review what I did and when. |
| DET-8 | As a user, I want a "Best week this month" banner, so that I stay motivated. |

**Acceptance criteria**
- **DET-2/3:** **Progress** card shows `percent%` and a delta vs. the previous week over the same number of days (green if ≥ 0, red if negative). **Completed** card shows `N of M`. Percent = completed ÷ (habits × elapsed days), rounded; 0 with no habits. The current week counts only up to today.
- **DET-4/5/6:** "Weekly progress" / "Habit completion by day", with **Completed** and **Goal** legend dots. Seven animated bars (M T W T F S S) scale to the habit count. A day with every habit done turns green, gets a lime goal dot and a bold label. A dropdown chip switches **This week** / **Last week**.
- **DET-7:** Shows 3 items (avatar, name, "Daily · {time ago}", green **Done** pill). **See all** expands to 50 and becomes **Show less**. Same empty state as Home.
- **DET-8:** A rounded banner (deep blue in light, steel blue in dark) with a lime icon, "Best week this month", a message, and a sparkline of this week's daily counts. Messages: "Add a habit to start tracking your weeks." / "Check off a habit to get your week going." / "You're on a record week. Keep it up!" / "You're N completion(s) away from a new record."
- A back button in the app bar returns to Home.

---

## Epic 5: Persistent Data (`auth_storage.dart`, `habit_storage.dart`, `settings_storage.dart`, `appearance_view_model.dart`)

| ID | User Story |
|----|-----------|
| DATA-1 | As a user, I want my account saved on my device, so that I can log in later. |
| DATA-2 | As a user, I want my session remembered, so that I stay signed in between launches. |
| DATA-3 | As a user, I want habits and completion history saved, so that I never lose progress. |
| DATA-4 | As a user, I want my profile and reminder settings saved, so that they persist. |
| DATA-5 | As a user, I want my dark mode choice remembered, so that the app looks right on every launch. |
| DATA-6 | As a user sharing a device, I want each account's data separate, so that I only see my own. |
| DATA-7 | As a user, I want the app to survive damaged data, so that a bad record never blocks me. |

**Acceptance criteria**
- **DATA-1:** `shared_preferences` key `auth.users` stores username, email, random salt, and SHA-256 of `salt:password`.
- **DATA-2:** `auth.session` is written on login/registration and removed on logout.
- **DATA-3:** `habits.{username}` stores JSON (id, name, iconKey, colorValue, completions as `yyyy-MM-dd → epoch ms`). The UI refreshes first, then saves. Add, edit, delete and toggle all persist.
- **DATA-4:** `profile.{username}` (full name, country name/code) and `notifications.{username}` (enabled, habit ids, hour, minute, repeat).
- **DATA-5:** `settings.darkMode`; follows the system until the user chooses; also applies on Login.
- **DATA-6:** All keys include the lowercase username; Home is keyed by user so switching accounts loads a fresh list.
- **DATA-7:** Corrupt JSON is caught and defaults are returned.

---

## Epic 6: External API Integration (`country_repository.dart`, `country_fallback.dart`, `country_picker.dart`)

| ID | User Story |
|----|-----------|
| API-1 | As a user, I want to pick my country from a complete, current list, so that my profile is accurate. |
| API-2 | As a user, I want the list to open instantly after the first load, so that the picker feels fast. |
| API-3 | As a user, I want the picker to work offline or if the request fails, so that I'm never blocked. |
| API-4 | As a user, I want to know when I'm seeing the offline list and be able to retry, so that I can get live data. |
| API-5 | As a user, I want to search and see popular countries first, so that I can find mine fast. |
| API-6 | As a developer, I want the API key supplied at build time, so that it isn't committed to source control. |

**Acceptance criteria**
- **API-1:** REST Countries v5 (`names.common`, `codes.alpha_2`), pages of 100 (max 10 pages), `Authorization: Bearer` header, 15 s timeout, sorted A–Z.
- **API-2:** Cached in memory in a shared repository for the app's lifetime.
- **API-3:** On a missing key, timeout, HTTP error or bad response, the cause is logged and the bundled offline ISO list is returned. `fetch` never throws; the fallback isn't cached.
- **API-4:** Panel shows "Showing offline list." with **Retry**. Errors show a Wi-Fi-off icon with "Try again".
- **API-5:** "Search country" filters by name, with a clear button and "No countries found." Empty search lists US, CA, MX, GB, AU, DE first, then A–Z.
- **API-6:** `--dart-define=RESTCOUNTRIES_API_KEY=...`; without it the offline list is used.

---

## Epic 7: Settings Menu / Drawer (`app_drawer.dart`, `home_screen.dart`)

| ID | User Story |
|----|-----------|
| MENU-1 | As a user, I want to open a side menu from Home, so that I can reach Settings, Notifications and Log out. |
| MENU-2 | As a user, I want clearly labelled, iconned menu items, so that navigation is easy. |
| MENU-3 | As a user, I want to close the menu with a close button, so that I can return to Home. |
| MENU-4 | As a user, I want to log out from the menu, so that I can protect my account or switch users. |

**Acceptance criteria**
- **MENU-1:** The header menu chip opens a 290 px drawer in the card color.
- **MENU-2:** Title **Menu**. Items: Home (selected, highlighted, lifted icon chip), Settings, Notifications, Log out. Unselected items have an outlined rounded border and bold labels.
- **MENU-3:** A close chip (labelled "Close menu") at top left dismisses the drawer; tapping Home also closes it.
- **MENU-4:** Settings and Notifications close the drawer then open their screens. Log out cancels scheduled reminders, clears the session and returns to Login.

---

## Epic 8: Settings Screen (`settings_screen.dart`, `settings_view_model.dart`, `appearance_view_model.dart`)

| ID | User Story |
|----|-----------|
| SET-1 | As a user, I want Profile and Preferences sections, so that I manage my account in one place. |
| SET-2 | As a user, I want to edit my full name, so that the app reflects who I am. |
| SET-3 | As a user, I want to change my email, so that my account stays current. |
| SET-4 | As a user, I want to change my password after confirming the current one, so that my account stays secure. |
| SET-5 | As a user, I want to select my country, so that my profile is complete. |
| SET-6 | As a user, I want to toggle Dark Mode, so that I can use the app comfortably in any lighting. |
| SET-7 | As a user, I want changes applied only when I tap Save, so that I can review first. |

**Acceptance criteria**
- **SET-1:** Back button, title **Settings**. **Profile** card with four tinted rows (Full name, Email address, Password, Country): small-caps label, value, chevron. **Preferences** has an **Appearance** row with a **Dark Mode** switch (tapping the row also toggles).
- **SET-2:** Bottom sheet "Full name" with a field and **Done**; required ("Please enter your name"). Empty shows "Add your name" muted.
- **SET-3:** "Email address" sheet validates format; saving rejects duplicates ("An account with that email already exists.").
- **SET-4:** "Change password" sheet: **Current password** ("Incorrect password" if wrong) and **New password** ("At least 6 characters"), both with show/hide. The row shows masked dots; the new password gets a fresh salt on save.
- **SET-5:** The **Country** row opens the searchable popup anchored to it (above or below depending on space); empty shows "Select country".
- **SET-6:** The switch is a draft until Save; saving applies the theme app-wide.
- **SET-7:** **Save** shows a spinner, then a snackbar "Settings saved" or the error.

---

## Epic 9: Notifications (`notifications_screen.dart`, `notification_service.dart`, `time_wheel_picker.dart`, `notification_view_model.dart`)

| ID | User Story |
|----|-----------|
| NOTIF-1 | As a user, I want to turn reminders on or off, so that I control nudges. |
| NOTIF-2 | As a user, I want to choose which habits I'm reminded about, so that reminders stay relevant. |
| NOTIF-3 | As a user, I want to set the reminder time with a wheel picker, so that it fits my routine. |
| NOTIF-4 | As a user, I want reminders every day, on weekdays or on weekends, so that they match my schedule. |
| NOTIF-5 | As a user, I want to see my time zone, so that I know the time is local. |
| NOTIF-6 | As a user, I want to be asked for permission when I save, so that I'm not prompted too early. |
| NOTIF-7 | As a user, I want reminders to stay in sync with my habits and login state, so that they're accurate. |
| NOTIF-8 | As a user, I want one clear reminder, so that I'm not flooded with duplicates. |

**Acceptance criteria**
- **NOTIF-1:** **Habit reminders** card ("Receive a gentle nudge at your chosen time.") with a bell chip and switch. When off, the rest is dimmed (50%) and inert, and a separate **Save notification settings** button saves the "off" state.
- **NOTIF-2:** **Choose habits** shows "{n} of {total} selected", **Select all / Clear all**, and a row per habit (avatar, name, "Daily", checkbox). No habits: "No habits yet. Add a habit to set a reminder." Saving with none chosen: "Choose at least one habit." Deleted habits are dropped.
- **NOTIF-3:** **Notification time** ("Applies to selected habits") shows a chip (e.g. "7:30 AM") and a three-wheel hour / minute / AM-PM picker with a highlighted center row, looping scroll and haptics. Default 7:30 AM.
- **NOTIF-4:** **Repeat** drop-down: Every day, Weekdays, Weekends.
- **NOTIF-5:** Caption "Local time · Asia/Ho_Chi_Minh", with a UTC-offset fallback.
- **NOTIF-6:** Save requests OS permission (plus exact-alarm permission on Android 12+). If blocked: "Saved, but notifications are blocked for this app. Turn them on in system settings." Otherwise: "Notification settings saved."
- **NOTIF-7:** Reminders reschedule on sign-in, app start, and when a habit is added, renamed or deleted (not on check-off), and are cancelled on log out. Each sync cancels earlier IDs (4200–4207) first; calls are queued.
- **NOTIF-8:** One notification per reminder day, titled "Habit reminder". Body lists up to three habits ("Time to check in: A, B") or two plus "N more". Uses exact timing when allowed, otherwise inexact; handles daylight-saving changes; works on Android, iOS and macOS (no-op elsewhere).

---

## Traceability Summary

| Epic | Screen / Feature | Primary Files |
|------|------------------|---------------|
| 1 | Login | `login_screen.dart`, `auth_text_field.dart`, `habit_logo.dart` |
| 2 | Registration | `register_screen.dart`, `auth_view_model.dart` |
| 3 | Home (+ Add/Edit Habit) | `home_screen.dart`, `add_habit_screen.dart`, `habit_view_model.dart` |
| 4 | Detail (Analytics) | `analytics_screen.dart`, `habit_stats.dart` |
| 5 | Persistent data | `auth_storage.dart`, `habit_storage.dart`, `settings_storage.dart` |
| 6 | External API | `country_repository.dart`, `country_fallback.dart`, `country_picker.dart` |
| 7 | Settings menu | `app_drawer.dart` |
| 8 | Settings screen | `settings_screen.dart`, `settings_view_model.dart` |
| 9 | Notifications | `notifications_screen.dart`, `notification_service.dart`, `time_wheel_picker.dart` |
