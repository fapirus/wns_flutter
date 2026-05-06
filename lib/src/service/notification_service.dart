import 'package:flutter/services.dart';
import 'package:wns_flutter/src/codec/wns_native_event_codec.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/internal/wns_logger.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_channel.dart';
import 'package:wns_flutter/src/model/wns_message.dart';

class NotificationService {
  static const String _initializeMethod = 'initialize';
  static const String _closeChannelMethod = 'closeChannel';
  static const String _getChannelUriMethod = 'getChannelUri';
  static const String _getInitialMessageMethod = 'getInitialMessage';

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

  Stream<WnsMessage> get onMessage => _messageEvents.map(decodeWnsMessageEvent);

  Stream<WnsActivation> get onActivation => _messageOpenedAppEvents.map(
    (event) => decodeWnsActivationEvent(
      event,
      fallbackKind: WnsToastActivationKind.foregroundForward,
    ),
  );

  Future<void> initializePartnerCenter({String? appUserModelId}) async {
    try {
      wnsDebugLog('NotificationService.initializePartnerCenter invoke');
      final arguments = <String, Object?>{};
      if (appUserModelId != null) {
        arguments['appUserModelId'] = appUserModelId;
      }

      await _channel.invokeMethod<void>(_initializeMethod, arguments);
    } on PlatformException catch (e) {
      throw wnsExceptionFromPlatformException(e);
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  Future<WnsChannel> requestChannel() async {
    try {
      wnsDebugLog('NotificationService.requestChannel invoke');
      final Map<Object?, Object?> result = await _channel.invokeMethod(
        _getChannelUriMethod,
      );

      final String uri = result['uri'] as String;
      final int expirationMillis = result['expirationTime'] as int;

      return WnsChannel(
        uri: uri,
        expirationTime: DateTime.fromMillisecondsSinceEpoch(expirationMillis),
      );
    } on PlatformException catch (e) {
      throw wnsExceptionFromPlatformException(e);
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  Future<void> closeChannel() async {
    try {
      wnsDebugLog('NotificationService.closeChannel invoke');
      await _channel.invokeMethod<void>(_closeChannelMethod);
    } on PlatformException catch (e) {
      throw wnsExceptionFromPlatformException(e);
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  Future<WnsActivation?> getInitialActivation() async {
    try {
      wnsDebugLog('NotificationService.getInitialActivation invoke');
      final result = await _channel.invokeMethod<Object?>(
        _getInitialMessageMethod,
      );

      if (result == null) {
        return null;
      }

      return decodeWnsActivationEvent(
        result,
        fallbackKind: WnsToastActivationKind.launch,
      );
    } on PlatformException catch (e) {
      throw wnsExceptionFromPlatformException(e);
    } on WnsException {
      rethrow;
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }
}
