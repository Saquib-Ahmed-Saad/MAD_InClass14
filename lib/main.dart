import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

import 'src/app.dart';

bool _supportsConfiguredFirebasePlatform() {
  if (kIsWeb) {
    return true;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => true,
    TargetPlatform.iOS => true,
    _ => false,
  };
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  String? startupMessage;

  if (_supportsConfiguredFirebasePlatform()) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      firebaseReady = true;
    } catch (error) {
      startupMessage =
          'Firebase failed to initialize. Replace your generated Firebase config with the files from project inclass14-6d19c, then run the app again on Android or iOS.\n\n$error';
    }
  } else {
    startupMessage =
        'This project is configured for Firebase on Android and iOS only. Run it on an Android emulator, Android phone, or iPhone to complete the FCM assignment.';
  }

  runApp(
    InventoryApp(
      firebaseReady: firebaseReady,
      startupMessage: startupMessage,
    ),
  );
}
