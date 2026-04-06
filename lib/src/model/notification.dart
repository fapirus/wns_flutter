import 'package:flutter/foundation.dart';

@immutable
class WindowsNotificationPayload {
  const WindowsNotificationPayload({
    this.data = const <String, String>{},
    this.rawPayload,
  });

  factory WindowsNotificationPayload.fromMap(
    Map<Object?, Object?> map, {
    Map<String, String> fallbackData = const <String, String>{},
  }) {
    final data = _stringMapFromDynamic(map['data']);

    return WindowsNotificationPayload(
      data: data.isEmpty ? fallbackData : data,
      rawPayload: _stringOrNull(map['rawPayload']),
    );
  }

  final Map<String, String> data;
  final String? rawPayload;

  @override
  String toString() {
    return 'WindowsNotificationPayload(data: $data, rawPayload: $rawPayload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WindowsNotificationPayload &&
            mapEquals(other.data, data) &&
            other.rawPayload == rawPayload;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAllUnordered(data.entries), rawPayload);
}

@immutable
class WindowsNotificationActivation {
  const WindowsNotificationActivation({
    required this.arguments,
    required this.argumentMap,
    required this.payload,
    this.userInput = const <String, String>{},
  });

  factory WindowsNotificationActivation.fromMap(Map<Object?, Object?> map) {
    final arguments = _stringOrNull(map['arguments']) ?? '';
    final argumentMap = _parseArguments(arguments);

    return WindowsNotificationActivation(
      arguments: arguments,
      argumentMap: argumentMap,
      payload: WindowsNotificationPayload.fromMap(
        map,
        fallbackData: argumentMap,
      ),
      userInput: _stringMapFromDynamic(map['userInput']),
    );
  }

  final String arguments;
  final Map<String, String> argumentMap;
  final Map<String, String> userInput;
  final WindowsNotificationPayload payload;

  @override
  String toString() {
    return 'WindowsNotificationActivation('
        'arguments: $arguments, '
        'argumentMap: $argumentMap, '
        'userInput: $userInput, '
        'payload: $payload'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WindowsNotificationActivation &&
            other.arguments == arguments &&
            mapEquals(other.argumentMap, argumentMap) &&
            mapEquals(other.userInput, userInput) &&
            other.payload == payload;
  }

  @override
  int get hashCode => Object.hash(
    arguments,
    Object.hashAllUnordered(argumentMap.entries),
    Object.hashAllUnordered(userInput.entries),
    payload,
  );
}

@immutable
class WindowsIncomingMessage {
  const WindowsIncomingMessage({
    required this.arguments,
    required this.argumentMap,
    required this.payload,
    this.receivedAt,
  });

  factory WindowsIncomingMessage.fromMap(Map<Object?, Object?> map) {
    final arguments = _stringOrNull(map['arguments']) ?? '';
    final argumentMap = _parseArguments(arguments);

    return WindowsIncomingMessage(
      arguments: arguments,
      argumentMap: argumentMap,
      payload: WindowsNotificationPayload.fromMap(
        map,
        fallbackData: argumentMap,
      ),
      receivedAt: _dateTimeFromDynamic(map['receivedAt']),
    );
  }

  final String arguments;
  final Map<String, String> argumentMap;
  final WindowsNotificationPayload payload;
  final DateTime? receivedAt;

  @override
  String toString() {
    return 'WindowsIncomingMessage('
        'arguments: $arguments, '
        'argumentMap: $argumentMap, '
        'payload: $payload, '
        'receivedAt: $receivedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WindowsIncomingMessage &&
            other.arguments == arguments &&
            mapEquals(other.argumentMap, argumentMap) &&
            other.payload == payload &&
            other.receivedAt == receivedAt;
  }

  @override
  int get hashCode => Object.hash(
    arguments,
    Object.hashAllUnordered(argumentMap.entries),
    payload,
    receivedAt,
  );
}

Map<String, String> _stringMapFromDynamic(dynamic value) {
  if (value == null) {
    return const <String, String>{};
  }

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

DateTime? _dateTimeFromDynamic(dynamic value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}

String? _stringOrNull(dynamic value) {
  if (value == null) {
    return null;
  }

  return value.toString();
}
