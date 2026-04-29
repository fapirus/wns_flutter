import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/wns_notification_type.dart';
import 'package:wns_flutter/src/service/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('wns_flutter');

  group('NotificationService', () {
    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('maps activation arguments, payload, and user input', () async {
      final service = NotificationService(
        channel,
        messageOpenedAppStream: Stream<dynamic>.value({
          'type': 'toast',
          'kind': 'foregroundForward',
          'arguments': 'route=detail&id=42',
          'userInput': {'reply': 'hello'},
          'data': {'type': 'toast', 'conversationId': 'c-1'},
          'rawText': '{"type":"toast"}',
        }),
      );

      final activation = await service.onActivation.first;

      expect(activation.type, WnsNotificationType.toast);
      expect(activation.kind, WnsActivationKind.foregroundForward);
      expect(activation.payload.launchArguments, 'route=detail&id=42');
      expect(activation.payload.launchArgumentMap, {
        'route': 'detail',
        'id': '42',
      });
      expect(activation.userInput, {'reply': 'hello'});
      expect(activation.payload.data, {
        'type': 'toast',
        'conversationId': 'c-1',
      });
      expect(activation.payload.rawText, '{"type":"toast"}');
    });

    test('falls back to argument map when data is not provided', () async {
      final service = NotificationService(
        channel,
        messageOpenedAppStream: Stream<dynamic>.value({
          'arguments': 'route=detail&id=42',
        }),
      );

      final activation = await service.onActivation.first;

      expect(activation.payload.data, {'route': 'detail', 'id': '42'});
    });

    test('maps incoming message payload and received time', () async {
      final service = NotificationService(
        channel,
        messageStream: Stream<dynamic>.value({
          'type': 'toast',
          'source': 'foreground',
          'arguments': 'route=inbox&messageId=m-1',
          'xml': '<toast launch="route=inbox&amp;messageId=m-1" />',
          'receivedAt': 1700000000000,
        }),
      );

      final message = await service.onMessage.first;

      expect(message.type, WnsNotificationType.toast);
      expect(message.source, WnsMessageSource.foreground);
      expect(message.payload.launchArgumentMap, {
        'route': 'inbox',
        'messageId': 'm-1',
      });
      expect(message.payload.data, {'route': 'inbox', 'messageId': 'm-1'});
      expect(
        message.payload.xml,
        '<toast launch="route=inbox&amp;messageId=m-1" />',
      );
      expect(
        message.receivedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    test('returns typed channel result', () async {
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

      final service = NotificationService(channel);
      final channelResult = await service.requestChannel();

      expect(channelResult.uri, 'https://notify.windows.com/channel');
      expect(
        channelResult.expirationTime,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    test('maps native channel request failures to typed exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getChannelUri') {
              throw PlatformException(
                code: 'CHANNEL_REQUEST_FAILED',
                message: 'Failed to create push notification channel.',
                details: 'HRESULT: 0x80070490',
              );
            }

            return null;
          });

      final service = NotificationService(channel);

      await expectLater(
        service.requestChannel(),
        throwsA(
          isA<WnsChannelRequestException>()
              .having(
                (value) => value.code,
                'code',
                'CHANNEL_REQUEST_FAILED',
              )
              .having(
                (value) => value.details,
                'details',
                contains('0x80070490'),
              ),
        ),
      );
    });

    test('maps package identity failures to typed exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize') {
              throw PlatformException(
                code: 'IDENTITY_NOT_FOUND',
                message: 'Windows package identity is required.',
              );
            }

            return null;
          });

      final service = NotificationService(channel);

      await expectLater(
        service.initializePartnerCenter(),
        throwsA(
          isA<WnsPackageIdentityNotFoundException>().having(
            (value) => value.code,
            'code',
            'IDENTITY_NOT_FOUND',
          ),
        ),
      );
    });

    test('returns null when there is no initial activation', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getInitialMessage') {
              return null;
            }

            return null;
          });

      final service = NotificationService(channel);

      expect(await service.getInitialActivation(), isNull);
    });

    test('parses initial activation message from channel result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getInitialMessage') {
              return {
                'type': 'toast',
                'kind': 'launch',
                'arguments': 'route=inbox&messageId=99',
                'userInput': {'action': 'open'},
                'rawText': 'route=inbox&messageId=99',
              };
            }

            return null;
          });

      final service = NotificationService(channel);
      final activation = await service.getInitialActivation();

      expect(activation, isNotNull);
      expect(activation!.kind, WnsActivationKind.launch);
      expect(activation.payload.launchArgumentMap, {
        'route': 'inbox',
        'messageId': '99',
      });
      expect(activation.userInput, {'action': 'open'});
      expect(activation.payload.data, {'route': 'inbox', 'messageId': '99'});
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

    test('throws parse exception for invalid activation payload', () async {
      final service = NotificationService(
        channel,
        messageOpenedAppStream: Stream<dynamic>.value('invalid'),
      );

      await expectLater(
        service.onActivation,
        emitsError(
          isA<WnsActivationParseException>().having(
            (value) => value.code,
            'code',
            'INVALID_ACTIVATION_PAYLOAD',
          ),
        ),
      );
    });
  });
}
