import 'package:flutter/foundation.dart';
import 'package:wns_flutter/src/model/notification_setting.dart';

@immutable
class WnsNotificationSettingsInfo {
  const WnsNotificationSettingsInfo({
    required this.status,
    required this.displaySetting,
    required this.canShowToast,
    required this.canOpenSettings,
  });

  factory WnsNotificationSettingsInfo.fromStatus(
    WnsNotificationStatus status,
  ) {
    final displaySetting = _toDisplaySetting(status.windowsSetting);

    return WnsNotificationSettingsInfo(
      status: status.status,
      displaySetting: displaySetting,
      canShowToast: displaySetting == WnsNotificationDisplaySetting.enabled,
      canOpenSettings: true,
    );
  }

  final WnsNotificationPermissionStatus status;
  final WnsNotificationDisplaySetting displaySetting;
  final bool canShowToast;
  final bool canOpenSettings;

  @override
  String toString() {
    return 'WnsNotificationSettingsInfo('
        'status: $status, '
        'displaySetting: $displaySetting, '
        'canShowToast: $canShowToast, '
        'canOpenSettings: $canOpenSettings'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsNotificationSettingsInfo &&
            other.status == status &&
            other.displaySetting == displaySetting &&
            other.canShowToast == canShowToast &&
            other.canOpenSettings == canOpenSettings;
  }

  @override
  int get hashCode {
    return Object.hash(status, displaySetting, canShowToast, canOpenSettings);
  }
}

enum WnsNotificationDisplaySetting {
  enabled,
  disabledForApplication,
  disabledForUser,
  disabledByGroupPolicy,
  disabledByManifest,
  unknown,
}

WnsNotificationDisplaySetting _toDisplaySetting(
  WnsWindowsNotificationSetting? setting,
) {
  switch (setting) {
    case WnsWindowsNotificationSetting.enabled:
      return WnsNotificationDisplaySetting.enabled;
    case WnsWindowsNotificationSetting.disabledForApplication:
      return WnsNotificationDisplaySetting.disabledForApplication;
    case WnsWindowsNotificationSetting.disabledForUser:
      return WnsNotificationDisplaySetting.disabledForUser;
    case WnsWindowsNotificationSetting.disabledByGroupPolicy:
      return WnsNotificationDisplaySetting.disabledByGroupPolicy;
    case WnsWindowsNotificationSetting.disabledByManifest:
      return WnsNotificationDisplaySetting.disabledByManifest;
    case WnsWindowsNotificationSetting.unknown:
    case null:
      return WnsNotificationDisplaySetting.unknown;
  }
}
