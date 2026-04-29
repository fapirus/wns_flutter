import 'package:wns_flutter/wns_flutter.dart';

abstract class WnsDemoClient {
  Future<void> initialize();

  Future<WnsNotificationSettingsInfo> getNotificationSettingsInfo();

  Future<void> openNotificationSettingPage();

  Future<WnsChannel> requestChannel();

  Future<void> closeChannel();

  Future<void> setForegroundNotificationPresentation({required bool alert});

  Future<WnsActivation?> getInitialActivation();

  Stream<WnsMessage> get onMessage;

  Stream<WnsActivation> get onActivation;
}

class DefaultWnsDemoClient implements WnsDemoClient {
  DefaultWnsDemoClient({
    WnsClient? client,
    WnsNotificationSettings? settings,
    WindowsNotificationService? legacyService,
  }) : _client =
           client ??
           const WnsClientBuilder().create(const PartnerCenterWnsOptions()),
       _settings = settings ?? WnsNotificationSettings(),
       _legacyService = legacyService ?? WindowsNotificationService.instance;

  final WnsClient _client;
  final WnsNotificationSettings _settings;
  final WindowsNotificationService _legacyService;

  @override
  Future<void> initialize() {
    return _client.initialize();
  }

  @override
  Future<WnsNotificationSettingsInfo> getNotificationSettingsInfo() {
    return _settings.getInfo();
  }

  @override
  Future<void> openNotificationSettingPage() {
    return _settings.openSettingsPage();
  }

  @override
  Future<WnsChannel> requestChannel() {
    return _client.requestChannel();
  }

  @override
  Future<void> closeChannel() {
    return _client.closeChannel();
  }

  @override
  Future<void> setForegroundNotificationPresentation({required bool alert}) {
    return _legacyService.setForegroundNotificationPresentation(alert: alert);
  }

  @override
  Future<WnsActivation?> getInitialActivation() {
    return _client.getInitialActivation();
  }

  @override
  Stream<WnsMessage> get onMessage {
    return _client.onMessage;
  }

  @override
  Stream<WnsActivation> get onActivation {
    return _client.onActivation;
  }
}
