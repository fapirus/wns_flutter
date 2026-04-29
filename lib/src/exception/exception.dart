import 'package:flutter/services.dart';

enum WnsRecoveryHint {
  none,
  retryImmediately,
  retryLater,
  requestFreshChannel,
  openSettings,
  reinstallAsPackage,
  completeProviderSetup,
  useFallbackTransport,
  reportBug,
}

abstract class WnsException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  final WnsRecoveryHint recoveryHint;
  final StackTrace? stackTrace;

  const WnsException(
    this.message, {
    this.code,
    this.details,
    this.recoveryHint = WnsRecoveryHint.none,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'WnsException('
        'code: $code, '
        'message: $message, '
        'recoveryHint: $recoveryHint, '
        'details: $details'
        ')';
  }
}

class WnsUnsupportedPlatformException extends WnsException {
  const WnsUnsupportedPlatformException({
    String message = 'WNS is only supported on Windows.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.useFallbackTransport,
         stackTrace: stackTrace,
       );
}

class WnsUnsupportedRuntimeException extends WnsException {
  const WnsUnsupportedRuntimeException({
    String message = 'WNS is not supported in this runtime environment.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.useFallbackTransport,
         stackTrace: stackTrace,
       );
}

class WnsPackageIdentityNotFoundException extends WnsException {
  const WnsPackageIdentityNotFoundException({
    String message = 'Windows package identity is required.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.reinstallAsPackage,
         stackTrace: stackTrace,
       );
}

class WnsPackageFamilyMappingRequiredException extends WnsException {
  const WnsPackageFamilyMappingRequiredException({
    String message = 'Package family name mapping is required.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.completeProviderSetup,
         stackTrace: stackTrace,
       );
}

class WnsInvalidInitializationOptionsException extends WnsException {
  const WnsInvalidInitializationOptionsException({
    String message = 'Invalid WNS initialization options.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.completeProviderSetup,
         stackTrace: stackTrace,
       );
}

class WnsNotInitializedException extends WnsException {
  const WnsNotInitializedException({
    String message = 'WNS client has not been initialized.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.retryImmediately,
         stackTrace: stackTrace,
       );
}

class WnsDisposedException extends WnsException {
  const WnsDisposedException({
    String message = 'WNS client has been disposed.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         stackTrace: stackTrace,
       );
}

class WnsChannelRequestException extends WnsException {
  const WnsChannelRequestException({
    String message = 'Failed to request a WNS channel.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.retryLater,
         stackTrace: stackTrace,
       );
}

class WnsChannelRequestTimedOutException extends WnsChannelRequestException {
  const WnsChannelRequestTimedOutException({
    super.message = 'Timed out while requesting a WNS channel.',
    super.code,
    super.details,
    super.stackTrace,
  });
}

class WnsChannelClosedException extends WnsException {
  const WnsChannelClosedException({
    String message = 'The active WNS channel was closed.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.requestFreshChannel,
         stackTrace: stackTrace,
       );
}

class WnsNotificationSettingUnavailableException extends WnsException {
  const WnsNotificationSettingUnavailableException({
    String message = 'Windows notification settings are unavailable.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.openSettings,
         stackTrace: stackTrace,
       );
}

class WnsSettingsLaunchException extends WnsException {
  const WnsSettingsLaunchException({
    String message = 'Failed to open Windows notification settings.',
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.openSettings,
         stackTrace: stackTrace,
       );
}

class WnsPayloadParseException extends WnsException {
  const WnsPayloadParseException({
    required String message,
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.reportBug,
         stackTrace: stackTrace,
       );
}

class WnsActivationParseException extends WnsException {
  const WnsActivationParseException({
    required String message,
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: WnsRecoveryHint.reportBug,
         stackTrace: stackTrace,
       );
}

class WnsNativeCallException extends WnsException {
  const WnsNativeCallException({
    required String message,
    String? code,
    dynamic details,
    WnsRecoveryHint recoveryHint = WnsRecoveryHint.reportBug,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         details: details,
         recoveryHint: recoveryHint,
         stackTrace: stackTrace,
       );
}

/// A generic unknown exception.
class WnsUnknownException extends WnsException {
  const WnsUnknownException({
    String message = 'An unknown error occurred.',
    super.code,
    super.stackTrace,
    super.details,
  }) : super(
         message,
         recoveryHint: WnsRecoveryHint.reportBug,
       );
}

WnsException wnsExceptionFromPlatformException(PlatformException e) {
  final stackTrace = e.stacktrace != null
      ? StackTrace.fromString(e.stacktrace!)
      : null;
  final message = e.message ?? 'Unknown platform error';

  return switch (e.code) {
    'IDENTITY_NOT_FOUND' => WnsPackageIdentityNotFoundException(
      message: message,
      code: e.code,
      details: e.details,
      stackTrace: stackTrace,
    ),
    'CHANNEL_REQUEST_FAILED' ||
    'CHANNEL_REQUEST_CANCELLED' ||
    'CHANNEL_RESULT_INVALID' => WnsChannelRequestException(
      message: message,
      code: e.code,
      details: e.details,
      stackTrace: stackTrace,
    ),
    'CHANNEL_CLOSE_FAILED' => WnsChannelClosedException(
      message: message,
      code: e.code,
      details: e.details,
      stackTrace: stackTrace,
    ),
    'NOTIFICATION_SETTING_FAILED' =>
      WnsNotificationSettingUnavailableException(
        message: message,
        code: e.code,
        details: e.details,
        stackTrace: stackTrace,
      ),
    'SETTINGS_LAUNCH_FAILED' => WnsSettingsLaunchException(
      message: message,
      code: e.code,
      details: e.details,
      stackTrace: stackTrace,
    ),
    'UNKNOWN_ERROR' => WnsUnknownException(
      message: message,
      code: e.code,
      details: e.details,
      stackTrace: stackTrace,
    ),
    _ => WnsNativeCallException(
      message: message,
      code: e.code,
      details: e.details,
      stackTrace: stackTrace,
    ),
  };
}

/// Wraps platform-specific exceptions (e.g. from MethodChannel).
class WnsPlatformException extends WnsNativeCallException {
  const WnsPlatformException({
    required super.message,
    super.code,
    super.details,
    PlatformException? originalException,
    super.stackTrace,
  });

  factory WnsPlatformException.fromPlatformException(PlatformException e) {
    if (e.code == 'IDENTITY_NOT_FOUND') {
      return WnsPackageIdentityNotFoundPlatformException(
        message: e.message ?? 'Windows package identity is required.',
        code: e.code,
        details: e.details,
        originalException: e,
        stackTrace: e.stacktrace != null
            ? StackTrace.fromString(e.stacktrace!)
            : null,
      );
    }

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

class WnsPackageIdentityNotFoundPlatformException
    extends WnsPlatformException
    implements WnsPackageIdentityNotFoundException {
  const WnsPackageIdentityNotFoundPlatformException({
    required super.message,
    super.code,
    super.details,
    super.originalException,
    super.stackTrace,
  });
}

class WnsMessageParseException extends WnsPayloadParseException {
  const WnsMessageParseException({
    required super.message,
    super.code,
    super.details,
    super.stackTrace,
  });
}
