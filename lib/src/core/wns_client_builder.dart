import 'package:wns_flutter/src/adapter/partner_center/partner_center_wns_adapter.dart';
import 'package:wns_flutter/src/config/partner_center_wns_options.dart';
import 'package:wns_flutter/src/config/wns_initialization_options.dart';
import 'package:wns_flutter/src/core/wns_client.dart';
import 'package:wns_flutter/src/core/wns_platform_adapter.dart';
import 'package:wns_flutter/src/exception/exception.dart';

typedef PartnerCenterWnsAdapterFactory =
    WnsPlatformAdapter Function(PartnerCenterWnsOptions options);

class WnsClientBuilder {
  const WnsClientBuilder({
    PartnerCenterWnsAdapterFactory? partnerCenterAdapterFactory,
  }) : _partnerCenterAdapterFactory =
           partnerCenterAdapterFactory ?? _createPartnerCenterAdapter;

  final PartnerCenterWnsAdapterFactory _partnerCenterAdapterFactory;

  WnsClient create(WnsInitializationOptions options) {
    if (options is PartnerCenterWnsOptions) {
      return WnsClient(_partnerCenterAdapterFactory(options));
    }

    throw WnsInvalidInitializationOptionsException(
      message: 'Unsupported WNS initialization options.',
      details: options.runtimeType.toString(),
    );
  }
}

WnsPlatformAdapter _createPartnerCenterAdapter(
  PartnerCenterWnsOptions options,
) {
  return PartnerCenterWnsAdapter(options: options);
}
