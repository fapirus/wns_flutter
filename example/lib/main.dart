import 'package:flutter/material.dart';
import 'package:wns_flutter/wns_flutter.dart';

import 'package:wns_flutter_example/notification_setting_card.dart';
import 'package:wns_flutter_example/windows_notification_service_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: This AUMID is for debugging purposes only.
  // In a real MSIX packaged app, 'initialize' should typically not be called
  // (or called without arguments to rely on Package Identity).
  // For 'flutter run -d windows' (unpackaged), you must provide a valid AUMID
  // that is registered in the system or reuse an existing one for testing.
  //
  // Example using Microsoft Edge's ID for quick testing:
  await WindowsNotificationService.instance.initialize(
    aumId: 'Microsoft.WindowsStore_8wekyb3d8bbwe!App',
  );

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
