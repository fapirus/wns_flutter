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
constexpr wchar_t kPluginWindowPropertyName[] = L"WnsFlutterPluginInstance";
constexpr ULONG_PTR kActivationCopyDataSignature = 0x574E5346;  // WNSF
constexpr UINT kDispatchMessageEvent = WM_APP + 101;

void LogDebug(const std::wstring& message) {
  ::OutputDebugStringW((L"[wns_flutter] " + message + L"\n").c_str());
}

void LogDebug(const wchar_t* message) {
  LogDebug(std::wstring(message));
}

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
  payload[flutter::EncodableValue("type")] = flutter::EncodableValue("toast");
  payload[flutter::EncodableValue("kind")] = flutter::EncodableValue("launch");
  payload[flutter::EncodableValue("arguments")] =
      flutter::EncodableValue(WideToUtf8(arguments));
  payload[flutter::EncodableValue("rawText")] =
      flutter::EncodableValue(WideToUtf8(arguments));
  payload[flutter::EncodableValue("data")] =
      flutter::EncodableValue(flutter::EncodableMap());
  return payload;
}

flutter::EncodableMap BuildForwardedActivationPayload(
    const std::wstring& arguments) {
  auto payload = BuildActivationPayload(arguments);
  payload[flutter::EncodableValue("kind")] =
      flutter::EncodableValue("foregroundForward");
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

void BringWindowToForeground(HWND target_window) {
  if (target_window == nullptr) {
    return;
  }

  DWORD target_thread_id = ::GetWindowThreadProcessId(target_window, nullptr);
  DWORD current_thread_id = ::GetCurrentThreadId();
  DWORD foreground_thread_id =
      ::GetWindowThreadProcessId(::GetForegroundWindow(), nullptr);

  ::AllowSetForegroundWindow(::GetCurrentProcessId());

  if (::IsIconic(target_window)) {
    ::ShowWindowAsync(target_window, SW_RESTORE);
  } else {
    ::ShowWindowAsync(target_window, SW_SHOW);
  }

  if (foreground_thread_id != 0 && foreground_thread_id != current_thread_id) {
    ::AttachThreadInput(current_thread_id, foreground_thread_id, TRUE);
  }
  if (target_thread_id != 0 && target_thread_id != current_thread_id) {
    ::AttachThreadInput(current_thread_id, target_thread_id, TRUE);
  }

  ::BringWindowToTop(target_window);
  ::SetForegroundWindow(target_window);
  ::SetActiveWindow(target_window);
  ::SetFocus(target_window);

  if (target_thread_id != 0 && target_thread_id != current_thread_id) {
    ::AttachThreadInput(current_thread_id, target_thread_id, FALSE);
  }
  if (foreground_thread_id != 0 && foreground_thread_id != current_thread_id) {
    ::AttachThreadInput(current_thread_id, foreground_thread_id, FALSE);
  }

  ::SetWindowPos(target_window, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
  ::SetWindowPos(target_window, HWND_NOTOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
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
    const Windows::Networking::PushNotifications::PushNotificationReceivedEventArgs&
        event_args) {
  using Windows::Networking::PushNotifications::PushNotificationType;

  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("source")] =
      flutter::EncodableValue("foreground");
  payload[flutter::EncodableValue("arguments")] = flutter::EncodableValue("");
  payload[flutter::EncodableValue("data")] =
      flutter::EncodableValue(flutter::EncodableMap());
  payload[flutter::EncodableValue("receivedAt")] =
      flutter::EncodableValue(CurrentEpochMillis());

  switch (event_args.NotificationType()) {
    case PushNotificationType::Toast: {
      auto toast = event_args.ToastNotification();
      payload[flutter::EncodableValue("type")] =
          flutter::EncodableValue("toast");
      payload[flutter::EncodableValue("arguments")] =
          flutter::EncodableValue(GetToastLaunchArguments(toast));
      payload[flutter::EncodableValue("xml")] =
          flutter::EncodableValue(GetToastXml(toast));
      break;
    }
    case PushNotificationType::Tile:
      payload[flutter::EncodableValue("type")] = flutter::EncodableValue("tile");
      payload[flutter::EncodableValue("xml")] = flutter::EncodableValue(
          winrt::to_string(event_args.TileNotification().Content().GetXml()));
      break;
    case PushNotificationType::Badge:
      payload[flutter::EncodableValue("type")] =
          flutter::EncodableValue("badge");
      payload[flutter::EncodableValue("xml")] = flutter::EncodableValue(
          winrt::to_string(event_args.BadgeNotification().Content().GetXml()));
      break;
    case PushNotificationType::Raw:
      payload[flutter::EncodableValue("type")] = flutter::EncodableValue("raw");
      payload[flutter::EncodableValue("rawText")] = flutter::EncodableValue(
          winrt::to_string(event_args.RawNotification().Content()));
      break;
    default:
      payload[flutter::EncodableValue("type")] =
          flutter::EncodableValue("unknown");
      break;
  }

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
    InstallWindowProc();
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
  UninstallWindowProc();
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
    LogDebug(L"FlushPendingMessageEvents dispatching event");
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
    LogDebug(L"FlushPendingActivationEvents dispatching event");
    message_opened_app_sink_->Success(flutter::EncodableValue(payload));
  }
}

void WnsFlutterPlugin::QueueMessageEvent(EncodableMap payload) {
  LogDebug(L"QueueMessageEvent queued foreground notification");
  {
    std::lock_guard<std::mutex> lock(pending_events_mutex_);
    pending_message_events_.push_back(std::move(payload));
  }

  if (main_window_ != nullptr) {
    if (!::PostMessage(main_window_, kDispatchMessageEvent, 0, 0)) {
      LogDebug(L"QueueMessageEvent failed to post dispatch message");
    }
  } else {
    LogDebug(L"QueueMessageEvent skipped dispatch: no main window");
  }
}

void WnsFlutterPlugin::QueueOpenedAppEvent(EncodableMap payload) {
  LogDebug(L"QueueOpenedAppEvent received activation");
  if (message_opened_app_sink_) {
    message_opened_app_sink_->Success(flutter::EncodableValue(payload));
    return;
  }

  std::lock_guard<std::mutex> lock(pending_events_mutex_);
  pending_opened_app_events_.push_back(std::move(payload));
}

void WnsFlutterPlugin::AttachPushNotificationHandler() {
  if (!push_channel_) {
    LogDebug(L"AttachPushNotificationHandler skipped: no push channel");
    return;
  }

  LogDebug(L"AttachPushNotificationHandler registering handler");
  TearDownPushNotificationHandler();
  push_received_token_ = push_channel_.PushNotificationReceived(
      [this](const auto& sender, const auto& event_args) {
        LogDebug(L"PushNotificationReceived invoked");

        try {
          QueueMessageEvent(BuildIncomingMessagePayload(event_args));
        } catch (...) {
          LogDebug(L"PushNotificationReceived failed to build payload");
        }
      });
  has_push_received_handler_ = true;
}

void WnsFlutterPlugin::TearDownPushNotificationHandler() {
  if (push_channel_ && has_push_received_handler_) {
    LogDebug(L"TearDownPushNotificationHandler unregistering handler");
    push_channel_.PushNotificationReceived(push_received_token_);
  }
  has_push_received_handler_ = false;
}

void WnsFlutterPlugin::InstallWindowProc() {
  if (main_window_ == nullptr || previous_window_proc_ != nullptr) {
    return;
  }

  if (!::SetPropW(main_window_, kPluginWindowPropertyName,
                  reinterpret_cast<HANDLE>(this))) {
    LogDebug(L"InstallWindowProc failed to set window property");
    return;
  }

  ::SetLastError(ERROR_SUCCESS);
  auto previous = ::SetWindowLongPtrW(
      main_window_, GWLP_WNDPROC,
      reinterpret_cast<LONG_PTR>(&WnsFlutterPlugin::WindowProc));
  if (previous == 0 && ::GetLastError() != ERROR_SUCCESS) {
    ::RemovePropW(main_window_, kPluginWindowPropertyName);
    LogDebug(L"InstallWindowProc failed to subclass window");
    return;
  }

  previous_window_proc_ = reinterpret_cast<WNDPROC>(previous);
  LogDebug(L"InstallWindowProc installed plugin message handler");
}

void WnsFlutterPlugin::UninstallWindowProc() {
  if (main_window_ == nullptr || previous_window_proc_ == nullptr) {
    return;
  }

  const auto* plugin = reinterpret_cast<WnsFlutterPlugin*>(
      ::GetPropW(main_window_, kPluginWindowPropertyName));
  if (plugin == this) {
    const auto current_proc =
        reinterpret_cast<WNDPROC>(::GetWindowLongPtrW(main_window_,
                                                      GWLP_WNDPROC));
    if (current_proc == &WnsFlutterPlugin::WindowProc) {
      ::SetWindowLongPtrW(main_window_, GWLP_WNDPROC,
                          reinterpret_cast<LONG_PTR>(previous_window_proc_));
    }
    ::RemovePropW(main_window_, kPluginWindowPropertyName);
  }

  previous_window_proc_ = nullptr;
}

LRESULT CALLBACK WnsFlutterPlugin::WindowProc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  auto* plugin = reinterpret_cast<WnsFlutterPlugin*>(
      ::GetPropW(hwnd, kPluginWindowPropertyName));
  if (plugin != nullptr) {
    auto result = plugin->HandleWindowProc(hwnd, message, wparam, lparam);
    if (result.has_value()) {
      return *result;
    }

    if (plugin->previous_window_proc_ != nullptr) {
      return ::CallWindowProcW(plugin->previous_window_proc_, hwnd, message,
                               wparam, lparam);
    }
  }

  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

std::optional<LRESULT> WnsFlutterPlugin::HandleWindowProc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  if (message == kDispatchMessageEvent) {
    LogDebug(L"HandleWindowProc flushing queued message events");
    FlushPendingMessageEvents();
    return std::optional<LRESULT>(0);
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
    QueueOpenedAppEvent(BuildForwardedActivationPayload(arguments));
    BringWindowToForeground(hwnd);
    return std::optional<LRESULT>(TRUE);
  }

  return std::nullopt;
}

