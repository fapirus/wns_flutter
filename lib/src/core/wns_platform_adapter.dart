import 'package:wns_flutter/src/model/wns_activation.dart';
import 'package:wns_flutter/src/model/wns_channel.dart';
import 'package:wns_flutter/src/model/wns_message.dart';

abstract interface class WnsPlatformAdapter {
  Future<void> initialize();

  Future<WnsChannel> requestChannel();

  Future<void> closeChannel();

  Future<WnsActivation?> getInitialActivation();

  Stream<WnsMessage> get onMessage;

  Stream<WnsActivation> get onActivation;

  Future<void> dispose();
}
