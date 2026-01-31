import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wns_flutter_method_channel.dart';

abstract class WnsFlutterPlatform extends PlatformInterface {
  /// Constructs a WnsFlutterPlatform.
  WnsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static WnsFlutterPlatform _instance = MethodChannelWnsFlutter();

  /// The default instance of [WnsFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelWnsFlutter].
  static WnsFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WnsFlutterPlatform] when
  /// they register themselves.
  static set instance(WnsFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
