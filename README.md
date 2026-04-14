# Firebase Messaging Demo App

Flutter app that combines Firebase Authentication with Firebase Cloud Messaging so a signed-in user can receive a notification, inspect the current device token, and verify which handler processed the latest payload.

## Assignment Coverage

- Firebase initializes before the widget tree starts.
- A top-level background message handler is registered before `runApp()`.
- Firebase Messaging is centralized in a dedicated service and controller.
- The profile screen displays permission state, token state, last payload, and handler source.
- Foreground, background-tap, and terminated-launch flows are mapped to `onMessage`, `onMessageOpenedApp`, and `getInitialMessage()`.
- The app degrades safely on unsupported desktop targets instead of appearing stuck.

## Tech Stack

- Flutter and Dart
- firebase_core
- firebase_auth
- firebase_messaging
- flutter_local_notifications

## Architecture

- App bootstrap in `main.dart` initializes Firebase and registers the background handler.
- `FCMService` owns permission requests, token lookup, listener registration, and foreground notification display.
- `FCMController` stores the latest token, permission state, connection status, and most recent payload.
- Authentication routes the user to a profile screen where the current messaging state is visible.

Source layout used in this project:

```text
lib/
	main.dart
	src/
		app.dart
		core/
			validators/
		features/
			inventory/
				domain/
					entities/
					repositories/
				data/
					models/
					services/
					repositories/
				presentation/
					pages/
```

## Features

- Firebase email/password authentication
- FCM permission request and token retrieval
- Local foreground notification display
- Unified payload handling across foreground, background, and terminated launch
- Visible cloud messaging monitor for submission evidence

## Setup Instructions

1. Clone this repository.
2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase for this app:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=inclass14-6d19c --platforms=android
```

4. Replace `android/app/google-services.json` with the file downloaded from Firebase Console for package `com.fitio.app`.
5. Run the app on Android:

```bash
flutter run -d android
```

Desktop targets are intentionally guarded because FCM for this assignment is validated on Android or iOS, not Windows.

## Build APK

```bash
flutter build apk --release
```

Generated file:

build/app/outputs/flutter-apk/app-release.apk

## Testing and Verification

Run static checks and tests:

```bash
flutter analyze
```

Focused automated coverage:
- Payload normalization tests for `FCMMessagePayload`
- Controller state tests for `FCMController`

Manual verification checklist:
- Capture the FCM token from the profile screen.
- Send a Firebase Console test message with `asset` and `action` custom data.
- Verify foreground update through `onMessage`.
- Verify background reopen through `onMessageOpenedApp`.
- Verify terminated launch through `getInitialMessage()` if device setup is available.

## Reflection

See REFLECTION.md for the required reflection answers document.

## Submission Checklist

- GitHub repository link with the actual code used for the assignment
- Screenshots or a short recording showing token display and notification-driven UI updates
- Reflection document using the prompts in `REFLECTION.md`
- Notes describing any unfinished device-side verification honestly
