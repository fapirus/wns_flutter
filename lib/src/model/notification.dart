enum WnsPushNotificationType { raw, toast, tile, badge, tileFlyout, unknown }

class WindowsNotification {
  final WnsPushNotificationType type;
  final String payload;
  final String? channelUri;
  final DateTime receivedAt;

  const WindowsNotification({
    required this.type,
    required this.payload,
    required this.receivedAt,
    this.channelUri,
  });

  factory WindowsNotification.fromMap(Map<Object?, Object?> map) {
    final typeText = map['type'] as String? ?? 'unknown';
    final payload = map['payload'] as String? ?? '';
    final channelUri = map['channelUri'] as String?;
    final receivedAtMillis = map['receivedAt'] as int? ?? 0;

    return WindowsNotification(
      type: _parseType(typeText),
      payload: payload,
      channelUri: channelUri,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMillis),
    );
  }

  static WnsPushNotificationType _parseType(String typeText) {
    switch (typeText) {
      case 'raw':
        return WnsPushNotificationType.raw;
      case 'toast':
        return WnsPushNotificationType.toast;
      case 'tile':
        return WnsPushNotificationType.tile;
      case 'badge':
        return WnsPushNotificationType.badge;
      case 'tileFlyout':
        return WnsPushNotificationType.tileFlyout;
      default:
        return WnsPushNotificationType.unknown;
    }
  }

  @override
  String toString() {
    return 'WindowsNotification(type: $type, payload: $payload, channelUri: $channelUri, receivedAt: $receivedAt)';
  }
}
