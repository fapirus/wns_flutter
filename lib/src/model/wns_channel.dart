import 'package:flutter/foundation.dart';

@immutable
class WnsChannel {
  const WnsChannel({
    required this.uri,
    required this.expirationTime,
  });

  final String uri;
  final DateTime expirationTime;

  bool get isExpired => !expirationTime.isAfter(DateTime.now());

  @override
  String toString() {
    return 'WnsChannel(uri: $uri, expirationTime: $expirationTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsChannel &&
            other.uri == uri &&
            other.expirationTime == expirationTime;
  }

  @override
  int get hashCode => Object.hash(uri, expirationTime);
}
