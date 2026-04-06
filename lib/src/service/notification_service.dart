import 'package:flutter/services.dart';
import 'package:wns_flutter/src/exception/exception.dart';

import '../model/channel_uri.dart';
import '../model/notification.dart';

class NotificationService {
  static const String _getChannelUriMethod = 'getChannelUri';
  static const String _getInitialMessageMethod = 'getInitialMessage';
  static const String _setForegroundPresentationMethod =
      'setForegroundNotificationPresentation';

  NotificationService(
    MethodChannel channel, {
    EventChannel? messageChannel,
    EventChannel? messageOpenedAppChannel,
    Stream<dynamic>? messageStream,
    Stream<dynamic>? messageOpenedAppStream,
  }) : _channel = channel,
       _messageEvents =
           messageStream ??
           (messageChannel ?? const EventChannel('wns_flutter/message'))
               .receiveBroadcastStream(),
       _messageOpenedAppEvents =
           messageOpenedAppStream ??
           (messageOpenedAppChannel ??
                   const EventChannel('wns_flutter/message_opened_app'))
               .receiveBroadcastStream();

  final MethodChannel _channel;
  final Stream<dynamic> _messageEvents;
  final Stream<dynamic> _messageOpenedAppEvents;

  Stream<WindowsIncomingMessage> get onMessage =>
      _messageEvents.map(_parseIncomingMessageEvent);

  Stream<WindowsNotificationActivation> get onMessageOpenedApp =>
      _messageOpenedAppEvents.map(_parseActivationEvent);

  Future<ChannelUri> getChannelUri() async {
    try {
      final Map<Object?, Object?> result = await _channel.invokeMethod(
        _getChannelUriMethod,
      );

      final String uri = result['uri'] as String;
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

  Future<void> setForegroundNotificationPresentation({
    required bool alert,
  }) async {
    try {
      await _channel.invokeMethod<void>(_setForegroundPresentationMethod, {
        'alert': alert,
      });
    } on PlatformException catch (e) {
      throw WnsPlatformException.fromPlatformException(e);
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  Future<WindowsNotificationActivation?> getInitialMessage() async {
    try {
      final result = await _channel.invokeMethod<Object?>(
        _getInitialMessageMethod,
      );

      if (result == null) {
        return null;
      }

      return _parseActivationEvent(result);
    } on PlatformException catch (e) {
      throw WnsPlatformException.fromPlatformException(e);
    } on WnsException {
      rethrow;
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  WindowsIncomingMessage _parseIncomingMessageEvent(dynamic event) {
    final map = _requireMap(
      event,
      message: 'Expected incoming message event payload to be a map.',
      code: 'INVALID_MESSAGE_PAYLOAD',
    );

    return WindowsIncomingMessage.fromMap(map);
  }

  WindowsNotificationActivation _parseActivationEvent(dynamic event) {
    final map = _requireMap(
      event,
      message: 'Expected activation event payload to be a map.',
      code: 'INVALID_ACTIVATION_PAYLOAD',
    );

    return WindowsNotificationActivation.fromMap(map);
  }

  Map<Object?, Object?> _requireMap(
    dynamic value, {
    required String message,
    required String code,
  }) {
    if (value is Map<Object?, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<Object?, Object?>.from(value);
    }

    throw WnsMessageParseException(
      message: message,
      code: code,
      details: value,
    );
  }
}
