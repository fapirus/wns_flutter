import 'package:flutter/services.dart';
import 'package:wns_flutter/src/config/partner_center_wns_options.dart';
import 'package:wns_flutter/src/core/wns_platform_adapter.dart';
import 'package:wns_flutter/src/internal/wns_logger.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_channel.dart';
import 'package:wns_flutter/src/model/wns_message.dart';
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
    return _notificationService.onMessage;
  }

  @override
  Stream<WnsActivation> get onActivation {
    return _notificationService.onActivation;
  }

  @override
  Future<void> initialize() {
    wnsDebugLog('PartnerCenterWnsAdapter.initialize started');
    return _notificationService.initializePartnerCenter(
      appUserModelId: _options.appUserModelId,
      suppressForegroundToasts: _options.suppressForegroundToasts,
    );
  }

  @override
  Future<WnsChannel> requestChannel() async {
    wnsDebugLog('PartnerCenterWnsAdapter.requestChannel started');
    final channel = await _notificationService.requestChannel();
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
    final activation = await _notificationService.getInitialActivation();
    if (activation == null) {
      wnsDebugLog('PartnerCenterWnsAdapter.getInitialActivation empty');
      return null;
    }

    wnsDebugLog('PartnerCenterWnsAdapter.getInitialActivation completed');
    return activation;
  }

  @override
  Future<void> dispose() {
    wnsDebugLog('PartnerCenterWnsAdapter.dispose started');
    return closeChannel();
  }
}
