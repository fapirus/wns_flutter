import 'package:wns_flutter/wns_flutter.dart';

abstract class WnsDemoClient {
  Future<WnsNotificationStatus> getNotificationSettingStatus();

  Future<void> openNotificationSettingPage();

  Future<ChannelUri> getChannelUri();

  Future<void> setForegroundNotificationPresentation({required bool alert});

  Future<WindowsNotificationActivation?> getInitialMessage();

  Stream<WindowsIncomingMessage> get onMessage;

  Stream<WindowsNotificationActivation> get onMessageOpenedApp;
}

class DefaultWnsDemoClient implements WnsDemoClient {
  DefaultWnsDemoClient({WindowsNotificationService? service})
    : _service = service ?? WindowsNotificationService.instance;

  final WindowsNotificationService _service;

  @override
  Future<WnsNotificationStatus> getNotificationSettingStatus() {
    return _service.getNotificationSettingStatus();
  }

  @override
  Future<void> openNotificationSettingPage() {
    return _service.openNotificationSettingPage();
  }

  @override
  Future<ChannelUri> getChannelUri() {
    return _service.getChannelUri();
  }

  @override
  Future<void> setForegroundNotificationPresentation({required bool alert}) {
    return _service.setForegroundNotificationPresentation(alert: alert);
  }

  @override
  Future<WindowsNotificationActivation?> getInitialMessage() {
    return _service.getInitialMessage();
  }

  @override
  Stream<WindowsIncomingMessage> get onMessage {
    return _service.onMessage;
  }

  @override
  Stream<WindowsNotificationActivation> get onMessageOpenedApp {
    return _service.onMessageOpenedApp;
  }
}
