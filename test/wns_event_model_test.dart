import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_message.dart';

void main() {
  group('typed WNS event models', () {
    test('raw messages compare typed content and raw payload', () {
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);

      expect(
        WnsRawMessage(
          receivedAt: DateTime(2026),
          rawPayload: '{"event":"sync"}',
          text: '{"event":"sync"}',
          bytes: bytes,
          data: const <String, String>{'event': 'sync'},
        ),
        WnsRawMessage(
          receivedAt: DateTime(2026),
          rawPayload: '{"event":"sync"}',
          text: '{"event":"sync"}',
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          data: const <String, String>{'event': 'sync'},
        ),
      );
    });

    test('badge and tile messages expose only type-specific fields', () {
      expect(
        WnsBadgeMessage(
          receivedAt: DateTime(2026),
          rawPayload: '<badge value="4" />',
          value: 4,
        ),
        WnsBadgeMessage(
          receivedAt: DateTime(2026),
          rawPayload: '<badge value="4" />',
          value: 4,
        ),
      );
      expect(
        WnsTileMessage(
          receivedAt: DateTime(2026),
          rawPayload: '<tile><visual /></tile>',
          xml: '<tile><visual /></tile>',
        ),
        WnsTileMessage(
          receivedAt: DateTime(2026),
          rawPayload: '<tile><visual /></tile>',
          xml: '<tile><visual /></tile>',
        ),
      );
    });

    test('toast activation compares activation-specific fields', () {
      expect(
        WnsToastActivation(
          kind: WnsToastActivationKind.action,
          arguments: 'route=inbox&action=reply',
          argumentMap: const <String, String>{
            'route': 'inbox',
            'action': 'reply',
          },
          actionId: 'reply',
          userInput: const <String, String>{'reply': 'ok'},
          xml: '<toast />',
          data: const <String, String>{'route': 'inbox'},
          activatedAt: DateTime(2026),
          rawPayload: '<toast />',
        ),
        WnsToastActivation(
          kind: WnsToastActivationKind.action,
          arguments: 'route=inbox&action=reply',
          argumentMap: const <String, String>{
            'route': 'inbox',
            'action': 'reply',
          },
          actionId: 'reply',
          userInput: const <String, String>{'reply': 'ok'},
          xml: '<toast />',
          data: const <String, String>{'route': 'inbox'},
          activatedAt: DateTime(2026),
          rawPayload: '<toast />',
        ),
      );
    });
  });
}
