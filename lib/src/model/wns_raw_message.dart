part of 'wns_message.dart';

@immutable
class WnsRawMessage extends WnsMessage {
  const WnsRawMessage({
    required super.receivedAt,
    super.rawPayload,
    this.text,
    this.bytes,
    this.data = const <String, String>{},
  });

  final String? text;
  final Uint8List? bytes;
  final Map<String, String> data;

  @override
  String toString() {
    return 'WnsRawMessage('
        'receivedAt: $receivedAt, '
        'rawPayload: $rawPayload, '
        'text: $text, '
        'bytes: $bytes, '
        'data: $data'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsRawMessage &&
            other.receivedAt == receivedAt &&
            other.rawPayload == rawPayload &&
            other.text == text &&
            listEquals(other.bytes, bytes) &&
            mapEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(
    receivedAt,
    rawPayload,
    text,
    bytes == null ? null : Object.hashAll(bytes!),
    Object.hashAllUnordered(data.entries),
  );
}
