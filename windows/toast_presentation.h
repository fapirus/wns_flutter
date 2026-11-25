#ifndef FLUTTER_PLUGIN_WNS_TOAST_PRESENTATION_H_
#define FLUTTER_PLUGIN_WNS_TOAST_PRESENTATION_H_

#include <windows.h>
#include <winrt/Windows.Networking.PushNotifications.h>

namespace wns_flutter {

// Cancellation must happen before the native WNS callback returns, not in Dart.
template <typename NotificationEvent>
bool SuppressForegroundToast(const NotificationEvent& event_args,
                             bool enabled,
                             DWORD foreground_process_id,
                             DWORD receiving_process_id) {
  if (!enabled ||
      event_args.NotificationType() !=
          winrt::Windows::Networking::PushNotifications::PushNotificationType::
              Toast ||
      foreground_process_id == 0 ||
      foreground_process_id != receiving_process_id) {
    return false;
  }

  event_args.Cancel(true);
  return true;
}

}  // namespace wns_flutter

#endif  // FLUTTER_PLUGIN_WNS_TOAST_PRESENTATION_H_
