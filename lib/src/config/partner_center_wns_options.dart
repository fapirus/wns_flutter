import 'package:wns_flutter/src/config/wns_initialization_options.dart';

class PartnerCenterWnsOptions extends WnsInitializationOptions {
  const PartnerCenterWnsOptions({
    this.appUserModelId,
  });

  final String? appUserModelId;
}
