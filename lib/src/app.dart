import 'package:flutter/material.dart';

import 'core/services/fcm_service.dart';
import 'features/auth/presentation/pages/authentication_screen.dart';

class InventoryApp extends StatefulWidget {
  const InventoryApp({
    super.key,
    this.firebaseReady = true,
    this.startupMessage,
  });

  final bool firebaseReady;
  final String? startupMessage;

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  late final FCMController _messagingController = FCMController();
  late final FCMService _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      _initializeMessaging();
    } else {
      _messagingController.updateConnectionState(
        widget.startupMessage ?? 'Firebase is unavailable on this platform.',
      );
    }
  }

  Future<void> _initializeMessaging() async {
    await _fcmService.initialize(controller: _messagingController);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FCM Activity Demo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: widget.firebaseReady
          ? AuthenticationScreen(messagingController: _messagingController)
          : _StartupBlockedScreen(message: widget.startupMessage),
    );
  }
}

class _StartupBlockedScreen extends StatelessWidget {
  const _StartupBlockedScreen({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Setup Required')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'The app is not stuck.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message ??
                          'Firebase could not start for this target.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Next step: run this app on Android or iOS after replacing the Firebase config files with the ones from your own Firebase project.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
