import 'package:flutter/services.dart';
import 'package:wns_flutter/src/exception/exception.dart';

import '../model/channel_uri.dart';
import '../model/notification.dart';

class NotificationService {
  final MethodChannel _channel;

  const NotificationService(MethodChannel channel) : _channel = channel;

  // Wns Channel uri 불러오기
  // WinRT API : PushNotificationChannelManager::CreatePushNotificationChannelForApplicationAsync()
  Future<ChannelUri> getChannelUri() async {
    try {
      final Map<Object?, Object?> result = await _channel.invokeMethod(
        'getChannelUri',
      );

      final String uri = result['uri'] as String;
      // Expiration time is returned as milliseconds since epoch from native side
      final int expirationMillis = result['expirationTime'] as int;

      return ChannelUri(
        uri: uri,
        expirationTime: DateTime.fromMillisecondsSinceEpoch(expirationMillis),
      );
    } on PlatformException catch (e) {
      throw WnsPlatformException.fromPlatformException(e);
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  Future<WindowsNotification?> getLaunchNotification() {
    throw WnsUnknownException();
  }
}
