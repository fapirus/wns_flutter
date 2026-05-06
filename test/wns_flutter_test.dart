import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_message.dart';
import 'package:wns_flutter/src/service/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('wns_flutter');

  group('NotificationService', () {
    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('maps toast activation arguments, payload, and user input', () async {
      final service = NotificationService(
        channel,
        messageOpenedAppStream: Stream<dynamic>.value({
          'type': 'toast',
          'kind': 'foregroundForward',
          'arguments': 'route=detail&id=42&action=reply',
          'userInput': {'reply': 'hello'},
          'data': {'type': 'toast', 'conversationId': 'c-1'},
          'xml': '<toast launch="route=detail&amp;id=42" />',
        }),
      );

      final activation = await service.onActivation.first;

      expect(activation, isA<WnsToastActivation>());
      final toast = activation as WnsToastActivation;
      expect(toast.kind, WnsToastActivationKind.foregroundForward);
      expect(toast.arguments, 'route=detail&id=42&action=reply');
      expect(toast.argumentMap, {
        'route': 'detail',
        'id': '42',
        'action': 'reply',
      });
      expect(toast.actionId, 'reply');
      expect(toast.userInput, {'reply': 'hello'});
      expect(toast.data, {'type': 'toast', 'conversationId': 'c-1'});
      expect(toast.xml, '<toast launch="route=detail&amp;id=42" />');
      expect(toast.rawPayload, '<toast launch="route=detail&amp;id=42" />');
    });

    test(
      'toast activation falls back to argument map when data is not provided',
      () async {
        final service = NotificationService(
          channel,
          messageOpenedAppStream: Stream<dynamic>.value({
            'type': 'toast',
            'arguments': 'route=detail&id=42',
          }),
        );

        final activation =
            await service.onActivation.first as WnsToastActivation;

        expect(activation.data, {'route': 'detail', 'id': '42'});
      },
    );

    test('maps foreground raw message payload and received time', () async {
      final service = NotificationService(
        channel,
        messageStream: Stream<dynamic>.value({
          'type': 'raw',
          'data': {'event': 'sync', 'messageId': 'm-1'},
          'rawText': '{"event":"sync","messageId":"m-1"}',
          'receivedAt': 1700000000000,
        }),
      );

      final message = await service.onMessage.first;

      expect(message, isA<WnsRawMessage>());
      final raw = message as WnsRawMessage;
      expect(raw.data, {'event': 'sync', 'messageId': 'm-1'});
      expect(raw.text, '{"event":"sync","messageId":"m-1"}');
      expect(raw.rawPayload, '{"event":"sync","messageId":"m-1"}');
      expect(
        raw.receivedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    test(
      'maps raw JSON text to data when native data is not provided',
      () async {
        final service = NotificationService(
          channel,
          messageStream: Stream<dynamic>.value({
            'type': 'raw',
            'rawText': '{"event":"debug.raw","value":4}',
            'receivedAt': 1700000000000,
          }),
        );

        final raw = await service.onMessage.first as WnsRawMessage;

        expect(raw.data, {'event': 'debug.raw', 'value': '4'});
      },
    );

    test(
      'maps Partner Center raw badge and tile message payload types',
      () async {
        final events = <Map<String, Object?>>[
          {
            'type': 'raw',
            'rawText': '{"event":"sync"}',
            'receivedAt': 1700000000000,
          },
          {
            'type': 'badge',
            'xml': '<badge value="3" />',
            'receivedAt': 1700000000001,
          },
          {
            'type': 'tile',
            'xml': '<tile><visual /></tile>',
            'receivedAt': 1700000000002,
          },
        ];

        final service = NotificationService(
          channel,
          messageStream: Stream<dynamic>.fromIterable(events),
        );

        final messages = await service.onMessage.toList();

        expect(messages[0], isA<WnsRawMessage>());
        expect((messages[0] as WnsRawMessage).text, '{"event":"sync"}');
        expect(messages[1], isA<WnsBadgeMessage>());
        expect((messages[1] as WnsBadgeMessage).value, 3);
        expect(
          (messages[1] as WnsBadgeMessage).rawPayload,
          '<badge value="3" />',
        );
        expect(messages[2], isA<WnsTileMessage>());
        expect((messages[2] as WnsTileMessage).xml, '<tile><visual /></tile>');
      },
    );

    test(
      'maps native badge value and glyph fields before XML fallback',
      () async {
        final service = NotificationService(
          channel,
          messageStream: Stream<dynamic>.value({
            'type': 'badge',
            'value': 7,
            'glyph': 'alert',
            'xml': '<badge value="3" />',
            'receivedAt': 1700000000000,
          }),
        );

        final badge = await service.onMessage.first as WnsBadgeMessage;

        expect(badge.value, 7);
        expect(badge.glyph, 'alert');
      },
    );

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
              .having((value) => value.code, 'code', 'CHANNEL_REQUEST_FAILED')
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

    test(
      'parses initial toast activation message from channel result',
      () async {
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

        expect(activation, isA<WnsToastActivation>());
        final toast = activation! as WnsToastActivation;
        expect(toast.kind, WnsToastActivationKind.launch);
        expect(toast.argumentMap, {'route': 'inbox', 'messageId': '99'});
        expect(toast.userInput, {'action': 'open'});
        expect(toast.data, {'route': 'inbox', 'messageId': '99'});
      },
    );

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

    test('throws parse exception for unknown message type', () async {
      final service = NotificationService(
        channel,
        messageStream: Stream<dynamic>.value({'type': 'toast'}),
      );

      await expectLater(
        service.onMessage,
        emitsError(
          isA<WnsMessageParseException>().having(
            (value) => value.code,
            'code',
            'UNSUPPORTED_MESSAGE_TYPE',
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

    test('throws parse exception for unknown activation type', () async {
      final service = NotificationService(
        channel,
        messageOpenedAppStream: Stream<dynamic>.value({'type': 'raw'}),
      );

      await expectLater(
        service.onActivation,
        emitsError(
          isA<WnsActivationParseException>().having(
            (value) => value.code,
            'code',
            'UNSUPPORTED_ACTIVATION_TYPE',
          ),
        ),
      );
    });
  });
}
