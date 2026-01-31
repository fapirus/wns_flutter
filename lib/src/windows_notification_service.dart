import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wns_flutter/src/service/wns_service.dart';
import 'package:wns_flutter/src/service/wns_setting_service.dart';

import 'model/notification_setting.dart';

class WindowsNotificationService {
  static const MethodChannel _channel = MethodChannel('wns_flutter');

  static final WindowsNotificationService instance = WindowsNotificationService._();

  final WnsSettingService _wnsSettingService;
  final WnsService _wnsService;

  WindowsNotificationService._()
      : _wnsSettingService = WnsSettingService(),
        _wnsService = WnsService();

  /// ko: 플러그인을 초기화합니다.
  /// [aumId] (App User Model ID)는 패키징되지 않은 앱(Unpackaged App)을 식별하기 위해
  /// 디버그(Debug) 또는 프로필(Profile) 모드에서만 사용됩니다.
  /// 릴리즈(Release) 모드에서는 이 파라미터가 무시되며, 앱의 패키지 Identity(MSIX)가 자동으로 사용됩니다.
  ///
  /// en: Initialize the plugin.
  /// [aumId] (App User Model ID) is only used in Debug/Profile mode to identify
  /// unpackaged apps. In Release mode, this parameter is ignored and the
  /// application's package identity (MSIX) is used.
  static Future<void> initialize({String? aumId}) async {
    if (kReleaseMode) {
      if (aumId != null) {
        debugPrint(
          '[WnsFlutter] Warning: initialize() with aumid is ignored in Release mode. Using Package Identity.',
        );
      }
      return;
    }

    if (aumId != null) {
      try {
        await _channel.invokeMethod('initialize', {'aumid': aumId});
      } on PlatformException catch (e) {
        debugPrint('[WnsFlutter] Failed to initialize: ${e.message}');
      }
    }
  }

  Future<WnsNotificationStatus> getNotificationSettingStatus() {
    return _wnsSettingService.getNotificationSettingStatus();
  }

  Future<void> openNotificationSettingPage() {
    return _wnsSettingService.openNotificationSettingPage();
  }
}
