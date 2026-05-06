part of 'wns_message.dart';

@immutable
class WnsBadgeMessage extends WnsMessage {
  const WnsBadgeMessage({
    required super.receivedAt,
    super.rawPayload,
    this.value,
    this.glyph,
  });

  final int? value;
  final String? glyph;

  @override
  String toString() {
    return 'WnsBadgeMessage('
        'receivedAt: $receivedAt, '
        'rawPayload: $rawPayload, '
        'value: $value, '
        'glyph: $glyph'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsBadgeMessage &&
            other.receivedAt == receivedAt &&
            other.rawPayload == rawPayload &&
            other.value == value &&
            other.glyph == glyph;
  }

  @override
  int get hashCode => Object.hash(receivedAt, rawPayload, value, glyph);
}
