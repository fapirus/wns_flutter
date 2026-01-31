import 'package:wns_flutter/src/exception/exception.dart';

import '../model/channel_uri.dart';
import '../model/notification.dart';

class WnsNotificationService {

  // Wns Channel uri 불러오기
  // WinRT API : PushNotificationChannelManager::CreatePushNotificationChannelForApplicationAsync()
  Future<ChannelUri> getChannelUri() {
    throw WnsUnknownException();
  }

  Future<WindowsNotification?> getLaunchNotification() {
    throw WnsUnknownException();
  }
}