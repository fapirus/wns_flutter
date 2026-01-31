#ifndef FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace wns_flutter {

class WnsFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WnsFlutterPlugin();

  virtual ~WnsFlutterPlugin();

  // Disallow copy and assign.
  WnsFlutterPlugin(const WnsFlutterPlugin&) = delete;
  WnsFlutterPlugin& operator=(const WnsFlutterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  std::string aumid_;
};

}  // namespace wns_flutter

#endif  // FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_
