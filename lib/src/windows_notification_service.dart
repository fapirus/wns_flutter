import 'package:flutter/services.dart';
import 'package:wns_flutter/src/model/channel_uri.dart';
import 'package:wns_flutter/src/model/notification.dart';
import 'package:wns_flutter/src/service/notification_service.dart';
import 'package:wns_flutter/src/service/setting_service.dart';

import 'model/notification_setting.dart';

class WindowsNotificationService {
  static const MethodChannel _channel = MethodChannel('wns_flutter');

  static final WindowsNotificationService instance =
      WindowsNotificationService._();

  final SettingService _wnsSettingService;
  final NotificationService _wnsNotificationService;

  WindowsNotificationService._()
    : _wnsSettingService = SettingService(_channel),
      _wnsNotificationService = NotificationService(_channel);

  Future<WnsNotificationStatus> getNotificationSettingStatus() {
    return _wnsSettingService.getNotificationSettingStatus();
  }

  Future<void> openNotificationSettingPage() {
    return _wnsSettingService.openNotificationSettingPage();
  }

  Future<ChannelUri> getChannelUri() {
    return _wnsNotificationService.getChannelUri();
  }

  Future<WindowsNotificationActivation?> getInitialMessage() {
    return _wnsNotificationService.getInitialMessage();
  }

  Stream<WindowsIncomingMessage> get onMessage {
    return _wnsNotificationService.onMessage;
  }

  Stream<WindowsNotificationActivation> get onMessageOpenedApp {
    return _wnsNotificationService.onMessageOpenedApp;
  }
}
