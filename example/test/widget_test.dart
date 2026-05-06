import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/wns_flutter.dart';
import 'package:wns_flutter_example/main.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'renders desktop timeline demo and accumulates lifecycle events',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final client = _FakeWnsDemoClient();

      await tester.pumpWidget(MyApp(client: client));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('desktop-shell')), findsOneWidget);
      expect(find.text('Desktop-style WNS validation console'), findsOneWidget);
      expect(find.text('Notification Setting'), findsOneWidget);
      expect(find.text('Partner Center WNS'), findsWidgets);
      expect(find.text('Foreground Messages'), findsOneWidget);
      expect(find.text('Notification Activations'), findsOneWidget);
      expect(find.text('Clear Event Logs'), findsOneWidget);
      expect(find.byKey(const ValueKey('theme-mode-menu')), findsOneWidget);
      expect(find.text('Initial Activation Checked At'), findsOneWidget);

      await tester.tap(find.text('Get Settings Info'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('notification-status-value')),
        findsOneWidget,
      );
      expect(find.textContaining('authorized'), findsWidgets);

      await tester.ensureVisible(find.text('Initialize Client'));
      await tester.tap(find.text('Initialize Client'));
      await tester.pumpAndSettle();
      expect(client.initializeCalls, 1);
      expect(find.text('Client: Initialized'), findsOneWidget);

      await tester.ensureVisible(find.text('Request Channel'));
      await tester.tap(find.text('Request Channel'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('https://notify.windows.com/channel/demo'),
        findsOneWidget,
      );
      expect(find.textContaining('isExpired=false'), findsOneWidget);

      await tester.ensureVisible(find.text('Refresh Initial Activation'));
      await tester.tap(find.text('Refresh Initial Activation'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('route=inbox&id=42', findRichText: true),
        findsOneWidget,
      );

      client.addIncoming(
        WnsRawMessage(
          receivedAt: DateTime(2025, 1, 2, 10, 12, 13),
          rawPayload: '{"event":"sync"}',
          text: '{"event":"sync"}',
          data: const <String, String>{'event': 'sync'},
        ),
      );
      client.addIncoming(
        WnsBadgeMessage(
          receivedAt: DateTime(2025, 1, 2, 10, 13, 14),
          rawPayload: '<badge value="7" />',
          value: 7,
        ),
      );
      client.addIncoming(
        WnsTileMessage(
          receivedAt: DateTime(2025, 1, 2, 10, 14, 15),
          rawPayload: '<tile><visual /></tile>',
          xml: '<tile><visual /></tile>',
        ),
      );
      client.addActivation(
        const WnsToastActivation(
          kind: WnsToastActivationKind.foregroundForward,
          arguments: 'route=settings&action=open',
          argumentMap: <String, String>{'route': 'settings', 'action': 'open'},
          actionId: 'open',
          userInput: <String, String>{'action': 'open'},
          xml: '<toast>settings</toast>',
          data: <String, String>{'route': 'settings', 'action': 'open'},
          rawPayload: '<toast>settings</toast>',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Foreground'), findsNWidgets(3));
      expect(find.text('Opened App'), findsOneWidget);
      expect(find.text('toast activation'), findsOneWidget);
      expect(find.text('raw'), findsOneWidget);
      expect(find.text('badge'), findsOneWidget);
      expect(find.text('tile'), findsOneWidget);
      expect(
        find.textContaining('route=orders&id=100', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('event=sync', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('action=open', findRichText: true),
        findsWidgets,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('clear-event-logs-button')),
      );
      await tester.tap(find.byKey(const ValueKey('clear-event-logs-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('empty-foreground-messages-message')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('empty-activation-events-message')),
        findsOneWidget,
      );
    },
  );

  testWidgets('uses mobile shell on narrow widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final client = _FakeWnsDemoClient();
    await tester.pumpWidget(MyApp(client: client));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-shell')), findsNothing);
  });
}

class _FakeWnsDemoClient implements WnsDemoClient {
  final StreamController<WnsMessage> _messageController =
      StreamController<WnsMessage>.broadcast();
  final StreamController<WnsActivation> _activationController =
      StreamController<WnsActivation>.broadcast();

  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<WnsNotificationSettingsInfo> getNotificationSettingsInfo() async {
    return const WnsNotificationSettingsInfo(
      status: WnsNotificationPermissionStatus.authorized,
      displaySetting: WnsNotificationDisplaySetting.enabled,
      canShowToast: true,
      canOpenSettings: true,
    );
  }

  @override
  Future<void> openNotificationSettingPage() async {}

  @override
  Future<WnsChannel> requestChannel() async {
    return WnsChannel(
      uri: 'https://notify.windows.com/channel/demo',
      expirationTime: DateTime.now().add(const Duration(days: 1)),
    );
  }

  @override
  Future<void> closeChannel() async {}

  @override
  Future<WnsActivation?> getInitialActivation() async {
    return const WnsToastActivation(
      kind: WnsToastActivationKind.launch,
      arguments: 'route=inbox&id=42',
      argumentMap: <String, String>{'route': 'inbox', 'id': '42'},
      data: <String, String>{'route': 'inbox', 'id': '42'},
      userInput: <String, String>{'action': 'view'},
      rawPayload: 'route=inbox&id=42',
    );
  }

  @override
  Stream<WnsMessage> get onMessage => _messageController.stream;

  @override
  Stream<WnsActivation> get onActivation => _activationController.stream;

  void addIncoming(WnsMessage message) {
    _messageController.add(message);
  }

  void addActivation(WnsActivation activation) {
    _activationController.add(activation);
  }
}
