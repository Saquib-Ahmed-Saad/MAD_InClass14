# Reflection - Firebase Cloud Messaging in Flutter

## Prompt 1: Setup Reasoning

FlutterFire configuration was the correct first step because every later part of the assignment depends on Firebase being initialized with the right project and platform identifiers. If the Android package name, `google-services.json`, or `firebase_options.dart` are wrong, then notification token generation, authentication, and message delivery all fail even if the Dart code is correct. I configured the app so Firebase initializes before `runApp()`, and I verified the project files were aligned to the Android package `com.fitio.app`. The strongest setup evidence is the updated Firebase configuration in the repository and a clean `flutter analyze` run after the configuration changes.

## Prompt 2: Lifecycle Analysis

The app handles the three FCM lifecycle states with a single service and controller so the UI can show which path was used. In the foreground, `onMessage` updates the profile screen immediately and also triggers a local notification for visibility. In the background, `onMessageOpenedApp` runs after the user taps the notification and routes the payload back into the same controller. In the terminated state, `getInitialMessage()` restores the payload when the app launches from a notification tap. This design keeps the payload processing centralized instead of duplicating logic in several widgets, which reduces inconsistent behavior between states.

## Prompt 3: Debug Evidence

One bug I had to fix was that the app appeared to hang during startup. The root cause was not a Flutter layout problem. The app was still wired to an older Firebase project and was also being launched on unsupported desktop targets for FCM. I diagnosed this by checking the generated Firebase files and comparing the project id in `firebase_options.dart` and `google-services.json` against the intended Firebase project `inclass14-6d19c`. I then updated the Android Firebase config, added guarded startup handling for unsupported platforms, and surfaced a visible connection status in the profile screen instead of letting initialization fail silently. The proof that the fix worked is that the repository now points Android to the correct Firebase project and static analysis passes with no errors.

## Prompt 4: Payload Design

I used the payload keys `asset` and `action` because they map cleanly to visible UI behavior without adding unnecessary complexity. The `asset` key lets the app change the visual accent state of the notification panel, and the `action` key determines which icon or interaction theme should appear. I also relied on the standard notification `title` and `body` fields so the message content is visible both in the UI and in the system notification. This payload shape was appropriate because it is small, easy to test from Firebase Console, and simple to validate when a message is missing optional fields.

## Prompt 5: Improvement Plan

If I had another hour, I would finish end-to-end device verification on Android and capture final evidence for foreground, background, and terminated delivery states. The main reason is that the app-side implementation is complete enough to demonstrate the assignment goals, but FCM evidence is only meaningful when tested on a real Android target with a current device token. After that, I would improve the experience by adding explicit navigation actions for different notification types and storing a short history of received messages for easier debugging.

## Trade-off

I intentionally simplified the UI reaction to incoming messages. Instead of building a complex animation workflow first, I updated visible text, status chips, accent colors, and handler labels. That trade-off made debugging easier because I could verify payload processing with obvious changes before adding more advanced behavior.

## Risk and Protection

The biggest risk was inconsistent behavior across foreground, background, and terminated states. I reduced that risk by using one `FCMService`, one `FCMController`, a top-level background handler, and one payload model that normalizes incoming data. I also added fallback values for missing keys so incomplete payloads do not crash the app.

## Evidence Notes

Add your own final evidence here before submitting:

- Screenshot of the profile screen showing the generated FCM token.
- Screenshot or short clip of a foreground message updating the cloud messaging monitor.
- Screenshot of a notification tap reopening the app from background.
- Screenshot showing terminated launch behavior through `getInitialMessage()` if completed.
- A copy of the payload used in Firebase Console, for example `asset=promo` and `action=show_animation`.

## Known Limitation

At the time of writing, the local machine still needed a working Android SDK or emulator setup to complete final device-side FCM verification. The Flutter project itself analyzes cleanly, and the Android Firebase configuration now targets `inclass14-6d19c`, but final notification evidence must be captured on an Android device or emulator.
