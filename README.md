# GoalPath Mobile

Flutter Android client for GoalPath. The app uses the existing REST API and supports login, daily habits, goals, progress, Coach, profile, Premium pricing, and eligible Premium trials.

## Requirements

- Flutter SDK 3.47.4 or newer
- GoalPath API running locally or a reachable API URL

## Run on an Android emulator

From this folder, install packages and start the app:

    flutter pub get
    flutter run

The default API URL is http://10.0.2.2:4000/api/v1, which reaches the host computer from the Android emulator. Start the backend on port 4000 before logging in.

## Run on a physical Android device

Connect the phone and computer to the same network. Start the backend so it accepts connections from the local network, then run Flutter with the computer's LAN address:

    flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000/api/v1

Replace 192.168.1.10 with the computer's LAN IP. The Android debug manifest permits HTTP for local development. Use an HTTPS API URL for release builds.

## Build an APK

    flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api/v1

The APK is written to build/app/outputs/flutter-apk/app-release.apk. Configure Android release signing before distributing a production APK. GitHub Release automation is not configured yet; upload the signed APK to a GitHub Release when ready.

## API and sessions

API_BASE_URL is a compile-time setting. Login and registration use the existing GoalPath API. Access and refresh tokens are stored with Android secure storage, private requests use bearer authentication, and expired sessions are refreshed through the API.
