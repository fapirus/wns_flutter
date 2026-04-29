import 'package:wns_flutter/src/core/wns_platform_adapter.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/internal/wns_logger.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_channel.dart';

class WnsLifecycleManager {
  WnsLifecycleManager(this._adapter);

  final WnsPlatformAdapter _adapter;

  bool _initialized = false;
  bool _disposed = false;

  bool get isInitialized => _initialized;

  bool get isDisposed => _disposed;

  Future<void> initialize() async {
    _ensureNotDisposed();

    if (_initialized) {
      wnsDebugLog('WnsLifecycleManager.initialize skipped: already initialized');
      return;
    }

    wnsDebugLog('WnsLifecycleManager.initialize adapter call started');
    await _adapter.initialize();
    _initialized = true;
    wnsDebugLog('WnsLifecycleManager.initialize completed');
  }

  Future<WnsChannel> requestChannel() async {
    _ensureReady();
    return _adapter.requestChannel();
  }

  Future<void> closeChannel() async {
    _ensureReady();
    return _adapter.closeChannel();
  }

  Future<WnsActivation?> getInitialActivation() async {
    _ensureReady();
    return _adapter.getInitialActivation();
  }

  Future<void> dispose() async {
    if (_disposed) {
      wnsDebugLog('WnsLifecycleManager.dispose skipped: already disposed');
      return;
    }

    wnsDebugLog('WnsLifecycleManager.dispose adapter call started');
    _disposed = true;
    _initialized = false;
    await _adapter.dispose();
    wnsDebugLog('WnsLifecycleManager.dispose completed');
  }

  void _ensureReady() {
    _ensureNotDisposed();

    if (!_initialized) {
      wnsDebugLog('WnsLifecycleManager guard failed: not initialized');
      throw const WnsNotInitializedException();
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      wnsDebugLog('WnsLifecycleManager guard failed: disposed');
      throw const WnsDisposedException();
    }
  }
}
