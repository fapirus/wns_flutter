#include "wns_flutter_plugin.h"

#include <appmodel.h>
#include <windows.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <chrono>
#include <memory>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Networking.PushNotifications.h>
#include <winrt/Windows.System.h>
#include <winrt/Windows.UI.Notifications.h>

using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::System;
using namespace Windows::UI::Notifications;

namespace wns_flutter {
namespace {

constexpr wchar_t kActivationForwardWindowMessageName[] =
    L"WnsFlutterActivationForward";
constexpr ULONG_PTR kActivationCopyDataSignature = 0x574E5346;  // WNSF
constexpr UINT kDispatchMessageEvent = WM_APP + 101;

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

void NotPackagedError(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  result->Error(
      "IDENTITY_NOT_FOUND",
      "Windows package identity is required. Register the app via MSIX before calling this API.");
}

std::string WideToUtf8(const std::wstring& value) {
  return winrt::to_string(value);
}

std::wstring Utf8ToWide(const std::string& value) {
  return winrt::to_hstring(value).c_str();
}

std::wstring JoinCommandLineArguments() {
  int argument_count = 0;
  LPWSTR* argv = ::CommandLineToArgvW(::GetCommandLineW(), &argument_count);
  if (argv == nullptr || argument_count <= 1) {
    if (argv != nullptr) {
      ::LocalFree(argv);
    }
    return L"";
  }

  std::wstring joined;
  bool skipped_toast_flag = false;
  for (int index = 1; index < argument_count; ++index) {
    std::wstring argument = argv[index];
    if (!skipped_toast_flag && argument == L"-ToastActivated") {
      skipped_toast_flag = true;
      continue;
    }

    if (!joined.empty()) {
      joined.append(L" ");
    }
    joined.append(argument);
  }

  ::LocalFree(argv);
  return joined;
}

flutter::EncodableMap BuildActivationPayload(const std::wstring& arguments) {
  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("arguments")] =
      flutter::EncodableValue(WideToUtf8(arguments));
  payload[flutter::EncodableValue("rawPayload")] =
      flutter::EncodableValue(WideToUtf8(arguments));
  return payload;
}

std::wstring ToLower(std::wstring value) {
  std::transform(value.begin(), value.end(), value.begin(), towlower);
  return value;
}

bool TryGetProcessImagePath(DWORD process_id, std::wstring* image_path) {
  HANDLE process = ::OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE,
                                 process_id);
  if (process == nullptr) {
    return false;
  }

  std::wstring buffer(MAX_PATH, L'\0');
  DWORD size = static_cast<DWORD>(buffer.size());
  const BOOL success =
      ::QueryFullProcessImageNameW(process, 0, buffer.data(), &size);
  ::CloseHandle(process);

  if (!success) {
    return false;
  }

  buffer.resize(size);
  *image_path = buffer;
  return true;
}

struct ExistingWindowSearchContext {
  DWORD current_process_id;
  std::wstring current_image_path;
  HWND found_window = nullptr;
};

BOOL CALLBACK FindExistingWindowCallback(HWND hwnd, LPARAM lparam) {
  auto* context = reinterpret_cast<ExistingWindowSearchContext*>(lparam);
  DWORD window_process_id = 0;
  ::GetWindowThreadProcessId(hwnd, &window_process_id);
  if (window_process_id == 0 ||
      window_process_id == context->current_process_id) {
    return TRUE;
  }

  if (::GetWindow(hwnd, GW_OWNER) != nullptr) {
    return TRUE;
  }

  std::wstring window_image_path;
  if (!TryGetProcessImagePath(window_process_id, &window_image_path)) {
    return TRUE;
  }

  if (ToLower(window_image_path) != ToLower(context->current_image_path)) {
    return TRUE;
  }

  context->found_window = hwnd;
  return FALSE;
}

int64_t CurrentEpochMillis() {
  const auto now = std::chrono::time_point_cast<std::chrono::milliseconds>(
      std::chrono::system_clock::now());
  return now.time_since_epoch().count();
}

std::string GetToastLaunchArguments(const ToastNotification& toast) {
  try {
    auto document = toast.Content();
    auto root = document.DocumentElement();
    if (root) {
      return winrt::to_string(root.GetAttribute(L"launch"));
    }
  } catch (...) {
  }

  return std::string();
}

std::string GetToastXml(const ToastNotification& toast) {
  try {
    return winrt::to_string(toast.Content().GetXml());
  } catch (...) {
    return std::string();
  }
}

