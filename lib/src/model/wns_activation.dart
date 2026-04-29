import 'package:flutter/foundation.dart';
import 'package:wns_flutter/src/model/wns_notification_type.dart';
import 'package:wns_flutter/src/model/wns_payload.dart';

@immutable
class WnsActivation {
  const WnsActivation({
    required this.type,
    required this.kind,
    required this.payload,
    this.userInput = const <String, String>{},
    this.activatedAt,
  });

  final WnsNotificationType type;
  final WnsActivationKind kind;
  final WnsPayload payload;
  final Map<String, String> userInput;
  final DateTime? activatedAt;

  @override
  String toString() {
    return 'WnsActivation('
        'type: $type, '
        'kind: $kind, '
        'payload: $payload, '
        'userInput: $userInput, '
        'activatedAt: $activatedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsActivation &&
            other.type == type &&
            other.kind == kind &&
            other.payload == payload &&
            mapEquals(other.userInput, userInput) &&
            other.activatedAt == activatedAt;
  }

  @override
  int get hashCode => Object.hash(
    type,
    kind,
    payload,
    Object.hashAllUnordered(userInput.entries),
    activatedAt,
  );
}
