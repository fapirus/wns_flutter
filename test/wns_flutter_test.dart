import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/notification.dart';
import 'package:wns_flutter/src/service/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('wns_flutter');

  group('WindowsNotificationActivation', () {
    test('parses arguments, payload, and user input', () {
      final activation = WindowsNotificationActivation.fromMap({
        'arguments': 'route=detail&id=42',
        'userInput': {'reply': 'hello'},
        'data': {'type': 'toast', 'conversationId': 'c-1'},
        'rawPayload': '{"type":"toast"}',
      });

      expect(activation.arguments, 'route=detail&id=42');
      expect(activation.argumentMap, {'route': 'detail', 'id': '42'});
      expect(activation.userInput, {'reply': 'hello'});
      expect(activation.payload.data, {
        'type': 'toast',
        'conversationId': 'c-1',
      });
      expect(activation.payload.rawPayload, '{"type":"toast"}');
    });

    test('falls back to argument map when data is not provided', () {
      final activation = WindowsNotificationActivation.fromMap({
        'arguments': 'route=detail&id=42',
      });

      expect(activation.payload.data, {'route': 'detail', 'id': '42'});
    });
  });

  group('WindowsIncomingMessage', () {
    test('parses payload and received time', () {
      final message = WindowsIncomingMessage.fromMap({
        'arguments': 'route=inbox&messageId=m-1',
        'rawPayload': '<toast launch="route=inbox&amp;messageId=m-1" />',
        'receivedAt': 1700000000000,
      });

      expect(message.argumentMap, {'route': 'inbox', 'messageId': 'm-1'});
      expect(message.payload.data, {'route': 'inbox', 'messageId': 'm-1'});
      expect(
        message.payload.rawPayload,
        '<toast launch="route=inbox&amp;messageId=m-1" />',
      );
      expect(
        message.receivedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });
  });

  group('NotificationService', () {
    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('returns null when there is no initial message', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getInitialMessage') {
              return null;
            }

            return null;
          });

      final service = NotificationService(channel);

      expect(await service.getInitialMessage(), isNull);
    });

    test('parses initial activation message from channel result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getInitialMessage') {
              return {
                'arguments': 'route=inbox&messageId=99',
                'userInput': {'action': 'open'},
                'rawPayload': 'route=inbox&messageId=99',
              };
            }

            return null;
          });

      final service = NotificationService(channel);
      final message = await service.getInitialMessage();

      expect(message, isNotNull);
      expect(message!.argumentMap, {'route': 'inbox', 'messageId': '99'});
      expect(message.userInput, {'action': 'open'});
      expect(message.payload.data, {'route': 'inbox', 'messageId': '99'});
    });

    test('invokes foreground presentation method', () async {
      bool invoked = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setForegroundNotificationPresentation') {
              invoked = true;
              expect(call.arguments, {'alert': false});
            }

            return null;
          });

      final service = NotificationService(channel);
      await service.setForegroundNotificationPresentation(alert: false);

      expect(invoked, isTrue);
    });

    test('maps incoming message events from injected stream', () async {
      final service = NotificationService(
        channel,
        messageStream: Stream<dynamic>.value({
          'arguments': 'route=thread&id=5',
          'rawPayload': '<toast launch="route=thread&amp;id=5" />',
        }),
      );

      await expectLater(
        service.onMessage,
        emits(
          isA<WindowsIncomingMessage>().having(
            (value) => value.argumentMap['id'],
            'id',
            '5',
          ),
        ),
      );
    });

    test('maps activation events from injected stream', () async {
      final service = NotificationService(
        channel,
        messageOpenedAppStream: Stream<dynamic>.value({
          'arguments': 'route=thread&id=5',
          'data': {'id': '5'},
        }),
      );

      await expectLater(
        service.onMessageOpenedApp,
        emits(
          isA<WindowsNotificationActivation>().having(
            (value) => value.argumentMap['id'],
            'id',
            '5',
          ),
        ),
      );
    });

    test('throws parse exception for invalid message payload', () async {
      final service = NotificationService(
        channel,
        messageStream: Stream<dynamic>.value('invalid'),
      );

      await expectLater(
        service.onMessage,
        emitsError(
          isA<WnsMessageParseException>().having(
            (value) => value.code,
            'code',
            'INVALID_MESSAGE_PAYLOAD',
          ),
        ),
      );
    });
  });
}
