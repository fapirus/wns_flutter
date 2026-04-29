import 'package:wns_flutter/src/core/wns_lifecycle_manager.dart';
import 'package:wns_flutter/src/core/wns_platform_adapter.dart';
import 'package:wns_flutter/src/internal/wns_logger.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_channel.dart';
import 'package:wns_flutter/src/model/wns_message.dart';

class WnsClient {
  WnsClient(WnsPlatformAdapter adapter)
    : _adapter = adapter,
      _lifecycle = WnsLifecycleManager(adapter);

  final WnsPlatformAdapter _adapter;
  final WnsLifecycleManager _lifecycle;

  Stream<WnsMessage> get onMessage => _adapter.onMessage;

  Stream<WnsActivation> get onActivation => _adapter.onActivation;

  Future<void> initialize() {
    wnsDebugLog('WnsClient.initialize requested');
    return _lifecycle.initialize();
  }

  Future<WnsChannel> requestChannel() {
    wnsDebugLog('WnsClient.requestChannel requested');
    return _lifecycle.requestChannel();
  }

  Future<void> closeChannel() {
    wnsDebugLog('WnsClient.closeChannel requested');
    return _lifecycle.closeChannel();
  }

  Future<WnsActivation?> getInitialActivation() {
    wnsDebugLog('WnsClient.getInitialActivation requested');
    return _lifecycle.getInitialActivation();
  }

  Future<void> dispose() {
    wnsDebugLog('WnsClient.dispose requested');
    return _lifecycle.dispose();
  }
}
