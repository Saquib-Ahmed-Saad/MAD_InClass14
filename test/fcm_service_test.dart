import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_inclass14_fcm/src/core/services/fcm_service.dart';

void main() {
  group('FCMMessagePayload', () {
    test('maps notification and data fields into a UI-safe payload', () {
      final payload = FCMMessagePayload.fromRaw(
        title: 'New promotion',
        body: 'Switch the screen to the promo asset',
        data: const <String, Object?>{
          'asset': 'promo',
          'action': 'show_animation',
          'screen': 'profile',
        },
        messageId: 'msg-123',
        source: FCMMessageSource.foreground,
        receivedAt: DateTime(2026, 4, 13, 18),
      );

      expect(payload.title, 'New promotion');
      expect(payload.body, 'Switch the screen to the promo asset');
      expect(payload.assetKey, 'promo');
      expect(payload.actionKey, 'show_animation');
      expect(payload.messageId, 'msg-123');
      expect(payload.source, FCMMessageSource.foreground);
      expect(
        payload.payloadSummary,
        'asset=promo, action=show_animation, screen=profile',
      );
    });

    test('falls back safely when optional fields are missing', () {
      final payload = FCMMessagePayload.fromRaw(
        data: const <String, Object?>{'unexpected': 'value'},
        source: FCMMessageSource.terminatedLaunch,
      );

      expect(payload.title, 'Cloud update received');
      expect(
        payload.body,
        'Your app processed a Firebase Cloud Messaging payload.',
      );
      expect(payload.assetKey, 'default');
      expect(payload.actionKey, 'none');
      expect(payload.messageId, 'no-message-id');
      expect(payload.payloadSummary, 'unexpected=value');
      expect(payload.source.label, 'getInitialMessage()');
    });
  });

  group('FCMController', () {
    test('stores the latest permission, token, and message state', () {
      final controller = FCMController();
      final payload = FCMMessagePayload.fromRaw(
        title: 'Offer update',
        data: const <String, Object?>{'asset': 'offer'},
        source: FCMMessageSource.notificationTap,
      );

      controller.updatePermission(AuthorizationStatus.authorized);
      controller.updateToken('abc-token');
      controller.updateMessage(payload);

      expect(controller.value.permissionStatus, AuthorizationStatus.authorized);
      expect(controller.value.token, 'abc-token');
      expect(controller.value.lastMessage?.title, 'Offer update');
      expect(controller.value.lastMessage?.assetKey, 'offer');
      expect(
        controller.value.lastMessage?.source,
        FCMMessageSource.notificationTap,
      );
    });
  });
}
