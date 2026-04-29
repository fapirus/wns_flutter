import 'package:flutter/services.dart';
import 'package:wns_flutter/src/config/partner_center_wns_options.dart';
import 'package:wns_flutter/src/core/wns_platform_adapter.dart';
import 'package:wns_flutter/src/internal/wns_logger.dart';
import 'package:wns_flutter/src/model/channel_uri.dart';
import 'package:wns_flutter/src/model/notification.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_channel.dart';
import 'package:wns_flutter/src/model/wns_message.dart';
import 'package:wns_flutter/src/model/wns_notification_type.dart';
import 'package:wns_flutter/src/model/wns_payload.dart';
import 'package:wns_flutter/src/service/notification_service.dart';

class PartnerCenterWnsAdapter implements WnsPlatformAdapter {
  PartnerCenterWnsAdapter({
    PartnerCenterWnsOptions options = const PartnerCenterWnsOptions(),
    NotificationService? notificationService,
  }) : _options = options,
       _notificationService =
           notificationService ??
           NotificationService(const MethodChannel('wns_flutter'));

  final PartnerCenterWnsOptions _options;
  final NotificationService _notificationService;

  @override
  Stream<WnsMessage> get onMessage {
    return _notificationService.onMessage.map(_toWnsMessage);
  }

  @override
  Stream<WnsActivation> get onActivation {
    return _notificationService.onMessageOpenedApp.map(
      (activation) => _toWnsActivation(
        activation,
        kind: WnsActivationKind.foregroundForward,
      ),
    );
  }

  @override
  Future<void> initialize() {
    wnsDebugLog('PartnerCenterWnsAdapter.initialize started');
    return _notificationService.initializePartnerCenter(
      appUserModelId: _options.appUserModelId,
    );
  }

  @override
  Future<WnsChannel> requestChannel() async {
    wnsDebugLog('PartnerCenterWnsAdapter.requestChannel started');
    final channel = _toWnsChannel(await _notificationService.getChannelUri());
    wnsDebugLog(
      'PartnerCenterWnsAdapter.requestChannel completed: '
      'expires=${channel.expirationTime.toIso8601String()}',
    );
    return channel;
  }

  @override
  Future<void> closeChannel() {
    wnsDebugLog('PartnerCenterWnsAdapter.closeChannel started');
    return _notificationService.closeChannel();
  }

  @override
  Future<WnsActivation?> getInitialActivation() async {
    wnsDebugLog('PartnerCenterWnsAdapter.getInitialActivation started');
    final activation = await _notificationService.getInitialMessage();
    if (activation == null) {
      wnsDebugLog('PartnerCenterWnsAdapter.getInitialActivation empty');
      return null;
    }

    wnsDebugLog('PartnerCenterWnsAdapter.getInitialActivation completed');
    return _toWnsActivation(activation, kind: WnsActivationKind.launch);
  }

  @override
  Future<void> dispose() {
    wnsDebugLog('PartnerCenterWnsAdapter.dispose started');
    return closeChannel();
  }

  WnsChannel _toWnsChannel(ChannelUri channel) {
    return WnsChannel(
      uri: channel.uri,
      expirationTime: channel.expirationTime,
    );
  }

  WnsMessage _toWnsMessage(WindowsIncomingMessage message) {
    return WnsMessage(
      type: WnsNotificationType.toast,
      payload: _toWnsPayload(
        arguments: message.arguments,
        argumentMap: message.argumentMap,
        payload: message.payload,
        treatRawPayloadAsXml: true,
      ),
      receivedAt: message.receivedAt ?? DateTime.now(),
      source: WnsMessageSource.foreground,
    );
  }

  WnsActivation _toWnsActivation(
    WindowsNotificationActivation activation, {
    required WnsActivationKind kind,
  }) {
    return WnsActivation(
      type: WnsNotificationType.toast,
      kind: kind,
      payload: _toWnsPayload(
        arguments: activation.arguments,
        argumentMap: activation.argumentMap,
        payload: activation.payload,
      ),
      userInput: activation.userInput,
    );
  }

  WnsPayload _toWnsPayload({
    required String arguments,
    required Map<String, String> argumentMap,
    required WindowsNotificationPayload payload,
    bool treatRawPayloadAsXml = false,
  }) {
    return WnsPayload(
      rawText: treatRawPayloadAsXml ? null : payload.rawPayload,
      xml: treatRawPayloadAsXml ? payload.rawPayload : null,
      data: payload.data,
      launchArguments: arguments.isEmpty ? null : arguments,
      launchArgumentMap: argumentMap,
    );
  }
}
