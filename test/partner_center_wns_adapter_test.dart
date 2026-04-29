import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/adapter/partner_center/partner_center_wns_adapter.dart';
import 'package:wns_flutter/src/config/partner_center_wns_options.dart';
import 'package:wns_flutter/src/model/wns_notification_type.dart';
import 'package:wns_flutter/src/service/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('wns_flutter');

  group('PartnerCenterWnsAdapter', () {
    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('initialize forwards Partner Center options', () async {
      MethodCall? invokedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            invokedCall = call;
            return null;
          });

      final adapter = PartnerCenterWnsAdapter(
        options: const PartnerCenterWnsOptions(appUserModelId: 'app.id'),
        notificationService: NotificationService(
          channel,
          messageStream: const Stream<dynamic>.empty(),
          messageOpenedAppStream: const Stream<dynamic>.empty(),
        ),
      );

      await adapter.initialize();

      expect(invokedCall!.method, 'initialize');
      expect(invokedCall!.arguments, {'appUserModelId': 'app.id'});
    });

    test('requestChannel maps legacy channel result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getChannelUri') {
              return {
                'uri': 'https://notify.windows.com/channel',
                'expirationTime': 1700000000000,
              };
            }

            return null;
          });

      final adapter = PartnerCenterWnsAdapter(
        notificationService: NotificationService(
          channel,
          messageStream: const Stream<dynamic>.empty(),
          messageOpenedAppStream: const Stream<dynamic>.empty(),
        ),
      );

      final channelResult = await adapter.requestChannel();

      expect(channelResult.uri, 'https://notify.windows.com/channel');
      expect(
        channelResult.expirationTime,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    test('onMessage maps legacy foreground toast events', () async {
      final adapter = PartnerCenterWnsAdapter(
        notificationService: NotificationService(
          channel,
          messageStream: Stream<dynamic>.value({
            'arguments': 'route=thread&id=5',
            'rawPayload': '<toast launch="route=thread&amp;id=5" />',
            'receivedAt': 1700000000000,
          }),
          messageOpenedAppStream: const Stream<dynamic>.empty(),
        ),
      );

      await expectLater(
        adapter.onMessage,
        emits(
          isA<dynamic>()
              .having((value) => value.type, 'type', WnsNotificationType.toast)
              .having((value) => value.payload.xml, 'xml', isNotNull)
              .having(
                (value) => value.payload.launchArgumentMap['id'],
                'launchArgumentMap id',
                '5',
              ),
        ),
      );
    });

    test('onActivation maps forwarded activation events', () async {
      final adapter = PartnerCenterWnsAdapter(
        notificationService: NotificationService(
          channel,
          messageStream: const Stream<dynamic>.empty(),
          messageOpenedAppStream: Stream<dynamic>.value({
            'arguments': 'route=thread&id=5',
            'userInput': {'reply': 'ok'},
          }),
        ),
      );

      await expectLater(
        adapter.onActivation,
        emits(
          isA<dynamic>()
              .having((value) => value.type, 'type', WnsNotificationType.toast)
              .having(
                (value) => value.payload.launchArgumentMap['id'],
                'launchArgumentMap id',
                '5',
              )
              .having((value) => value.userInput['reply'], 'reply', 'ok'),
        ),
      );
    });
  });
}
