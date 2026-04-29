import 'package:flutter/foundation.dart';

@immutable
class WnsPayload {
  const WnsPayload({
    this.rawText,
    this.rawBytes,
    this.xml,
    this.data = const <String, String>{},
    this.launchArguments,
    this.launchArgumentMap = const <String, String>{},
  });

  final String? rawText;
  final Uint8List? rawBytes;
  final String? xml;
  final Map<String, String> data;
  final String? launchArguments;
  final Map<String, String> launchArgumentMap;

  @override
  String toString() {
    return 'WnsPayload('
        'rawText: $rawText, '
        'rawBytes: $rawBytes, '
        'xml: $xml, '
        'data: $data, '
        'launchArguments: $launchArguments, '
        'launchArgumentMap: $launchArgumentMap'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsPayload &&
            other.rawText == rawText &&
            listEquals(other.rawBytes, rawBytes) &&
            other.xml == xml &&
            mapEquals(other.data, data) &&
            other.launchArguments == launchArguments &&
            mapEquals(other.launchArgumentMap, launchArgumentMap);
  }

  @override
  int get hashCode => Object.hash(
    rawText,
    rawBytes == null ? null : Object.hashAll(rawBytes!),
    xml,
    Object.hashAllUnordered(data.entries),
    launchArguments,
    Object.hashAllUnordered(launchArgumentMap.entries),
  );
}
