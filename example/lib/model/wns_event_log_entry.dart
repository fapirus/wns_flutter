import 'package:flutter/foundation.dart';

enum WnsEventLogSource { foregroundMessage, openedApp }

@immutable
class WnsEventLogEntry {
  const WnsEventLogEntry({
    required this.source,
    required this.eventTypeLabel,
    required this.loggedAt,
    this.sourceTimestamp,
    this.primaryFields = const <String, String>{},
    this.rawPayload,
  });

  final WnsEventLogSource source;
  final String eventTypeLabel;
  final DateTime loggedAt;
  final DateTime? sourceTimestamp;
  final Map<String, String> primaryFields;
  final String? rawPayload;

  DateTime get displayTimestamp => sourceTimestamp ?? loggedAt;
}
