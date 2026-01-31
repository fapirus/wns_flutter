#include "wns_flutter_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// C++/WinRT Headers
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.System.h>
#include <winrt/Windows.UI.Notifications.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <winrt/Windows.Networking.PushNotifications.h>
#include <winrt/Windows.Foundation.h>

#include <memory>
#include <sstream>

// Use C++/WinRT namespaces
using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::System;
using namespace Windows::UI::Notifications;

namespace wns_flutter {

// Helper to fire-and-forget async operations without blocking
// This is a minimal implementation of fire_and_forget structure if not using the one from winrt
// Actually winrt::fire_and_forget serves this purpose.

void WnsFlutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wns_flutter",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WnsFlutterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WnsFlutterPlugin::WnsFlutterPlugin() {}

WnsFlutterPlugin::~WnsFlutterPlugin() {}

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
  
  if (method_call.method_name().compare("initialize") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto aumid_it = arguments->find(flutter::EncodableValue("aumid"));
      if (aumid_it != arguments->end()) {
        if (std::holds_alternative<std::string>(aumid_it->second)) {
           aumid_ = std::get<std::string>(aumid_it->second);
        }
      }
    }
    result->Success();
  }
  else if (method_call.method_name().compare("getNotificationSettingStatus") == 0) {
    try {
      // ToastNotificationManager::CreateToastNotifier() creates a notifier for the current app.
      
      ToastNotifier notifier = nullptr;
      
      if (!aumid_.empty()) {
        // Debug mode: use the provided AUMID
        notifier = ToastNotificationManager::CreateToastNotifier(winrt::to_hstring(aumid_));
      } else {
        // Release mode or no AUMID: use Package Identity
        notifier = ToastNotificationManager::CreateToastNotifier();
      }
      
      auto setting = notifier.Setting();
      result->Success(flutter::EncodableValue((int)setting));
    } catch (const hresult_error& ex) {
      std::ostringstream error_msg;
      error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": " << winrt::to_string(ex.message());
      
      // Additional hint for common error
      if (ex.code() == (winrt::hresult)0x80070490) { // Element not found
         error_msg << " (Hint: Application Identity not found. If running in Debug mode, call WnsFlutter.initialize(aumid: '...') with a valid AUMID.)";
      }

      result->Error("WINRT_ERROR", "Failed to get notification setting.",
                    flutter::EncodableValue(error_msg.str()));
    } catch (...) {
      result->Error("UNKNOWN_ERROR", "Unknown error getting notification setting.");
    }
  }
  else if (method_call.method_name().compare("getChannelUri") == 0) {
    // Convert unique_ptr to shared_ptr to capture it in lambda
    std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> shared_result = std::move(result);
    
    try {
      winrt::Windows::Foundation::IAsyncOperation<winrt::Windows::Networking::PushNotifications::PushNotificationChannel> op = nullptr;
      
      if (!aumid_.empty()) {
        op = winrt::Windows::Networking::PushNotifications::PushNotificationChannelManager::CreatePushNotificationChannelForApplicationAsync(winrt::to_hstring(aumid_));
      } else {
        op = winrt::Windows::Networking::PushNotifications::PushNotificationChannelManager::CreatePushNotificationChannelForApplicationAsync();
      }

      op.Completed([shared_result](
        winrt::Windows::Foundation::IAsyncOperation<winrt::Windows::Networking::PushNotifications::PushNotificationChannel> const& asyncInfo,
        winrt::Windows::Foundation::AsyncStatus const& asyncStatus) {
          
          if (asyncStatus == winrt::Windows::Foundation::AsyncStatus::Completed) {
             try {
                auto channel = asyncInfo.GetResults();
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
               error_msg << " (Hint: Identity not found. Check AUMID or MSIX packaging.)";
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

}  // namespace wns_flutter