std::optional<WnsFlutterPlugin::EncodableMap>
WnsFlutterPlugin::ConsumeInitialActivation() {
  if (!initial_activation_payload_.has_value()) {
    LogDebug(L"ConsumeInitialActivation empty");
    return std::nullopt;
  }

  LogDebug(L"ConsumeInitialActivation returning payload");
  auto payload = initial_activation_payload_;
  initial_activation_payload_.reset();
  return payload;
}

std::optional<WnsFlutterPlugin::EncodableMap>
WnsFlutterPlugin::BuildActivationFromCommandLine() const {
  if (!HasPackageIdentity()) {
    LogDebug(L"BuildActivationFromCommandLine skipped: no package identity");
    return std::nullopt;
  }

  std::wstring arguments = JoinCommandLineArguments();
  if (arguments.empty()) {
    LogDebug(L"BuildActivationFromCommandLine skipped: no arguments");
    return std::nullopt;
  }

  LogDebug(L"BuildActivationFromCommandLine captured activation arguments");
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
    LogDebug(L"ForwardActivationToRunningInstance skipped: no target window");
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
  LogDebug(result == TRUE ? L"ForwardActivationToRunningInstance succeeded"
                          : L"ForwardActivationToRunningInstance failed");
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
      result->Error("SETTINGS_LAUNCH_FAILED",
                    "Failed to launch notification settings.");
    }
  } catch (const hresult_error& ex) {
    result->Error("SETTINGS_LAUNCH_FAILED", "Error launching settings.",
                  flutter::EncodableValue((std::string)to_string(ex.message())));
  } catch (...) {
    result->Error("UNKNOWN_ERROR", "Unknown error launching settings.");
  }
}

void WnsFlutterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("initialize") == 0) {
    LogDebug(L"HandleMethodCall initialize");
    if (!HasPackageIdentity()) {
      LogDebug(L"initialize failed: no package identity");
      NotPackagedError(std::move(result));
      return;
    }

    LogDebug(L"initialize succeeded");
    result->Success();
  } else if (method_call.method_name().compare(
                 "getNotificationSettingStatus") == 0) {
    LogDebug(L"HandleMethodCall getNotificationSettingStatus");
    if (!HasPackageIdentity()) {
      LogDebug(L"getNotificationSettingStatus failed: no package identity");
      NotPackagedError(std::move(result));
      return;
    }
    try {
      ToastNotifier notifier = ToastNotificationManager::CreateToastNotifier();
      auto setting = notifier.Setting();
      LogDebug(L"getNotificationSettingStatus succeeded");
      result->Success(flutter::EncodableValue((int)setting));
    } catch (const hresult_error& ex) {
      LogDebug(L"getNotificationSettingStatus failed: WinRT error");
      std::ostringstream error_msg;
      error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": "
                << winrt::to_string(ex.message());

      if (ex.code() == (winrt::hresult)0x80070490) {
        error_msg << " (Hint: Package identity not found. Register the app as MSIX before running.)";
      }

      result->Error("NOTIFICATION_SETTING_FAILED",
                    "Failed to get notification setting.",
                    flutter::EncodableValue(error_msg.str()));
    } catch (...) {
      LogDebug(L"getNotificationSettingStatus failed: unknown error");
      result->Error("UNKNOWN_ERROR",
                    "Unknown error getting notification setting.");
    }
  } else if (method_call.method_name().compare("getChannelUri") == 0) {
    LogDebug(L"HandleMethodCall getChannelUri");
    if (!HasPackageIdentity()) {
      LogDebug(L"getChannelUri failed: no package identity");
      NotPackagedError(std::move(result));
      return;
    }

    std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>
        shared_result = std::move(result);

    try {
      LogDebug(L"getChannelUri starting channel request");
      auto operation =
          Windows::Networking::PushNotifications::PushNotificationChannelManager::
              CreatePushNotificationChannelForApplicationAsync();

      operation.Completed(
          [shared_result, this](const auto& async_info, const auto& status) {
            if (status == AsyncStatus::Completed) {
              LogDebug(L"getChannelUri async completed");
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

                LogDebug(L"getChannelUri succeeded");
                shared_result->Success(flutter::EncodableValue(response));
              } catch (...) {
                LogDebug(L"getChannelUri failed: result conversion error");
                shared_result->Error("CHANNEL_RESULT_INVALID",
                                     "Failed to retrieve channel results.");
              }
            } else if (status == AsyncStatus::Error) {
              LogDebug(L"getChannelUri async failed");
              std::ostringstream error_msg;
              error_msg << "Async operation failed with status: "
                        << (int)status << ". HRESULT: 0x" << std::hex
                        << async_info.ErrorCode().value;

              if (async_info.ErrorCode().value ==
                  (winrt::hresult)0x80070490) {
                error_msg << " (Hint: Package identity not found. Register the app as MSIX before running.)";
              }

              shared_result->Error(
                  "CHANNEL_REQUEST_FAILED",
                  "Failed to create push notification channel.",
                  flutter::EncodableValue(error_msg.str()));
            } else {
              LogDebug(L"getChannelUri async cancelled or incomplete");
              shared_result->Error(
                  "CHANNEL_REQUEST_CANCELLED",
                  "Async operation cancelled or not completed.");
            }
          });
    } catch (const hresult_error& ex) {
      LogDebug(L"getChannelUri failed to initiate: WinRT error");
      std::ostringstream error_msg;
      error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": "
                << winrt::to_string(ex.message());
      shared_result->Error(
          "CHANNEL_REQUEST_FAILED", "Failed to initiate channel creation.",
          flutter::EncodableValue(error_msg.str()));
    } catch (...) {
      LogDebug(L"getChannelUri failed to initiate: unknown error");
      shared_result->Error("UNKNOWN_ERROR",
                           "Unknown error initiating channel creation.");
    }
  } else if (method_call.method_name().compare("closeChannel") == 0) {
    LogDebug(L"HandleMethodCall closeChannel");
    if (push_channel_) {
      try {
        LogDebug(L"closeChannel closing active channel");
        TearDownPushNotificationHandler();
        push_channel_.Close();
        push_channel_ = nullptr;
      } catch (const hresult_error& ex) {
        LogDebug(L"closeChannel failed: WinRT error");
        std::ostringstream error_msg;
        error_msg << "HRESULT: 0x" << std::hex << ex.code() << ": "
                  << winrt::to_string(ex.message());
        result->Error("CHANNEL_CLOSE_FAILED",
                      "Failed to close push notification channel.",
                      flutter::EncodableValue(error_msg.str()));
        return;
      } catch (...) {
        LogDebug(L"closeChannel failed: unknown error");
        result->Error("UNKNOWN_ERROR",
                      "Unknown error closing push notification channel.");
        return;
      }
    }

    LogDebug(L"closeChannel succeeded");
    result->Success();
  } else if (method_call.method_name().compare("getInitialMessage") == 0) {
    LogDebug(L"HandleMethodCall getInitialMessage");
    auto payload = ConsumeInitialActivation();
    if (!payload.has_value()) {
      LogDebug(L"getInitialMessage succeeded: empty");
      result->Success();
      return;
    }

    LogDebug(L"getInitialMessage succeeded: payload");
    result->Success(flutter::EncodableValue(*payload));
  } else if (method_call.method_name().compare("openNotificationSettingPage") ==
             0) {
    LogDebug(L"HandleMethodCall openNotificationSettingPage");
    LaunchSettingsAsync(std::move(result));
  } else {
    LogDebug(L"HandleMethodCall not implemented");
    result->NotImplemented();
  }
}

}  // namespace wns_flutter
