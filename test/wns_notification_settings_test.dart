import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/core/wns_notification_settings.dart';
import 'package:wns_flutter/src/model/notification_setting.dart';
import 'package:wns_flutter/src/model/wns_notification_settings_info.dart';
import 'package:wns_flutter/src/service/setting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('wns_flutter');

  group('WnsNotificationSettings', () {
    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getInfo maps enabled native setting', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getNotificationSettingStatus') {
              return 0;
            }

            return null;
          });

      final settings = WnsNotificationSettings(
        settingService: const SettingService(channel),
      );

      final info = await settings.getInfo();

      expect(info.status, WnsNotificationPermissionStatus.authorized);
      expect(info.displaySetting, WnsNotificationDisplaySetting.enabled);
      expect(info.canShowToast, isTrue);
      expect(info.canOpenSettings, isTrue);
    });

    test('getInfo maps unknown native setting', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getNotificationSettingStatus') {
              return 99;
            }

            return null;
          });

      final settings = WnsNotificationSettings(
        settingService: const SettingService(channel),
      );

      final info = await settings.getInfo();

      expect(info.status, WnsNotificationPermissionStatus.unknown);
      expect(info.displaySetting, WnsNotificationDisplaySetting.unknown);
      expect(info.canShowToast, isFalse);
    });
  });
}
