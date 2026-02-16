import 'package:flutter/services.dart';
import 'package:wns_flutter/src/model/channel_uri.dart';
import 'package:wns_flutter/src/model/notification.dart';
import 'package:wns_flutter/src/service/notification_service.dart';
import 'package:wns_flutter/src/service/setting_service.dart';

import 'model/notification_setting.dart';

class WindowsNotificationService {
  static const MethodChannel _channel = MethodChannel('wns_flutter');
  static const EventChannel _messageChannel = EventChannel(
    'wns_flutter/on_message',
  );

  static final WindowsNotificationService instance =
      WindowsNotificationService._();

  final SettingService _wnsSettingService;
  final NotificationService _wnsNotificationService;

  WindowsNotificationService._()
    : _wnsSettingService = SettingService(_channel),
      _wnsNotificationService = NotificationService(_channel, _messageChannel);

  /// ko: 현재 앱의 알림 설정 상태를 조회합니다.
  /// 결과는 [WnsNotificationStatus] 객체로 반환되며, 시스템 및 앱의 알림 권한 상태를 포함합니다.
  ///
  /// en: Retrieves the current notification setting status of the application.
  /// Returns a [WnsNotificationStatus] object containing system and app notification permission statuses.
  Future<WnsNotificationStatus> getNotificationSettingStatus() {
    return _wnsSettingService.getNotificationSettingStatus();
  }

  /// ko: Windows 시스템 알림 설정 페이지를 엽니다.
  /// 이 메서드는 'ms-settings:notifications' URI를 실행합니다.
  ///
  /// en: Opens the Windows system notification settings page.
  /// This method launches the 'ms-settings:notifications' URI.
  Future<void> openNotificationSettingPage() {
    return _wnsSettingService.openNotificationSettingPage();
  }

  /// ko: WNS (Windows Notification Service) 채널 URI를 요청합니다.
  /// 이 URI는 푸시 알림을 보내는 서버(Provider)에 등록하여 사용합니다.
  ///
  /// en: Requests a WNS (Windows Notification Service) Channel URI.
  /// This URI should be registered with your Push Notification Provider to send notifications.
  Future<ChannelUri> getChannelUri() {
    return _wnsNotificationService.getChannelUri();
  }

  /// ko: 앱이 실행 중일 때 수신되는 WNS 푸시 메시지 스트림입니다.
  ///
  /// en: Stream of WNS push messages received while the app is running.
  Stream<WindowsNotification> onMessage() {
    return _wnsNotificationService.onMessage();
  }

  /// ko: 앱이 알림을 클릭하여 실행되었을 때, 해당 알림의 정보를 가져옵니다.
  /// 앱이 이미 실행 중일 때는 null을 반환할 수 있습니다.
  ///
  /// en: Retrieves the notification information if the app was launched by clicking a notification.
  /// May return null if the app was not launched via a notification.

  // TODO
  // Future<WindowsNotification?> getLaunchNotification() {
  //   return _wnsNotificationService.getLaunchNotification();
  // }
}
