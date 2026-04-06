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
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final client = _FakeWnsDemoClient();

      await tester.pumpWidget(MyApp(client: client));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('desktop-shell')), findsOneWidget);
      expect(
        find.text('Desktop-style WNS validation console'),
        findsOneWidget,
      );
      expect(find.text('Notification Setting'), findsOneWidget);
      expect(find.text('Windows Notification Service'), findsWidgets);
      expect(find.text('Event Timeline'), findsOneWidget);
      expect(find.text('Show foreground toast'), findsOneWidget);
      expect(find.text('Clear Event Logs'), findsOneWidget);
      expect(find.byKey(const ValueKey('theme-mode-menu')), findsOneWidget);
      expect(find.textContaining('route=inbox&id=42'), findsOneWidget);
      expect(find.text('Initial Message Checked At'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(client.alertCalls, <bool>[false]);

      await tester.tap(find.text('Get Status'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notification-status-value')), findsOneWidget);
      expect(find.textContaining('authorized'), findsWidgets);

      await tester.tap(find.text('Get Channel URI'));
      await tester.pumpAndSettle();
      expect(find.textContaining('https://notify.windows.com/channel/demo'), findsOneWidget);

      client.addIncoming(
        WindowsIncomingMessage(
          arguments: 'route=orders&id=100',
          argumentMap: const <String, String>{'route': 'orders', 'id': '100'},
          payload: const WindowsNotificationPayload(
            data: <String, String>{'route': 'orders', 'id': '100'},
            rawPayload: '<toast>orders-100</toast>',
          ),
          receivedAt: DateTime(2025, 1, 2, 10, 11, 12),
        ),
      );
      client.addIncoming(
        WindowsIncomingMessage(
          arguments: 'route=orders&id=101',
          argumentMap: const <String, String>{'route': 'orders', 'id': '101'},
          payload: const WindowsNotificationPayload(
            data: <String, String>{'route': 'orders', 'id': '101'},
            rawPayload: '<toast>orders-101</toast>',
          ),
          receivedAt: DateTime(2025, 1, 2, 10, 12, 13),
        ),
      );
      client.addOpenedApp(
        WindowsNotificationActivation(
          arguments: 'route=settings&action=open',
          argumentMap: const <String, String>{
            'route': 'settings',
            'action': 'open',
          },
          payload: const WindowsNotificationPayload(
            data: <String, String>{'route': 'settings', 'action': 'open'},
            rawPayload: '<toast>settings</toast>',
          ),
          userInput: const <String, String>{'action': 'open'},
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Foreground'), findsNWidgets(2));
      expect(find.text('Opened App'), findsOneWidget);
      expect(
        find.textContaining('route=orders&id=100', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('route=orders&id=101', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('action=open', findRichText: true),
        findsWidgets,
      );

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('clear-event-logs-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('empty-timeline-message')), findsOneWidget);
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
  final StreamController<WindowsIncomingMessage> _messageController =
      StreamController<WindowsIncomingMessage>.broadcast();
  final StreamController<WindowsNotificationActivation>
  _openedAppController =
      StreamController<WindowsNotificationActivation>.broadcast();

  final List<bool> alertCalls = <bool>[];

  @override
  Future<WnsNotificationStatus> getNotificationSettingStatus() async {
    return const WnsNotificationStatus(
      status: WnsNotificationPermissionStatus.authorized,
    );
  }

  @override
  Future<void> openNotificationSettingPage() async {}

  @override
  Future<ChannelUri> getChannelUri() async {
    return ChannelUri(
      uri: 'https://notify.windows.com/channel/demo',
      expirationTime: DateTime(2025, 1, 2, 3, 4, 5),
    );
  }

  @override
  Future<WindowsNotificationActivation?> getInitialMessage() async {
    return WindowsNotificationActivation(
      arguments: 'route=inbox&id=42',
      argumentMap: const <String, String>{'route': 'inbox', 'id': '42'},
      payload: const WindowsNotificationPayload(
        data: <String, String>{'route': 'inbox', 'id': '42'},
      ),
      userInput: const <String, String>{'action': 'view'},
    );
  }

  @override
  Stream<WindowsIncomingMessage> get onMessage => _messageController.stream;

  @override
  Stream<WindowsNotificationActivation> get onMessageOpenedApp =>
      _openedAppController.stream;

  @override
  Future<void> setForegroundNotificationPresentation({
    required bool alert,
  }) async {
    alertCalls.add(alert);
  }

  void addIncoming(WindowsIncomingMessage message) {
    _messageController.add(message);
  }

  void addOpenedApp(WindowsNotificationActivation activation) {
    _openedAppController.add(activation);
  }
}
