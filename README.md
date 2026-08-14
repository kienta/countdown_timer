# Countdown Timer

A cross-platform countdown timer application (Android, iOS, Windows, macOS, Linux, Web) built with Flutter.

## Features

- Create and manage multiple countdown timers simultaneously
- Animated hourglass visualization
- Audio alarm when a timer finishes
- System notification on timer completion
- Sort timers by name, remaining time, or creation date
- Local data persistence with SQLite
- Dark theme with responsive layout across screen sizes

## Prerequisites

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- **Windows**: Visual Studio 2022 with "Desktop development with C++" workload
- **macOS**: Xcode >= 14
- **Linux**: `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`
- **Android**: Android SDK & Android Studio
- **iOS**: Xcode >= 14 (macOS only)

## Installation

1. Clone the repository:

```bash
git clone <repo-url>
cd countdown_timer
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app in debug mode:

```bash
# Default device
flutter run

# Specific platform
flutter run -d windows
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

## Building Release Executables

### Windows (.exe)

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/countdown_timer.exe`

### macOS (.app)

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/countdown_timer.app`

### Linux

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/countdown_timer`

### Android (.apk / .aab)

```bash
# APK (for direct installation)
flutter build apk --release

# App Bundle (for Google Play Store)
flutter build appbundle --release
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS (.ipa)

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/countdown_timer.ipa`

> **Note:** iOS builds require macOS with Xcode and a valid Apple Developer signing configuration.

### Web

```bash
flutter build web --release
```

Output: `build/web/` (deploy this directory to any static hosting)

## Packaging Installers

Flutter does not create installers natively (except for Android/iOS). You need external tools to package the app for distribution.

### Windows — Inno Setup (.exe installer)

1. Install [Inno Setup](https://jrsoftware.org/isinfo.php)
2. Build the app:

```bash
flutter build windows --release
```

3. Create the installer using the included `installer.iss`:

```bash
# Via command line
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss

# Or open installer.iss in Inno Setup GUI → Build → Compile
```

4. Output: `build/installer/CountdownTimer-Setup.exe`

### macOS — Disk Image (.dmg)

1. Build the app:

```bash
flutter build macos --release
```

2. Create the `.dmg`:

```bash
hdiutil create -volname "Countdown Timer" \
  -srcfolder build/macos/Build/Products/Release/countdown_timer.app \
  -ov -format UDZO \
  build/CountdownTimer.dmg
```

3. Output: `build/CountdownTimer.dmg`

> **Note:** For distribution outside the Mac App Store, you need to notarize the app with an Apple Developer account.

### Linux — Debian package (.deb)

1. Install `flutter_distributor`:

```bash
dart pub global activate flutter_distributor
```

2. Install `flutter_to_debian`:

```bash
dart pub global activate flutter_to_debian
```

3. Create `distribute_options.yaml` in the project root:

```yaml
output: build/dist
releases:
  - name: linux
    jobs:
      - name: build-deb
        package:
          platform: linux
          target: deb
```

4. Run:

```bash
flutter_distributor release --name linux
```

5. Output: `build/dist/` directory

### Android — Direct install (.apk)

No extra tools needed. The `.apk` file can be installed directly on Android devices:

```bash
flutter build apk --release
```

Transfer `build/app/outputs/flutter-apk/app-release.apk` to the device and open it to install.

### iOS — App Store / TestFlight (.ipa)

No extra tools needed. Upload the `.ipa` to App Store Connect using Xcode or Transporter:

```bash
flutter build ipa --release
```

> **Note:** Requires a paid Apple Developer account and proper signing configuration.

## Usage

1. **Create a timer** — Tap the **+** button in the top-right corner. Enter a name and set the duration (hours, minutes, seconds).
2. **Start / Pause** — Tap a timer card to open the countdown screen. Use the Play/Pause button to control it.
3. **Reset** — Tap the Reset button to restore the timer to its original duration.
4. **Sort** — Use the "Sort by" dropdown on the toolbar to reorder the timer list.
5. **Delete** — Swipe or tap the delete button on a timer card to remove it.
6. **Alarm** — When a timer reaches zero, the app plays an audio alert and shows a system notification.

## Running Tests

```bash
flutter test
```

## Project Structure

```
lib/
  main.dart                   # App entry point
  models/
    timer_model.dart          # Timer data model
  screens/
    launcher_screen.dart      # Main screen (timer list)
    timer_screen.dart         # Countdown screen
  services/
    database_service.dart     # SQLite database management
    timer_service.dart        # Timer state management
    notification_service.dart # Audio & system notifications
  theme/
    app_theme.dart            # Theme configuration
  utils/
    responsive.dart           # Responsive layout utilities
    time_utils.dart           # Time formatting helpers
  widgets/
    create_timer_dialog.dart  # Create timer dialog
    hourglass_widget.dart     # Hourglass animation widget
    timer_card.dart           # Timer card widget
```
