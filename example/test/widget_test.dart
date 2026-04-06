import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/wns_flutter.dart';
import 'package:wns_flutter_example/main.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';

void main() {
  testWidgets('renders WNS lifecycle state and reacts to demo actions', (
    WidgetTester tester,
  ) async {
    final client = FakeWnsDemoClient(
      initialMessage: WindowsNotificationActivation.fromMap({
        'arguments': 'route=inbox&id=42',
        'data': {'route': 'inbox', 'id': '42'},
      }),
      channelUri: ChannelUri(
        uri: 'https://notify.windows.com/?token=demo',
        expirationTime: DateTime(2026, 3, 15),
      ),
    );
    addTearDown(client.dispose);

    await tester.pumpWidget(MyApp(client: client));
    await tester.pump();

    expect(find.text('Notification Setting'), findsOneWidget);
    expect(find.text('Show foreground toast'), findsOneWidget);
    expect(find.textContaining('route=inbox&id=42'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(client.alertCalls, <bool>[false]);

    await tester.tap(find.text('Get Status'));
    await tester.pump();
    expect(find.byKey(const ValueKey('notification-status-value')), findsOneWidget);
    expect(find.textContaining('authorized'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(ElevatedButton, 'Get Channel URI'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Channel URI'));
    await tester.pump();
    expect(
      find.textContaining('https://notify.windows.com/?token=demo'),
      findsOneWidget,
    );

    client.messageController.add(
      WindowsIncomingMessage.fromMap({
        'arguments': 'route=thread&id=7',
        'rawPayload': '<toast launch="route=thread&amp;id=7" />',
      }),
    );
    await tester.pump();
    expect(find.textContaining('route=thread&id=7'), findsOneWidget);

    client.openedController.add(
      WindowsNotificationActivation.fromMap({
        'arguments': 'route=detail&id=9',
        'userInput': {'action': 'open'},
      }),
    );
    await tester.pump();
    expect(find.textContaining('route=detail&id=9'), findsOneWidget);
    expect(find.textContaining('action'), findsOneWidget);
  });
}

class FakeWnsDemoClient implements WnsDemoClient {
  FakeWnsDemoClient({
    required this.initialMessage,
    required this.channelUri,
  });

  final WindowsNotificationActivation? initialMessage;
  final ChannelUri channelUri;
  final StreamController<WindowsIncomingMessage> messageController =
      StreamController<WindowsIncomingMessage>.broadcast();
  final StreamController<WindowsNotificationActivation> openedController =
      StreamController<WindowsNotificationActivation>.broadcast();
  final List<bool> alertCalls = <bool>[];

  @override
  Future<ChannelUri> getChannelUri() async => channelUri;

  @override
  Future<WindowsNotificationActivation?> getInitialMessage() async {
    return initialMessage;
  }

  @override
  Future<WnsNotificationStatus> getNotificationSettingStatus() async {
    return const WnsNotificationStatus(
      status: WnsNotificationPermissionStatus.authorized,
      windowsSetting: WnsWindowsNotificationSetting.enabled,
    );
  }

  @override
  Stream<WindowsIncomingMessage> get onMessage => messageController.stream;

  @override
  Stream<WindowsNotificationActivation> get onMessageOpenedApp =>
      openedController.stream;

  @override
  Future<void> openNotificationSettingPage() async {}

  @override
  Future<void> setForegroundNotificationPresentation({
    required bool alert,
  }) async {
    alertCalls.add(alert);
  }

  Future<void> dispose() async {
    await messageController.close();
    await openedController.close();
  }
}
