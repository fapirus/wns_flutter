import 'package:flutter/foundation.dart';

part 'wns_badge_message.dart';
part 'wns_raw_message.dart';
part 'wns_tile_message.dart';

@immutable
sealed class WnsMessage {
  const WnsMessage({required this.receivedAt, this.rawPayload});

  final DateTime receivedAt;
  final String? rawPayload;
}
