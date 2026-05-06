import 'package:flutter/foundation.dart';

part 'wns_toast_activation.dart';

@immutable
sealed class WnsActivation {
  const WnsActivation({this.activatedAt, this.rawPayload});

  final DateTime? activatedAt;
  final String? rawPayload;
}

enum WnsToastActivationKind { launch, action, foregroundForward, unknown }
