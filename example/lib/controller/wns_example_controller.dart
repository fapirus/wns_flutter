import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wns_flutter/wns_flutter.dart';
import 'package:wns_flutter_example/model/wns_event_log_entry.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';

class WnsExampleController extends ChangeNotifier {
  WnsExampleController({
    required WnsDemoClient client,
    DateTime Function()? now,
  }) : _client = client,
       _now = now ?? DateTime.now {
    _messageSubscription = _client.onMessage.listen(_handleIncomingMessage);
    _activationSubscription = _client.onActivation.listen(_handleActivation);
  }

  static const int _maxEntries = 50;

  final WnsDemoClient _client;
  final DateTime Function() _now;

  StreamSubscription<WnsMessage>? _messageSubscription;
  StreamSubscription<WnsActivation>? _activationSubscription;

  bool _initialized = false;
  String _channelUri = '-';
  DateTime? _channelExpirationTime;
  bool? _channelIsExpired;
  WnsActivation? _initialActivation;
  DateTime? _initialActivationCheckedAt;
  bool _foregroundAlert = true;
  WnsNotificationSettingsInfo? _notificationSettingsInfo;
  final List<WnsEventLogEntry> _eventLogs = <WnsEventLogEntry>[];

  bool get initialized => _initialized;
  String get channelUri => _channelUri;
  DateTime? get channelExpirationTime => _channelExpirationTime;
  bool? get channelIsExpired => _channelIsExpired;
  WnsActivation? get initialActivation => _initialActivation;
  DateTime? get initialActivationCheckedAt => _initialActivationCheckedAt;
  bool get foregroundAlert => _foregroundAlert;
  WnsNotificationSettingsInfo? get notificationSettingsInfo =>
      _notificationSettingsInfo;
  List<WnsEventLogEntry> get eventLogs => List<WnsEventLogEntry>.unmodifiable(
    _eventLogs,
  );

  Future<void> initialize() async {
    await _client.initialize();
    _initialized = true;
    notifyListeners();
  }

  Future<void> loadNotificationSettingsInfo() async {
    _notificationSettingsInfo = await _client.getNotificationSettingsInfo();
    notifyListeners();
  }

  Future<void> openNotificationSettings() {
    return _client.openNotificationSettingPage();
  }

  Future<void> requestChannel() async {
    final channel = await _client.requestChannel();
    _channelUri = channel.uri;
    _channelExpirationTime = channel.expirationTime;
    _channelIsExpired = channel.isExpired;
    notifyListeners();
  }

  Future<void> closeChannel() async {
    await _client.closeChannel();
    _channelUri = '-';
    _channelExpirationTime = null;
    _channelIsExpired = null;
    notifyListeners();
  }

  Future<void> refreshInitialActivation() async {
    _initialActivation = await _client.getInitialActivation();
    _initialActivationCheckedAt = _now();
    notifyListeners();
  }

  Future<void> setForegroundAlert(bool value) async {
    await _client.setForegroundNotificationPresentation(alert: value);
    _foregroundAlert = value;
    notifyListeners();
  }

  void clearEventLogs() {
    _eventLogs.clear();
    notifyListeners();
  }

  void _handleIncomingMessage(WnsMessage message) {
    _addLog(
      WnsEventLogEntry(
        source: WnsEventLogSource.foregroundMessage,
        loggedAt: _now(),
        sourceTimestamp: message.receivedAt,
        notificationType: message.type,
        messageSource: message.source,
        arguments: message.payload.launchArguments ?? '',
        data: message.payload.data,
        userInput: const <String, String>{},
        rawPayload: message.payload.xml ?? message.payload.rawText,
      ),
    );
  }

  void _handleActivation(WnsActivation activation) {
    _addLog(
      WnsEventLogEntry(
        source: WnsEventLogSource.openedApp,
        loggedAt: _now(),
        notificationType: activation.type,
        activationKind: activation.kind,
        arguments: activation.payload.launchArguments ?? '',
        data: activation.payload.data,
        userInput: activation.userInput,
        rawPayload: activation.payload.xml ?? activation.payload.rawText,
      ),
    );
  }

  void _addLog(WnsEventLogEntry entry) {
    _eventLogs.insert(0, entry);
    if (_eventLogs.length > _maxEntries) {
      _eventLogs.removeRange(_maxEntries, _eventLogs.length);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _activationSubscription?.cancel();
    super.dispose();
  }
}
