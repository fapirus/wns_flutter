import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wns_flutter_platform_interface.dart';

/// An implementation of [WnsFlutterPlatform] that uses method channels.
class MethodChannelWnsFlutter extends WnsFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wns_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
