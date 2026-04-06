import 'package:flutter/foundation.dart';

enum WnsEventLogSource {
  foregroundMessage,
  openedApp,
}

@immutable
class WnsEventLogEntry {
  const WnsEventLogEntry({
    required this.source,
    required this.loggedAt,
    required this.arguments,
    required this.data,
    required this.userInput,
    this.sourceTimestamp,
    this.rawPayload,
  });

  final WnsEventLogSource source;
  final DateTime loggedAt;
  final DateTime? sourceTimestamp;
  final String arguments;
  final Map<String, String> data;
  final Map<String, String> userInput;
  final String? rawPayload;

  DateTime get displayTimestamp => sourceTimestamp ?? loggedAt;
}
