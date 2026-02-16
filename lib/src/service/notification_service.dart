import 'package:flutter/services.dart';
import 'package:wns_flutter/src/exception/exception.dart';

import '../model/channel_uri.dart';
import '../model/notification.dart';

class NotificationService {
  final MethodChannel _channel;
  final EventChannel _eventChannel;

  const NotificationService(MethodChannel channel, EventChannel eventChannel)
    : _channel = channel,
      _eventChannel = eventChannel;

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

  Stream<WindowsNotification> onMessage() {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        return WindowsNotification.fromMap(event);
      }

      throw WnsUnknownException(
        message: 'Unexpected message payload type: ${event.runtimeType}',
      );
    });
  }
}
