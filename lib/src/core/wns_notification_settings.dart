import 'package:flutter/services.dart';
import 'package:wns_flutter/src/model/wns_notification_settings_info.dart';
import 'package:wns_flutter/src/service/setting_service.dart';

class WnsNotificationSettings {
  WnsNotificationSettings({SettingService? settingService})
    : _settingService =
          settingService ?? SettingService(const MethodChannel('wns_flutter'));

  final SettingService _settingService;

  Future<WnsNotificationSettingsInfo> getInfo() async {
    final status = await _settingService.getNotificationSettingStatus();
    return WnsNotificationSettingsInfo.fromStatus(status);
  }

  Future<void> openSettingsPage() async {
    await _settingService.openNotificationSettingPage();
  }
}
