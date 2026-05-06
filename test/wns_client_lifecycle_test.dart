import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/core/wns_client.dart';
import 'package:wns_flutter/src/core/wns_platform_adapter.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_channel.dart';
import 'package:wns_flutter/src/model/wns_message.dart';

void main() {
  group('WnsClient lifecycle', () {
    test('initialize is idempotent after success', () async {
      final adapter = _FakeWnsPlatformAdapter();
      final client = WnsClient(adapter);

      await client.initialize();
      await client.initialize();

      expect(adapter.initializeCount, 1);
    });

    test('requestChannel throws before initialize', () async {
      final client = WnsClient(_FakeWnsPlatformAdapter());

      await expectLater(
        client.requestChannel(),
        throwsA(isA<WnsNotInitializedException>()),
      );
    });

    test('requestChannel delegates after initialize', () async {
      final adapter = _FakeWnsPlatformAdapter();
      final client = WnsClient(adapter);

      await client.initialize();
      final channel = await client.requestChannel();

      expect(adapter.requestChannelCount, 1);
      expect(channel.uri, 'https://notify.windows.com/channel');
    });

    test('closeChannel delegates as no-op after initialize', () async {
      final adapter = _FakeWnsPlatformAdapter();
      final client = WnsClient(adapter);

      await client.initialize();
      await client.closeChannel();

      expect(adapter.closeChannelCount, 1);
    });

    test('getInitialActivation delegates after initialize', () async {
      final adapter = _FakeWnsPlatformAdapter();
      final client = WnsClient(adapter);

      await client.initialize();
      final activation = await client.getInitialActivation();

      expect(adapter.getInitialActivationCount, 1);
      expect(activation, isNotNull);
      expect(activation, isA<WnsToastActivation>());
      expect(
        (activation! as WnsToastActivation).kind,
        WnsToastActivationKind.launch,
      );
    });

    test('use after dispose throws disposed exception', () async {
      final client = WnsClient(_FakeWnsPlatformAdapter());

      await client.initialize();
      await client.dispose();

      await expectLater(
        client.requestChannel(),
        throwsA(isA<WnsDisposedException>()),
      );
      await expectLater(
        client.initialize(),
        throwsA(isA<WnsDisposedException>()),
      );
    });
  });
}

class _FakeWnsPlatformAdapter implements WnsPlatformAdapter {
  int initializeCount = 0;
  int requestChannelCount = 0;
  int closeChannelCount = 0;
  int getInitialActivationCount = 0;
  int disposeCount = 0;

  @override
  Stream<WnsMessage> get onMessage => const Stream<WnsMessage>.empty();

  @override
  Stream<WnsActivation> get onActivation => const Stream<WnsActivation>.empty();

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<WnsChannel> requestChannel() async {
    requestChannelCount += 1;
    return WnsChannel(
      uri: 'https://notify.windows.com/channel',
      expirationTime: DateTime.now().add(const Duration(days: 1)),
    );
  }

  @override
  Future<void> closeChannel() async {
    closeChannelCount += 1;
  }

  @override
  Future<WnsActivation?> getInitialActivation() async {
    getInitialActivationCount += 1;
    return const WnsToastActivation(
      kind: WnsToastActivationKind.launch,
      arguments: 'route=inbox',
      argumentMap: <String, String>{'route': 'inbox'},
    );
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}
