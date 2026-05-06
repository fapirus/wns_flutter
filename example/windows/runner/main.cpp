#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr wchar_t kSingleInstanceMutexName[] =
    L"Local\\wns_flutter_example_single_instance";
constexpr wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr wchar_t kWindowTitle[] = L"wns_flutter_example";
constexpr ULONG_PTR kActivationCopyDataSignature = 0x574E5346;  // WNSF

struct ExistingWindowSearchContext {
  HWND found_window = nullptr;
};

BOOL CALLBACK FindExistingWindowCallback(HWND hwnd, LPARAM lparam) {
  auto* context = reinterpret_cast<ExistingWindowSearchContext*>(lparam);

  wchar_t class_name[256] = {};
  if (::GetClassNameW(hwnd, class_name, static_cast<int>(std::size(class_name))) ==
      0) {
    return TRUE;
  }

  if (std::wstring(class_name) != kWindowClassName) {
    return TRUE;
  }

  wchar_t title[256] = {};
  ::GetWindowTextW(hwnd, title, static_cast<int>(std::size(title)));
  if (std::wstring(title) != kWindowTitle) {
    return TRUE;
  }

  context->found_window = hwnd;
  return FALSE;
}

HWND FindExistingWindow() {
  ExistingWindowSearchContext context;
  ::EnumWindows(FindExistingWindowCallback, reinterpret_cast<LPARAM>(&context));
  return context.found_window;
}

std::wstring JoinActivationArguments() {
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

void ForwardActivationToExistingWindow(HWND target_window,
                                       const std::wstring& arguments) {
  if (!arguments.empty()) {
    COPYDATASTRUCT copy_data{};
    copy_data.dwData = kActivationCopyDataSignature;
    copy_data.cbData =
        static_cast<DWORD>((arguments.size() + 1) * sizeof(wchar_t));
    copy_data.lpData = const_cast<wchar_t*>(arguments.c_str());
    ::SendMessage(target_window, WM_COPYDATA, 0,
                  reinterpret_cast<LPARAM>(&copy_data));
  }

  if (::IsIconic(target_window)) {
    ::ShowWindow(target_window, SW_RESTORE);
  }
  ::SetForegroundWindow(target_window);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE single_instance_mutex =
      ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutexName);
  if (single_instance_mutex != nullptr &&
      ::GetLastError() == ERROR_ALREADY_EXISTS) {
    if (HWND existing_window = FindExistingWindow()) {
      ForwardActivationToExistingWindow(existing_window,
                                        JoinActivationArguments());
      ::CloseHandle(single_instance_mutex);
      return EXIT_SUCCESS;
    }
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"wns_flutter_example", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single_instance_mutex != nullptr) {
    ::ReleaseMutex(single_instance_mutex);
    ::CloseHandle(single_instance_mutex);
  }
  return EXIT_SUCCESS;
}
