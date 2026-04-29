import 'package:flutter/services.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/wns_notification_settings_info.dart';
import 'package:wns_flutter/src/service/setting_service.dart';

class WnsNotificationSettings {
  WnsNotificationSettings({SettingService? settingService})
    : _settingService =
          settingService ?? SettingService(const MethodChannel('wns_flutter'));

  final SettingService _settingService;

  Future<WnsNotificationSettingsInfo> getInfo() async {
    try {
      final status = await _settingService.getNotificationSettingStatus();
      return WnsNotificationSettingsInfo.fromStatus(status);
    } on WnsPackageIdentityNotFoundException {
      rethrow;
    } on WnsPlatformException catch (e, stack) {
      throw WnsNotificationSettingUnavailableException(
        message: e.message,
        code: e.code,
        details: e.details,
        stackTrace: stack,
      );
    }
  }

  Future<void> openSettingsPage() async {
    try {
      await _settingService.openNotificationSettingPage();
    } on WnsPlatformException catch (e, stack) {
      throw WnsSettingsLaunchException(
        message: e.message,
        code: e.code,
        details: e.details,
        stackTrace: stack,
      );
    }
  }
}
