import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/src/core/wns_notification_settings.dart';
import 'package:wns_flutter/src/exception/exception.dart';
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

    test('getInfo maps native setting failures to typed exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getNotificationSettingStatus') {
              throw PlatformException(
                code: 'NOTIFICATION_SETTING_FAILED',
                message: 'Failed to get notification setting.',
                details: 'HRESULT: 0x80070490',
              );
            }

            return null;
          });

      final settings = WnsNotificationSettings(
        settingService: const SettingService(channel),
      );

      await expectLater(
        settings.getInfo(),
        throwsA(
          isA<WnsNotificationSettingUnavailableException>().having(
            (value) => value.code,
            'code',
            'NOTIFICATION_SETTING_FAILED',
          ),
        ),
      );
    });

    test('openSettingsPage maps native launch failures to typed exceptions',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'openNotificationSettingPage') {
              throw PlatformException(
                code: 'SETTINGS_LAUNCH_FAILED',
                message: 'Failed to launch notification settings.',
              );
            }

            return null;
          });

      final settings = WnsNotificationSettings(
        settingService: const SettingService(channel),
      );

      await expectLater(
        settings.openSettingsPage(),
        throwsA(
          isA<WnsSettingsLaunchException>().having(
            (value) => value.code,
            'code',
            'SETTINGS_LAUNCH_FAILED',
          ),
        ),
      );
    });
  });
}
