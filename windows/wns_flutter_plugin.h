#ifndef FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <deque>
#include <memory>
#include <mutex>
#include <optional>

#include <winrt/Windows.Networking.PushNotifications.h>
#include <winrt/Windows.UI.Notifications.h>

namespace wns_flutter {

class WnsFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit WnsFlutterPlugin(
      flutter::PluginRegistrarWindows* registrar = nullptr);

  ~WnsFlutterPlugin() override;

  WnsFlutterPlugin(const WnsFlutterPlugin&) = delete;
  WnsFlutterPlugin& operator=(const WnsFlutterPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  using EncodableMap = flutter::EncodableMap;
  using EventSink = flutter::EventSink<flutter::EncodableValue>;

  void SetUpEventChannels(flutter::BinaryMessenger* messenger);
  void FlushPendingMessageEvents();
  void FlushPendingActivationEvents();
  void QueueMessageEvent(EncodableMap payload);
  void QueueOpenedAppEvent(EncodableMap payload);
  void AttachPushNotificationHandler();
  void TearDownPushNotificationHandler();
  void TrackForegroundToastActivation(
      const winrt::Windows::UI::Notifications::ToastNotification& toast);
  void InstallWindowProc();
  void UninstallWindowProc();
  std::optional<LRESULT> HandleWindowProc(
      HWND hwnd,
      UINT message,
      WPARAM wparam,
      LPARAM lparam);
  static LRESULT CALLBACK WindowProc(
      HWND hwnd,
      UINT message,
      WPARAM wparam,
      LPARAM lparam);
  std::optional<EncodableMap> ConsumeInitialActivation();
  std::optional<EncodableMap> BuildActivationFromCommandLine() const;
  bool ForwardActivationToRunningInstance(const EncodableMap& payload);
  HWND FindRunningInstanceWindow() const;

  flutter::PluginRegistrarWindows* registrar_;
  HWND main_window_ = nullptr;
  WNDPROC previous_window_proc_ = nullptr;

  struct ForegroundToastActivationRegistration {
    winrt::Windows::UI::Notifications::ToastNotification toast{nullptr};
    winrt::Windows::UI::Notifications::ToastNotification::Activated_revoker
        activated_revoker;
  };

  std::unique_ptr<EventSink> message_sink_;
  std::unique_ptr<EventSink> message_opened_app_sink_;
  std::deque<EncodableMap> pending_message_events_;
  std::deque<EncodableMap> pending_opened_app_events_;
  std::mutex pending_events_mutex_;
  std::deque<ForegroundToastActivationRegistration>
      foreground_toast_activation_registrations_;
  std::mutex foreground_toast_activation_mutex_;

  std::optional<EncodableMap> initial_activation_payload_;
  winrt::Windows::Networking::PushNotifications::PushNotificationChannel
      push_channel_{nullptr};
  winrt::event_token push_received_token_{};
  bool has_push_received_handler_ = false;
};

}  // namespace wns_flutter

#endif  // FLUTTER_PLUGIN_WNS_FLUTTER_PLUGIN_H_
