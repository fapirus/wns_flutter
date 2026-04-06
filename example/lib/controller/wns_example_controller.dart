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
    _openedAppSubscription = _client.onMessageOpenedApp.listen(
      _handleOpenedAppMessage,
    );
  }

  static const int _maxEntries = 50;

  final WnsDemoClient _client;
  final DateTime Function() _now;

  StreamSubscription<WindowsIncomingMessage>? _messageSubscription;
  StreamSubscription<WindowsNotificationActivation>? _openedAppSubscription;

  String _channelUri = '-';
  WindowsNotificationActivation? _initialMessage;
  DateTime? _initialMessageCheckedAt;
  bool _foregroundAlert = true;
  WnsNotificationStatus? _notificationStatus;
  final List<WnsEventLogEntry> _eventLogs = <WnsEventLogEntry>[];

  String get channelUri => _channelUri;
  WindowsNotificationActivation? get initialMessage => _initialMessage;
  DateTime? get initialMessageCheckedAt => _initialMessageCheckedAt;
  bool get foregroundAlert => _foregroundAlert;
  WnsNotificationStatus? get notificationStatus => _notificationStatus;
  List<WnsEventLogEntry> get eventLogs => List<WnsEventLogEntry>.unmodifiable(
    _eventLogs,
  );

  Future<void> loadNotificationStatus() async {
    _notificationStatus = await _client.getNotificationSettingStatus();
    notifyListeners();
  }

  Future<void> openNotificationSettings() {
    return _client.openNotificationSettingPage();
  }

  Future<void> loadChannelUri() async {
    final channel = await _client.getChannelUri();
    _channelUri = channel.uri;
    notifyListeners();
  }

  Future<void> refreshInitialMessage() async {
    _initialMessage = await _client.getInitialMessage();
    _initialMessageCheckedAt = _now();
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

  void _handleIncomingMessage(WindowsIncomingMessage message) {
    _addLog(
      WnsEventLogEntry(
        source: WnsEventLogSource.foregroundMessage,
        loggedAt: _now(),
        sourceTimestamp: message.receivedAt,
        arguments: message.arguments,
        data: message.payload.data,
        userInput: const <String, String>{},
        rawPayload: message.payload.rawPayload,
      ),
    );
  }

  void _handleOpenedAppMessage(WindowsNotificationActivation activation) {
    _addLog(
      WnsEventLogEntry(
        source: WnsEventLogSource.openedApp,
        loggedAt: _now(),
        arguments: activation.arguments,
        data: activation.payload.data,
        userInput: activation.userInput,
        rawPayload: activation.payload.rawPayload,
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
    _openedAppSubscription?.cancel();
    super.dispose();
  }
}
