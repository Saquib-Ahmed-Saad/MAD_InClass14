import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum FCMMessageSource { foreground, notificationTap, terminatedLaunch }

extension FCMMessageSourceLabel on FCMMessageSource {
  String get label => switch (this) {
    FCMMessageSource.foreground => 'onMessage',
    FCMMessageSource.notificationTap => 'onMessageOpenedApp',
    FCMMessageSource.terminatedLaunch => 'getInitialMessage()',
  };
}

class FCMMessagePayload {
  const FCMMessagePayload({
    required this.title,
    required this.body,
    required this.assetKey,
    required this.actionKey,
    required this.messageId,
    required this.source,
    required this.receivedAt,
    required this.data,
  });

  factory FCMMessagePayload.fromRaw({
    String? title,
    String? body,
    Map<String, Object?> data = const <String, Object?>{},
    String? messageId,
    required FCMMessageSource source,
    DateTime? receivedAt,
  }) {
    final normalizedData = data.map(
      (String key, Object? value) => MapEntry(key, value?.toString() ?? ''),
    );

    return FCMMessagePayload(
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : 'Cloud update received',
      body: body?.trim().isNotEmpty == true
          ? body!.trim()
          : 'Your app processed a Firebase Cloud Messaging payload.',
      assetKey: normalizedData['asset']?.trim().isNotEmpty == true
          ? normalizedData['asset']!.trim()
          : 'default',
      actionKey: normalizedData['action']?.trim().isNotEmpty == true
          ? normalizedData['action']!.trim()
          : 'none',
      messageId: messageId?.trim().isNotEmpty == true
          ? messageId!.trim()
          : 'no-message-id',
      source: source,
      receivedAt: receivedAt ?? DateTime.now(),
      data: Map<String, String>.unmodifiable(normalizedData),
    );
  }

  factory FCMMessagePayload.fromRemoteMessage(
    RemoteMessage message, {
    required FCMMessageSource source,
  }) {
    return FCMMessagePayload.fromRaw(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      messageId: message.messageId,
      source: source,
    );
  }

  final String title;
  final String body;
  final String assetKey;
  final String actionKey;
  final String messageId;
  final FCMMessageSource source;
  final DateTime receivedAt;
  final Map<String, String> data;

  String get payloadSummary {
    if (data.isEmpty) {
      return 'No custom data payload';
    }
    return data.entries
        .map((MapEntry<String, String> entry) {
          return '${entry.key}=${entry.value}';
        })
        .join(', ');
  }
}

class FCMStatus {
  const FCMStatus({
    this.lastMessage,
    this.token,
    this.permissionStatus = AuthorizationStatus.notDetermined,
    this.connectionState = 'Waiting for FCM initialization',
  });

  final FCMMessagePayload? lastMessage;
  final String? token;
  final AuthorizationStatus permissionStatus;
  final String connectionState;

  FCMStatus copyWith({
    FCMMessagePayload? lastMessage,
    String? token,
    AuthorizationStatus? permissionStatus,
    String? connectionState,
  }) {
    return FCMStatus(
      lastMessage: lastMessage ?? this.lastMessage,
      token: token ?? this.token,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

class FCMController extends ValueNotifier<FCMStatus> {
  FCMController() : super(const FCMStatus());

  void updateMessage(FCMMessagePayload message) {
    value = value.copyWith(lastMessage: message);
  }

  void updateToken(String? token) {
    value = value.copyWith(token: token);
  }

  void updatePermission(AuthorizationStatus status) {
    value = value.copyWith(permissionStatus: status);
  }

  void updateConnectionState(String message) {
    value = value.copyWith(connectionState: message);
  }
}

class FCMService {
  FCMService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'fcm_high_importance',
    'Cloud Updates',
    description:
        'Foreground notifications for Firebase Cloud Messaging events.',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize({required FCMController controller}) async {
    if (_initialized) {
      return;
    }

    if (!_supportsMessagingPlatform()) {
      controller.updateConnectionState(
        'FCM is supported for this assignment on Android and iOS. Run the app on a phone or emulator instead of Windows desktop.',
      );
      _initialized = true;
      return;
    }

    controller.updateConnectionState('Initializing Firebase Cloud Messaging...');

    try {
      await _configureLocalNotifications();

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      controller.updatePermission(settings.authorizationStatus);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      controller.updateToken(
        await _messaging.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        ),
      );

      _messaging.onTokenRefresh.listen(controller.updateToken);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final payload = FCMMessagePayload.fromRemoteMessage(
          message,
          source: FCMMessageSource.foreground,
        );
        controller.updateMessage(payload);
        controller.updateConnectionState(
          'Message received through ${payload.source.label}.',
        );
        await _showForegroundNotification(message, payload);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final payload = FCMMessagePayload.fromRemoteMessage(
          message,
          source: FCMMessageSource.notificationTap,
        );
        controller.updateMessage(payload);
        controller.updateConnectionState(
          'Message opened through ${payload.source.label}.',
        );
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        final payload = FCMMessagePayload.fromRemoteMessage(
          initialMessage,
          source: FCMMessageSource.terminatedLaunch,
        );
        controller.updateMessage(payload);
        controller.updateConnectionState(
          'Message restored through ${payload.source.label}.',
        );
      } else {
        controller.updateConnectionState(
          controller.value.token == null
              ? 'Firebase initialized, but no FCM token is available yet. Check your project config and rerun on Android.'
              : 'Firebase initialized. Send a test message from Firebase Console to this token.',
        );
      }

      _initialized = true;
    } catch (error) {
      controller.updateConnectionState(
        'FCM initialization failed. Replace firebase_options.dart and android/app/google-services.json with files from Firebase project inclass14-6d19c, then restart the app.\n\n$error',
      );
    }
  }

  bool _supportsMessagingPlatform() {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      _ => false,
    };
  }

  Future<void> _configureLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(settings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _showForegroundNotification(
    RemoteMessage message,
    FCMMessagePayload payload,
  ) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      payload.title,
      payload.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: message.notification?.android?.smallIcon,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
