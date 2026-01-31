import 'package:flutter/services.dart';
import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/notification_setting.dart';

class WnsSettingService {
  final MethodChannel _channel = const MethodChannel('wns_flutter');

  Future<WnsNotificationStatus> getNotificationSettingStatus() async {
    try {
      final int result = await _channel.invokeMethod(
        'getNotificationSettingStatus',
      );
      return _mapToNotificationStatus(result);
    } on PlatformException catch (e) {
      throw WnsPlatformException.fromPlatformException(e);
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  Future<void> openNotificationSettingPage() async {
    try {
      await _channel.invokeMethod('openNotificationSettingPage');
    } on PlatformException catch (e) {
      throw WnsPlatformException.fromPlatformException(e);
    } catch (e, stack) {
      throw WnsUnknownException(message: e.toString(), stackTrace: stack);
    }
  }

  WnsNotificationStatus _mapToNotificationStatus(int nativeSetting) {
    // Mapping rules based on Windows NotificationSetting enum
    // 0: Enabled
    // 1: DisabledForApplication
    // 2: DisabledForUser
    // 3: DisabledByGroupPolicy
    // 4: DisabledByManifest

    WnsWindowsNotificationSetting windowsSetting;
    WnsNotificationPermissionStatus permissionStatus;

    switch (nativeSetting) {
      case 0:
        windowsSetting = WnsWindowsNotificationSetting.enabled;
        permissionStatus = WnsNotificationPermissionStatus.authorized;
        break;
      case 1:
        windowsSetting = WnsWindowsNotificationSetting.disabledForApplication;
        permissionStatus = WnsNotificationPermissionStatus.denied;
        break;
      case 2:
        windowsSetting = WnsWindowsNotificationSetting.disabledForUser;
        permissionStatus = WnsNotificationPermissionStatus.denied;
        break;
      case 3:
        windowsSetting = WnsWindowsNotificationSetting.disabledByGroupPolicy;
        permissionStatus = WnsNotificationPermissionStatus.denied;
        break;
      case 4:
        windowsSetting = WnsWindowsNotificationSetting.disabledByManifest;
        permissionStatus = WnsNotificationPermissionStatus.denied;
        break;
      default:
        windowsSetting = WnsWindowsNotificationSetting.unknown;
        permissionStatus = WnsNotificationPermissionStatus.notDetermined;
    }

    return WnsNotificationStatus(
      status: permissionStatus,
      windowsSetting: windowsSetting,
    );
  }
}