flutter::EncodableMap BuildIncomingMessagePayload(
    const ToastNotification& toast) {
  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("arguments")] =
      flutter::EncodableValue(GetToastLaunchArguments(toast));
  payload[flutter::EncodableValue("rawPayload")] =
      flutter::EncodableValue(GetToastXml(toast));
  payload[flutter::EncodableValue("receivedAt")] =
      flutter::EncodableValue(CurrentEpochMillis());
  return payload;
}

}  // namespace

void WnsFlutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wns_flutter",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WnsFlutterPlugin>(registrar);
  plugin->SetUpEventChannels(registrar->messenger());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WnsFlutterPlugin::WnsFlutterPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  if (registrar_ == nullptr) {
    return;
  }

  if (auto* view = registrar_->GetView()) {
    main_window_ = ::GetAncestor(view->GetNativeWindow(), GA_ROOT);
  }

  if (main_window_ != nullptr) {
    window_proc_delegate_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
        [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          return HandleWindowProc(hwnd, message, wparam, lparam);
        });
  }

  initial_activation_payload_ = BuildActivationFromCommandLine();
  if (initial_activation_payload_.has_value()) {
    if (ForwardActivationToRunningInstance(*initial_activation_payload_)) {
      initial_activation_payload_.reset();
      if (main_window_ != nullptr) {
        ::PostMessage(main_window_, WM_CLOSE, 0, 0);
      }
    }
  }
}

WnsFlutterPlugin::~WnsFlutterPlugin() {
  TearDownPushNotificationHandler();

  if (registrar_ != nullptr && window_proc_delegate_id_ != 0) {
    registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_delegate_id_);
  }
}

void WnsFlutterPlugin::SetUpEventChannels(flutter::BinaryMessenger* messenger) {
  auto message_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, "wns_flutter/message",
          &flutter::StandardMethodCodec::GetInstance());
  message_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const auto* arguments, auto events) {
            message_sink_ = std::move(events);
            FlushPendingMessageEvents();
            return nullptr;
          },
          [this](const auto* arguments) {
            message_sink_.reset();
            return nullptr;
          }));

  auto opened_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, "wns_flutter/message_opened_app",
          &flutter::StandardMethodCodec::GetInstance());
  opened_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const auto* arguments, auto events) {
            message_opened_app_sink_ = std::move(events);
            FlushPendingActivationEvents();
            return nullptr;
          },
          [this](const auto* arguments) {
            message_opened_app_sink_.reset();
            return nullptr;
          }));
}

void WnsFlutterPlugin::FlushPendingMessageEvents() {
  if (!message_sink_) {
    return;
  }

  std::deque<EncodableMap> pending_events;
  {
    std::lock_guard<std::mutex> lock(pending_events_mutex_);
    pending_events.swap(pending_message_events_);
  }

  for (const auto& payload : pending_events) {
    message_sink_->Success(flutter::EncodableValue(payload));
  }
}

void WnsFlutterPlugin::FlushPendingActivationEvents() {
  if (!message_opened_app_sink_) {
    return;
  }

  std::deque<EncodableMap> pending_events;
  {
    std::lock_guard<std::mutex> lock(pending_events_mutex_);
    pending_events.swap(pending_opened_app_events_);
  }

  for (const auto& payload : pending_events) {
    message_opened_app_sink_->Success(flutter::EncodableValue(payload));
  }
}

void WnsFlutterPlugin::QueueMessageEvent(EncodableMap payload) {
  {
    std::lock_guard<std::mutex> lock(pending_events_mutex_);
    pending_message_events_.push_back(std::move(payload));
  }

  if (main_window_ != nullptr) {
    ::PostMessage(main_window_, kDispatchMessageEvent, 0, 0);
  }
}

void WnsFlutterPlugin::QueueOpenedAppEvent(EncodableMap payload) {
  if (message_opened_app_sink_) {
    message_opened_app_sink_->Success(flutter::EncodableValue(payload));
    return;
  }

  std::lock_guard<std::mutex> lock(pending_events_mutex_);
  pending_opened_app_events_.push_back(std::move(payload));
}

void WnsFlutterPlugin::AttachPushNotificationHandler() {
  if (!push_channel_) {
    return;
  }

  TearDownPushNotificationHandler();
  push_received_token_ = push_channel_.PushNotificationReceived(
      [this](const auto& sender, const auto& event_args) {
        if (event_args.NotificationType() !=
            Windows::Networking::PushNotifications::PushNotificationType::Toast) {
          return;
        }

        if (!foreground_alert_) {
          event_args.Cancel(true);
        }

        try {
          QueueMessageEvent(BuildIncomingMessagePayload(
              event_args.ToastNotification()));
        } catch (...) {
        }
      });
  has_push_received_handler_ = true;
}

