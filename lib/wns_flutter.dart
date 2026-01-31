
import 'wns_flutter_platform_interface.dart';

class WnsFlutter {
  Future<String?> getPlatformVersion() {
    return WnsFlutterPlatform.instance.getPlatformVersion();
  }
}
