import 'package:wns_flutter/wns_flutter.dart';

class WnsErrorDetails {
  const WnsErrorDetails({
    required this.title,
    required this.message,
    required this.raw,
    this.code,
    this.recoveryHint,
    this.details,
  });

  final String title;
  final String message;
  final String raw;
  final String? code;
  final String? recoveryHint;
  final String? details;
}

WnsErrorDetails formatWnsError(Object error) {
  if (error is WnsException) {
    return WnsErrorDetails(
      title: error.runtimeType.toString(),
      message: error.message,
      code: error.code,
      recoveryHint: error.recoveryHint.name,
      details: error.details?.toString(),
      raw: error.toString(),
    );
  }

  return WnsErrorDetails(
    title: error.runtimeType.toString(),
    message: error.toString(),
    raw: error.toString(),
  );
}
