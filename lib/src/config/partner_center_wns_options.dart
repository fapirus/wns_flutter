import 'package:wns_flutter/src/config/wns_initialization_options.dart';

class PartnerCenterWnsOptions extends WnsInitializationOptions {
  const PartnerCenterWnsOptions({
    this.appUserModelId,
    this.suppressForegroundToasts = false,
  });

  final String? appUserModelId;

  /// Cancels incoming cloud toasts while this process owns the foreground window.
  ///
  /// This suppresses both the banner and a new Notification Center entry.
  /// Raw push delivery is unaffected. Defaults to false.
  final bool suppressForegroundToasts;
}
