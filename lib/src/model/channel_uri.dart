class ChannelUri {
  final String uri;
  final DateTime expirationTime;

  ChannelUri({required this.uri, required this.expirationTime});

  @override
  String toString() {
    return 'ChannelUri(uri: $uri, expirationTime: $expirationTime)';
  }
}
