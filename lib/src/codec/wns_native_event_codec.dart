import 'dart:convert';
import 'dart:typed_data';

import 'package:wns_flutter/src/exception/exception.dart';
import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_message.dart';

WnsMessage decodeWnsMessageEvent(dynamic event) {
  final map = _requireMap(
    event,
    message: 'Expected incoming message event payload to be a map.',
    code: 'INVALID_MESSAGE_PAYLOAD',
  );

  final receivedAt = _dateTimeFrom(map['receivedAt']) ?? DateTime.now();
  final rawText = _stringOrNull(map['rawText']);
  final xml = _stringOrNull(map['xml']);
  final rawPayload = _stringOrNull(map['rawPayload']);

  return switch (_normalized(map['type'])) {
    'raw' => WnsRawMessage(
      receivedAt: receivedAt,
      rawPayload: rawPayload ?? rawText,
      text: rawText,
      bytes: _uint8ListFrom(map['rawBytes']),
      data: _dataFromMapOrRawJson(map['data'], rawText),
    ),
    'badge' => WnsBadgeMessage(
      receivedAt: receivedAt,
      rawPayload: rawPayload ?? xml,
      value: _intOrNull(map['value']) ?? _badgeValueFromXml(xml),
      glyph: _stringOrNull(map['glyph']) ?? _badgeGlyphFromXml(xml),
    ),
    'tile' => WnsTileMessage(
      receivedAt: receivedAt,
      rawPayload: rawPayload ?? xml,
      xml: xml,
    ),
    _ => throw WnsMessageParseException(
      message: 'Unsupported incoming message event type.',
      code: 'UNSUPPORTED_MESSAGE_TYPE',
      details: map,
    ),
  };
}

WnsActivation decodeWnsActivationEvent(
  dynamic event, {
  WnsToastActivationKind fallbackKind = WnsToastActivationKind.unknown,
}) {
  final map = _requireMap(
    event,
    message: 'Expected activation event payload to be a map.',
    code: 'INVALID_ACTIVATION_PAYLOAD',
    activation: true,
  );

  if (_normalized(map['type']) != 'toast') {
    throw WnsActivationParseException(
      message: 'Unsupported activation event type.',
      code: 'UNSUPPORTED_ACTIVATION_TYPE',
      details: map,
    );
  }

  final arguments = _stringOrNull(map['arguments']) ?? '';
  final argumentMap = _parseArguments(arguments);
  final data = _stringMapFrom(map['data']);
  final xml = _stringOrNull(map['xml']);
  final rawPayload =
      _stringOrNull(map['rawPayload']) ??
      xml ??
      _stringOrNull(map['rawText']) ??
      (arguments.isEmpty ? null : arguments);
  final actionId =
      _stringOrNull(map['actionId']) ??
      argumentMap['actionId'] ??
      argumentMap['action'];

  return WnsToastActivation(
    kind: _toastActivationKindFrom(map['kind'], fallbackKind: fallbackKind),
    arguments: arguments,
    argumentMap: argumentMap,
    actionId: actionId,
    userInput: _stringMapFrom(map['userInput']),
    xml: xml,
    data: data.isEmpty ? argumentMap : data,
    activatedAt: _dateTimeFrom(map['activatedAt']),
    rawPayload: rawPayload,
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

  throw WnsMessageParseException(message: message, code: code, details: value);
}

WnsToastActivationKind _toastActivationKindFrom(
  dynamic value, {
  required WnsToastActivationKind fallbackKind,
}) {
  return switch (_normalized(value)) {
    'launch' => WnsToastActivationKind.launch,
    'action' => WnsToastActivationKind.action,
    'foregroundforward' ||
    'foreground_forward' => WnsToastActivationKind.foregroundForward,
    _ => fallbackKind,
  };
}

Map<String, String> _dataFromMapOrRawJson(dynamic value, String? rawText) {
  final data = _stringMapFrom(value);
  if (data.isNotEmpty || rawText == null || rawText.isEmpty) {
    return data;
  }

  try {
    final decoded = jsonDecode(rawText);
    if (decoded is Map) {
      return _stringMapFrom(decoded);
    }
  } on FormatException {
    return const <String, String>{};
  }

  return const <String, String>{};
}

Map<String, String> _stringMapFrom(dynamic value) {
  if (value is Map) {
    return Map<String, String>.unmodifiable(
      value.map(
        (key, entryValue) =>
            MapEntry(key.toString(), entryValue?.toString() ?? ''),
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

int? _intOrNull(dynamic value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

int? _badgeValueFromXml(String? xml) {
  final value = _xmlAttribute(xml, 'value');
  return value == null ? null : int.tryParse(value);
}

String? _badgeGlyphFromXml(String? xml) {
  return _xmlAttribute(xml, 'glyph');
}

String? _xmlAttribute(String? xml, String name) {
  if (xml == null || xml.isEmpty) {
    return null;
  }

  final pattern = RegExp("$name\\s*=\\s*[\"']([^\"']+)[\"']");
  return pattern.firstMatch(xml)?.group(1);
}

String? _stringOrNull(dynamic value) {
  return value?.toString();
}

String _normalized(dynamic value) {
  return value?.toString().replaceAll('-', '_').toLowerCase() ?? '';
}
