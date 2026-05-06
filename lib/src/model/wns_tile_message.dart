part of 'wns_message.dart';

@immutable
class WnsTileMessage extends WnsMessage {
  const WnsTileMessage({required super.receivedAt, super.rawPayload, this.xml});

  final String? xml;

  @override
  String toString() {
    return 'WnsTileMessage('
        'receivedAt: $receivedAt, '
        'rawPayload: $rawPayload, '
        'xml: $xml'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsTileMessage &&
            other.receivedAt == receivedAt &&
            other.rawPayload == rawPayload &&
            other.xml == xml;
  }

  @override
  int get hashCode => Object.hash(receivedAt, rawPayload, xml);
}
