import 'package:flutter/foundation.dart';

void wnsDebugLog(String message) {
  assert(() {
    debugPrint('[wns_flutter] $message');
    return true;
  }());
}