void WnsFlutterPlugin::TearDownPushNotificationHandler() {
  if (push_channel_ && has_push_received_handler_) {
    push_channel_.PushNotificationReceived(push_received_token_);
  }
  has_push_received_handler_ = false;
}

std::optional<LRESULT> WnsFlutterPlugin::HandleWindowProc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  if (message == kDispatchMessageEvent) {
    FlushPendingMessageEvents();
    return std::nullopt;
  }

  if (message == WM_COPYDATA) {
    const auto* copy_data = reinterpret_cast<COPYDATASTRUCT*>(lparam);
    if (copy_data == nullptr ||
        copy_data->dwData != kActivationCopyDataSignature ||
        copy_data->lpData == nullptr || copy_data->cbData == 0) {
      return std::nullopt;
    }

    const auto* payload = reinterpret_cast<const wchar_t*>(copy_data->lpData);
    std::wstring arguments(payload,
                           (copy_data->cbData / sizeof(wchar_t)) - 1);
    QueueOpenedAppEvent(BuildActivationPayload(arguments));
    return std::optional<LRESULT>(TRUE);
  }

  return std::nullopt;
}

std::optional<WnsFlutterPlugin::EncodableMap>
WnsFlutterPlugin::ConsumeInitialActivation() {
  if (!initial_activation_payload_.has_value()) {
    return std::nullopt;
  }

  auto payload = initial_activation_payload_;
  initial_activation_payload_.reset();
  return payload;
}

std::optional<WnsFlutterPlugin::EncodableMap>
WnsFlutterPlugin::BuildActivationFromCommandLine() const {
  if (!HasPackageIdentity()) {
    return std::nullopt;
  }

  std::wstring arguments = JoinCommandLineArguments();
  if (arguments.empty()) {
    return std::nullopt;
  }

  return BuildActivationPayload(arguments);
}

bool WnsFlutterPlugin::ForwardActivationToRunningInstance(
    const EncodableMap& payload) {
  const auto iterator = payload.find(flutter::EncodableValue("arguments"));
  if (iterator == payload.end()) {
    return false;
  }

  const auto* arguments = std::get_if<std::string>(&iterator->second);
  if (arguments == nullptr || arguments->empty()) {
    return false;
  }

  HWND target_window = FindRunningInstanceWindow();
  if (target_window == nullptr) {
    return false;
  }

  std::wstring wide_arguments = Utf8ToWide(*arguments);
  COPYDATASTRUCT copy_data{};
  copy_data.dwData = kActivationCopyDataSignature;
  copy_data.cbData =
      static_cast<DWORD>((wide_arguments.size() + 1) * sizeof(wchar_t));
  copy_data.lpData = wide_arguments.data();

  const auto result = ::SendMessage(target_window, WM_COPYDATA,
                                    reinterpret_cast<WPARAM>(main_window_),
                                    reinterpret_cast<LPARAM>(&copy_data));
  return result == TRUE;
}

HWND WnsFlutterPlugin::FindRunningInstanceWindow() const {
  std::wstring current_image_path;
  if (!TryGetProcessImagePath(::GetCurrentProcessId(), &current_image_path)) {
    return nullptr;
  }

  ExistingWindowSearchContext context{
      ::GetCurrentProcessId(), current_image_path, nullptr};
  ::EnumWindows(FindExistingWindowCallback,
                reinterpret_cast<LPARAM>(&context));
  return context.found_window;
}

winrt::fire_and_forget LaunchSettingsAsync(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    Uri uri{L"ms-settings:notifications"};
    bool success = co_await Launcher::LaunchUriAsync(uri);

    if (success) {
      result->Success();
    } else {
      result->Error("LAUNCH_FAILED",
                    "Failed to launch notification settings.");
    }
  } catch (const hresult_error& ex) {
    result->Error("LAUNCH_ERROR", "Error launching settings.",
                  flutter::EncodableValue((std::string)to_string(ex.message())));
  } catch (...) {
    result->Error("UNKNOWN_ERROR", "Unknown error launching settings.");
  }
}

void WnsFlutterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getNotificationSettingStatus") == 0) {
    if (!HasPackageIdentity()) {
      NotPackagedError(std::move(result));
      return;
    }
    try {
      ToastNotifier notifier = ToastNotificationManager::CreateToastNotifier();
      auto setting = notifier.Setting();
      result->Success(flutter::EncodableValue((int)setting));
    } catch (const hresult_error& ex) {
      std::ostringstream error_msg;
      error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": "
                << winrt::to_string(ex.message());

      if (ex.code() == (winrt::hresult)0x80070490) {
        error_msg << " (Hint: Package identity not found. Register the app as MSIX before running.)";
      }

      result->Error("WINRT_ERROR", "Failed to get notification setting.",
                    flutter::EncodableValue(error_msg.str()));
    } catch (...) {
      result->Error("UNKNOWN_ERROR",
                    "Unknown error getting notification setting.");
    }
  } else if (method_call.method_name().compare("getChannelUri") == 0) {
    if (!HasPackageIdentity()) {
      NotPackagedError(std::move(result));
      return;
    }

    std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>
        shared_result = std::move(result);

    try {
      auto operation =
          Windows::Networking::PushNotifications::PushNotificationChannelManager::
              CreatePushNotificationChannelForApplicationAsync();

      operation.Completed(
          [shared_result, this](const auto& async_info, const auto& status) {
            if (status == AsyncStatus::Completed) {
              try {
                push_channel_ = async_info.GetResults();
                AttachPushNotificationHandler();

                auto uri = winrt::to_string(push_channel_.Uri());
                auto expiration = push_channel_.ExpirationTime();

                auto expiration_ticks = expiration.time_since_epoch().count();
                const int64_t kWindowsToUnixEpochTicks =
                    116444736000000000LL;
                int64_t unix_ticks = expiration_ticks - kWindowsToUnixEpochTicks;
                int64_t expiration_millis = unix_ticks / 10000;

                flutter::EncodableMap response;
                response[flutter::EncodableValue("uri")] =
                    flutter::EncodableValue(uri);
                response[flutter::EncodableValue("expirationTime")] =
                    flutter::EncodableValue(expiration_millis);

                shared_result->Success(flutter::EncodableValue(response));
              } catch (...) {
                shared_result->Error("CHANNEL_ERROR",
                                     "Failed to retrieve channel results.");
              }
            } else if (status == AsyncStatus::Error) {
              std::ostringstream error_msg;
              error_msg << "Async operation failed with status: "
                        << (int)status << ". HRESULT: 0x" << std::hex
                        << async_info.ErrorCode().value;

              if (async_info.ErrorCode().value ==
                  (winrt::hresult)0x80070490) {
                error_msg << " (Hint: Package identity not found. Register the app as MSIX before running.)";
              }

              shared_result->Error(
                  "CHANNEL_ERROR",
                  "Failed to create push notification channel.",
                  flutter::EncodableValue(error_msg.str()));
            } else {
              shared_result->Error(
                  "CHANNEL_ERROR",
                  "Async operation cancelled or not completed.");
            }
          });
    } catch (const hresult_error& ex) {
      std::ostringstream error_msg;
      error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": "
                << winrt::to_string(ex.message());
      shared_result->Error(
          "CHANNEL_ERROR", "Failed to initiate channel creation.",
          flutter::EncodableValue(error_msg.str()));
    } catch (...) {
      shared_result->Error("UNKNOWN_ERROR",
                           "Unknown error initiating channel creation.");
    }
  } else if (method_call.method_name().compare("getInitialMessage") == 0) {
    auto payload = ConsumeInitialActivation();
    if (!payload.has_value()) {
      result->Success();
      return;
    }

    result->Success(flutter::EncodableValue(*payload));
  } else if (method_call.method_name().compare(
                 "setForegroundNotificationPresentation") == 0) {
    const auto* arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments == nullptr) {
      result->Error("INVALID_ARGUMENTS",
                    "Expected a map with an alert flag.");
      return;
    }

    const auto iterator = arguments->find(flutter::EncodableValue("alert"));
    if (iterator == arguments->end()) {
      result->Error("INVALID_ARGUMENTS",
                    "Expected an alert flag in the argument map.");
      return;
    }

    const auto* alert = std::get_if<bool>(&iterator->second);
    if (alert == nullptr) {
      result->Error("INVALID_ARGUMENTS", "Alert flag must be a boolean.");
      return;
    }

    foreground_alert_ = *alert;
    result->Success();
  } else if (method_call.method_name().compare("openNotificationSettingPage") ==
             0) {
    LaunchSettingsAsync(std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace wns_flutter
