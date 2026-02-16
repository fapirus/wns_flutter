#ifndef FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/event_sink.h>
#include <flutter/stream_handler_error.h>

#include <winrt/Windows.Networking.PushNotifications.h>

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
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListen(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events);
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancel(
      const flutter::EncodableValue* arguments);
  void AttachPushNotificationHandler();
  void DetachPushNotificationHandler();

  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  winrt::Windows::Networking::PushNotifications::PushNotificationChannel push_channel_{nullptr};
  winrt::event_token push_notification_received_token_{};
  bool has_push_notification_handler_ = false;
};

}  // namespace wns_flutter

#endif  // FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_
