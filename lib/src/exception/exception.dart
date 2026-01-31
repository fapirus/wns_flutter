import 'package:flutter/services.dart';

abstract class WnsException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;

  const WnsException(this.message, {this.code, this.details, this.stackTrace});

  @override
  String toString() {
    return 'WnsException(code: $code, message: $message, details: $details)';
  }
}

/// A generic unknown exception.
class WnsUnknownException extends WnsException {
  WnsUnknownException({
    String message = 'An unknown error occurred.',
    StackTrace? stackTrace,
    dynamic details,
  }) : super(message, stackTrace: stackTrace, details: details);
}

/// Wraps platform-specific exceptions (e.g. from MethodChannel).
class WnsPlatformException extends WnsException {
  WnsPlatformException({
    required String message,
    String? code,
    dynamic details,
    PlatformException? originalException,
    StackTrace? stackTrace,
  }) : super(message, code: code, details: details, stackTrace: stackTrace);

  factory WnsPlatformException.fromPlatformException(PlatformException e) {
    return WnsPlatformException(
      message: e.message ?? 'Unknown platform error',
      code: e.code,
      details: e.details,
      originalException: e,
      stackTrace: e.stacktrace != null
          ? StackTrace.fromString(e.stacktrace!)
          : null,
    );
  }
}
