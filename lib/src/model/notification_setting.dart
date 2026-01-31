import 'package:flutter/widgets.dart';

@immutable
class WnsNotificationStatus {
  final WnsNotificationPermissionStatus status;
  final WnsWindowsNotificationSetting? windowsSetting;

  const WnsNotificationStatus({required this.status, this.windowsSetting});

  @override
  String toString() {
    return 'WnsNotificationStatus(status: $status, windowsSetting: $windowsSetting)';
  }
}

/// A status derived from the Windows notification setting.
enum WnsNotificationPermissionStatus {
  /// The user has not yet made a choice regarding whether the application
  /// may post user notifications.
  /// (Conceptually mapped; Windows defaults to 'authorized' usually)
  notDetermined,

  /// The application is authorized to post user notifications.
  authorized,

  /// The application is not authorized to post user notifications.
  denied,

  /// The application is provisionally authorized to post non-interruptive
  /// user notifications.
  provisional,
}

/// Raw Windows ToastNotifier.Setting values
/// Ref: https://learn.microsoft.com/en-us/uwp/api/windows.ui.notifications.notificationlooptmodewithtoastnotifier
enum WnsWindowsNotificationSetting {
  enabled,
  disabledForApplication,
  disabledForUser,
  disabledByGroupPolicy,
  disabledByManifest,
  unknown,
}
