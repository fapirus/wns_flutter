import 'dart:typed_data';

import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_message.dart';
import 'package:wns_flutter/src/model/wns_notification_type.dart';
import 'package:wns_flutter/src/model/wns_payload.dart';

WnsMessage decodeWnsMessageEvent(dynamic event) {
  final map = _requireMap(
    event,
    message: 'Expected incoming message event payload to be a map.',
    code: 'INVALID_MESSAGE_PAYLOAD',
  );

  return WnsMessage(
    type: _notificationTypeFrom(map['type']),
    payload: _payloadFrom(map),
    receivedAt: _dateTimeFrom(map['receivedAt']) ?? DateTime.now(),
    source: _messageSourceFrom(map['source']),
  );
}

WnsActivation decodeWnsActivationEvent(
  dynamic event, {
  WnsActivationKind fallbackKind = WnsActivationKind.unknown,
}) {
  final map = _requireMap(
    event,
    message: 'Expected activation event payload to be a map.',
    code: 'INVALID_ACTIVATION_PAYLOAD',
    activation: true,
  );

  return WnsActivation(
    type: _notificationTypeFrom(map['type']),
    kind: _activationKindFrom(map['kind'], fallbackKind: fallbackKind),
    payload: _payloadFrom(map),
    userInput: _stringMapFrom(map['userInput']),
    activatedAt: _dateTimeFrom(map['activatedAt']),
  );
}

Map<Object?, Object?> _requireMap(
  dynamic value, {
  required String message,
  required String code,
  bool activation = false,
}) {
  if (value is Map<Object?, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<Object?, Object?>.from(value);
  }

  if (activation) {
    throw WnsActivationParseException(
      message: message,
      code: code,
      details: value,
    );
  }

  throw WnsMessageParseException(
    message: message,
    code: code,
    details: value,
  );
}

WnsPayload _payloadFrom(Map<Object?, Object?> map) {
  final arguments = _stringOrNull(map['arguments']);
  final argumentMap = _parseArguments(arguments ?? '');
  final data = _stringMapFrom(map['data']);

  return WnsPayload(
    rawText: _stringOrNull(map['rawText']),
    rawBytes: _uint8ListFrom(map['rawBytes']),
    xml: _stringOrNull(map['xml']),
    data: data.isEmpty ? argumentMap : data,
    launchArguments: arguments == null || arguments.isEmpty ? null : arguments,
    launchArgumentMap: argumentMap,
  );
}

WnsNotificationType _notificationTypeFrom(dynamic value) {
  return switch (_normalized(value)) {
    'raw' => WnsNotificationType.raw,
    'toast' => WnsNotificationType.toast,
    'badge' => WnsNotificationType.badge,
    'tile' => WnsNotificationType.tile,
    _ => WnsNotificationType.unknown,
  };
}

WnsMessageSource _messageSourceFrom(dynamic value) {
  return switch (_normalized(value)) {
    'foreground' => WnsMessageSource.foreground,
    'background' => WnsMessageSource.background,
    'nativequeue' || 'native_queue' => WnsMessageSource.nativeQueue,
    _ => WnsMessageSource.unknown,
  };
}

WnsActivationKind _activationKindFrom(
  dynamic value, {
  required WnsActivationKind fallbackKind,
}) {
  return switch (_normalized(value)) {
    'launch' => WnsActivationKind.launch,
    'action' => WnsActivationKind.action,
    'backgroundpush' || 'background_push' => WnsActivationKind.backgroundPush,
    'foregroundforward' || 'foreground_forward' =>
      WnsActivationKind.foregroundForward,
    _ => fallbackKind,
  };
}

Map<String, String> _stringMapFrom(dynamic value) {
  if (value is Map) {
    return Map<String, String>.unmodifiable(
      value.map(
        (key, entryValue) => MapEntry(
          key.toString(),
          entryValue?.toString() ?? '',
        ),
      ),
    );
  }

  return const <String, String>{};
}

Map<String, String> _parseArguments(String arguments) {
  if (arguments.isEmpty) {
    return const <String, String>{};
  }

  final normalized = arguments.startsWith('?')
      ? arguments.substring(1)
      : arguments;

  if (!normalized.contains('=')) {
    return const <String, String>{};
  }

  try {
    return Map<String, String>.unmodifiable(Uri.splitQueryString(normalized));
  } on FormatException {
    return const <String, String>{};
  }
}

DateTime? _dateTimeFrom(dynamic value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}

Uint8List? _uint8ListFrom(dynamic value) {
  if (value is Uint8List) {
    return value;
  }

  if (value is List) {
    return Uint8List.fromList(
      value.whereType<int>().map((entry) => entry & 0xff).toList(),
    );
  }

  return null;
}

String? _stringOrNull(dynamic value) {
  return value?.toString();
}

String _normalized(dynamic value) {
  return value?.toString().replaceAll('-', '_').toLowerCase() ?? '';
}
