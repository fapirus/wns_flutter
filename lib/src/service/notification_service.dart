import 'package:flutter/services.dart';
import 'package:wns_flutter/src/exception/exception.dart';

import '../model/channel_uri.dart';
import '../model/notification.dart';

class NotificationService {

  final MethodChannel _channel;

  const NotificationService(MethodChannel channel): _channel = channel;

  // Wns Channel uri 불러오기
  // WinRT API : PushNotificationChannelManager::CreatePushNotificationChannelForApplicationAsync()
  Future<ChannelUri> getChannelUri() {
    throw WnsUnknownException();
  }

  Future<WindowsNotification?> getLaunchNotification() {
    throw WnsUnknownException();
  }
}