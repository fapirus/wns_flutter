import 'package:flutter/material.dart';

import 'package:wns_flutter_example/notification_setting_card.dart';
import 'package:wns_flutter_example/windows_notification_service_card.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(client: DefaultWnsDemoClient()));
}

@immutable
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.client});

  final WnsDemoClient client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Windows Notification Service')),
        body: Center(
          child: ListView(
            children: [
              NotificationSettingCard(client: client),
              WindowsNotificationServiceCard(client: client),
            ],
          ),
        ),
      ),
    );
  }
}
