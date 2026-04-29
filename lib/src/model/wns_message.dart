import 'package:flutter/foundation.dart';
import 'package:wns_flutter/src/model/wns_notification_type.dart';
import 'package:wns_flutter/src/model/wns_payload.dart';

@immutable
class WnsMessage {
  const WnsMessage({
    required this.type,
    required this.payload,
    required this.receivedAt,
    this.source = WnsMessageSource.unknown,
  });

  final WnsNotificationType type;
  final WnsPayload payload;
  final DateTime receivedAt;
  final WnsMessageSource source;

  @override
  String toString() {
    return 'WnsMessage('
        'type: $type, '
        'payload: $payload, '
        'receivedAt: $receivedAt, '
        'source: $source'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsMessage &&
            other.type == type &&
            other.payload == payload &&
            other.receivedAt == receivedAt &&
            other.source == source;
  }

  @override
  int get hashCode => Object.hash(type, payload, receivedAt, source);
}
