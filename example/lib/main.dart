import 'package:flutter/material.dart';
import 'package:wns_flutter/wns_flutter.dart';

import 'package:wns_flutter_example/notification_setting_card.dart';
import 'package:wns_flutter_example/windows_notification_service_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

@immutable
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Windows Notification Service')),
        body: Center(
          child: ListView(
            children: [
              NotificationSettingCard(),
              WindowsNotificationServiceCard(),
            ],
          ),
        ),
      ),
    );
  }
}
