#include "wns_flutter_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <appmodel.h>

// C++/WinRT Headers
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.System.h>
#include <winrt/Windows.UI.Notifications.h>

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/plugin_registrar_windows.h>
#if __has_include(<flutter/event_stream_handler_functions.h>)
#include <flutter/event_stream_handler_functions.h>
#elif __has_include(<flutter/stream_handler_functions.h>)
#include <flutter/stream_handler_functions.h>
#else
#error "No compatible Flutter stream handler functions header found."
#endif
#include <flutter/standard_method_codec.h>

#include <winrt/Windows.Networking.PushNotifications.h>
#include <winrt/Windows.Foundation.h>

#include <chrono>
#include <memory>
#include <sstream>
#include <string>

// Use C++/WinRT namespaces
using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::System;
using namespace Windows::UI::Notifications;

namespace wns_flutter {

namespace {

bool HasPackageIdentity() {
  UINT32 length = 0;
  const LONG rc = GetCurrentPackageFullName(&length, nullptr);
  if (rc == APPMODEL_ERROR_NO_PACKAGE) {
    return false;
  }

  if (rc == ERROR_INSUFFICIENT_BUFFER && length > 0) {
    std::wstring full_name;
    full_name.resize(length);
    const LONG second = GetCurrentPackageFullName(&length, full_name.data());
    return second == ERROR_SUCCESS;
  }

  return rc == ERROR_SUCCESS;
}

void NotPackagedError(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  result->Error(
      "IDENTITY_NOT_FOUND",
      "Windows package identity is required. Register the app via MSIX or sparse package before calling this API.");
}

}  // namespace

// Helper to fire-and-forget async operations without blocking
// This is a minimal implementation of fire_and_forget structure if not using the one from winrt
// Actually winrt::fire_and_forget serves this purpose.

void WnsFlutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto method_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wns_flutter",
          &flutter::StandardMethodCodec::GetInstance());
  auto event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wns_flutter/on_message",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WnsFlutterPlugin>();

  method_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  event_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [plugin_pointer = plugin.get()](
              const flutter::EncodableValue* arguments,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
            return plugin_pointer->OnListen(arguments, std::move(events));
          },
          [plugin_pointer = plugin.get()](const flutter::EncodableValue* arguments) {
            return plugin_pointer->OnCancel(arguments);
          }));

  registrar->AddPlugin(std::move(plugin));
}

WnsFlutterPlugin::WnsFlutterPlugin() {}

WnsFlutterPlugin::~WnsFlutterPlugin() {
  DetachPushNotificationHandler();
}

// Helper function to launch settings async
winrt::fire_and_forget LaunchSettingsAsync(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    // Navigate to notification settings
    // Uri is "ms-settings:notifications" or "ms-settings:notifications-action" for direct access
    // Windows 10/11 supports "ms-settings:notifications" well.
    Uri uri{ L"ms-settings:notifications" };
    
    // LaunchUriAsync returns IAsyncOperation<bool>
    bool success = co_await Launcher::LaunchUriAsync(uri);
    
    if (success) {
      result->Success();
    } else {
      result->Error("LAUNCH_FAILED", "Failed to launch notification settings.");
    }
  } catch (const hresult_error& ex) {
    result->Error("LAUNCH_ERROR", "Error launching settings.", 
                  flutter::EncodableValue((std::string)to_string(ex.message())));
  } catch (...) {
     result->Error("UNKNOWN_ERROR", "Unknown error launching settings.");
  }
}

void WnsFlutterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name().compare("getNotificationSettingStatus") == 0) {
    if (!HasPackageIdentity()) {
      NotPackagedError(std::move(result));
      return;
    }
    try {
      // ToastNotificationManager::CreateToastNotifier() creates a notifier for the current app.
      
      ToastNotifier notifier = ToastNotificationManager::CreateToastNotifier();
      
      auto setting = notifier.Setting();
      result->Success(flutter::EncodableValue((int)setting));
    } catch (const hresult_error& ex) {
      std::ostringstream error_msg;
      error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": " << winrt::to_string(ex.message());
      
      // Additional hint for common error
      if (ex.code() == (winrt::hresult)0x80070490) { // Element not found
         error_msg << " (Hint: Package identity not found. Register the app as MSIX or sparse before running.)";
      }

      result->Error("WINRT_ERROR", "Failed to get notification setting.",
                    flutter::EncodableValue(error_msg.str()));
    } catch (...) {
      result->Error("UNKNOWN_ERROR", "Unknown error getting notification setting.");
    }
  }
  else if (method_call.method_name().compare("getChannelUri") == 0) {
    if (!HasPackageIdentity()) {
      NotPackagedError(std::move(result));
      return;
    }
    // Convert unique_ptr to shared_ptr to capture it in lambda
    std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> shared_result = std::move(result);
    
    try {
      winrt::Windows::Foundation::IAsyncOperation<winrt::Windows::Networking::PushNotifications::PushNotificationChannel> op = nullptr;
      
      op = winrt::Windows::Networking::PushNotifications::PushNotificationChannelManager::CreatePushNotificationChannelForApplicationAsync();

      op.Completed([this, shared_result](
        winrt::Windows::Foundation::IAsyncOperation<winrt::Windows::Networking::PushNotifications::PushNotificationChannel> const& asyncInfo,
        winrt::Windows::Foundation::AsyncStatus const& asyncStatus) {
          
          if (asyncStatus == winrt::Windows::Foundation::AsyncStatus::Completed) {
             try {
                auto channel = asyncInfo.GetResults();
                DetachPushNotificationHandler();
                push_channel_ = channel;
                AttachPushNotificationHandler();
                auto uri = winrt::to_string(channel.Uri());
                auto expiration = channel.ExpirationTime();

                auto expiration_ticks = expiration.time_since_epoch().count(); 
                const int64_t WINDOWS_TO_UNIX_EPOCH_TICKS = 116444736000000000LL;
                int64_t unix_ticks = expiration_ticks - WINDOWS_TO_UNIX_EPOCH_TICKS;
                int64_t expiration_millis = unix_ticks / 10000; 
                
                flutter::EncodableMap response;
                response[flutter::EncodableValue("uri")] = flutter::EncodableValue(uri);
                response[flutter::EncodableValue("expirationTime")] = flutter::EncodableValue(expiration_millis);
                
                shared_result->Success(flutter::EncodableValue(response));
             } catch (...) {
                shared_result->Error("CHANNEL_ERROR", "Failed to retrieve channel results.");
             }
          } else if (asyncStatus == winrt::Windows::Foundation::AsyncStatus::Error) {
             std::ostringstream error_msg;
             error_msg << "Async operation failed with status: " << (int)asyncStatus 
                       << ". HRESULT: 0x" << std::hex << asyncInfo.ErrorCode().value;
             
             if (asyncInfo.ErrorCode().value == (winrt::hresult)0x80070490) {
               error_msg << " (Hint: Package identity not found. Register the app as MSIX or sparse before running.)";
             }
             
             shared_result->Error("CHANNEL_ERROR", "Failed to create push notification channel.",
                                  flutter::EncodableValue(error_msg.str()));
          } else {
             shared_result->Error("CHANNEL_ERROR", "Async operation cancelled or not completed.");
          }
      });
    
    } catch (const hresult_error& ex) {
      std::ostringstream error_msg;
      error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": " << winrt::to_string(ex.message());
      shared_result->Error("CHANNEL_ERROR", "Failed to initiate channel creation.", flutter::EncodableValue(error_msg.str()));
    } catch (...) {
       shared_result->Error("UNKNOWN_ERROR", "Unknown error initiating channel creation.");
    }
  } 
  else if (method_call.method_name().compare("openNotificationSettingPage") == 0) {
    // Since this is an async operation, we delegate to a fire_and_forget helper
    LaunchSettingsAsync(std::move(result));
  } 
  else {
    result->NotImplemented();
  }
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
WnsFlutterPlugin::OnListen(
    const flutter::EncodableValue* /*arguments*/,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  if (!HasPackageIdentity()) {
    return std::make_unique<flutter::StreamHandlerError<flutter::EncodableValue>>(
        "IDENTITY_NOT_FOUND",
        "Windows package identity is required. Register the app via MSIX before subscribing.");
  }

  event_sink_ = std::move(events);
  AttachPushNotificationHandler();

  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
WnsFlutterPlugin::OnCancel(const flutter::EncodableValue* /*arguments*/) {
  event_sink_.reset();
  DetachPushNotificationHandler();
  return nullptr;
}

void WnsFlutterPlugin::AttachPushNotificationHandler() {
  if (!event_sink_ || !push_channel_ || has_push_notification_handler_) {
    return;
  }

  push_notification_received_token_ = push_channel_.PushNotificationReceived(
      [this](
          winrt::Windows::Networking::PushNotifications::PushNotificationChannel const& channel,
          winrt::Windows::Networking::PushNotifications::PushNotificationReceivedEventArgs const& args) {
        if (!event_sink_) {
          return;
        }

        flutter::EncodableMap event;
        const auto type = args.NotificationType();
        std::string type_text = "unknown";
        std::string payload = "";

        if (type == winrt::Windows::Networking::PushNotifications::PushNotificationType::Raw) {
          type_text = "raw";
          payload = winrt::to_string(args.RawNotification().Content());
        } else if (type == winrt::Windows::Networking::PushNotifications::PushNotificationType::Toast) {
          type_text = "toast";
        } else if (type == winrt::Windows::Networking::PushNotifications::PushNotificationType::Tile) {
          type_text = "tile";
        } else if (type == winrt::Windows::Networking::PushNotifications::PushNotificationType::Badge) {
          type_text = "badge";
        } else if (type == winrt::Windows::Networking::PushNotifications::PushNotificationType::TileFlyout) {
          type_text = "tileFlyout";
        }

        const auto now_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();

        event[flutter::EncodableValue("type")] = flutter::EncodableValue(type_text);
        event[flutter::EncodableValue("payload")] = flutter::EncodableValue(payload);
        event[flutter::EncodableValue("channelUri")] =
            flutter::EncodableValue(winrt::to_string(channel.Uri()));
        event[flutter::EncodableValue("receivedAt")] =
            flutter::EncodableValue(static_cast<int64_t>(now_ms));

        event_sink_->Success(flutter::EncodableValue(event));
      });

  has_push_notification_handler_ = true;
}

void WnsFlutterPlugin::DetachPushNotificationHandler() {
  if (!push_channel_ || !has_push_notification_handler_) {
    return;
  }

  push_channel_.PushNotificationReceived(push_notification_received_token_);
  has_push_notification_handler_ = false;
}

}  // namespace wns_flutter
