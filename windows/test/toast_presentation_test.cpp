#include <gtest/gtest.h>

#include "toast_presentation.h"

namespace wns_flutter {
namespace test {
namespace {

using winrt::Windows::Networking::PushNotifications::PushNotificationType;

struct NotificationEvent {
  PushNotificationType type;
  mutable bool cancelled = false;
  mutable int cancellation_calls = 0;

  PushNotificationType NotificationType() const { return type; }
  void Cancel(bool value) const {
    cancelled = value;
    ++cancellation_calls;
  }
};

TEST(ToastPresentation, PreservesForegroundToastWhenSuppressionIsDisabled) {
  const NotificationEvent toast{PushNotificationType::Toast};
  EXPECT_FALSE(SuppressForegroundToast(toast, false, 42, 42));
  EXPECT_FALSE(toast.cancelled);
  EXPECT_EQ(toast.cancellation_calls, 0);
}

TEST(ToastPresentation, CancelsToastOnlyWhileReceivingProcessIsForeground) {
  const NotificationEvent foreground_toast{PushNotificationType::Toast};
  EXPECT_TRUE(SuppressForegroundToast(foreground_toast, true, 42, 42));
  EXPECT_TRUE(foreground_toast.cancelled);
  EXPECT_EQ(foreground_toast.cancellation_calls, 1);

  const NotificationEvent background_toast{PushNotificationType::Toast};
  EXPECT_FALSE(SuppressForegroundToast(background_toast, true, 73, 42));
  EXPECT_FALSE(background_toast.cancelled);
  EXPECT_EQ(background_toast.cancellation_calls, 0);
}

TEST(ToastPresentation, LeavesToastVisibleWhenThereIsNoForegroundWindow) {
  const NotificationEvent toast{PushNotificationType::Toast};
  EXPECT_FALSE(SuppressForegroundToast(toast, true, 0, 42));
  EXPECT_EQ(toast.cancellation_calls, 0);
}

TEST(ToastPresentation, NeverCancelsRawStateUpdates) {
  const NotificationEvent raw{PushNotificationType::Raw};
  EXPECT_FALSE(SuppressForegroundToast(raw, true, 42, 42));
  EXPECT_FALSE(SuppressForegroundToast(raw, true, 73, 42));
  EXPECT_EQ(raw.cancellation_calls, 0);
}

}  // namespace
}  // namespace test
}  // namespace wns_flutter
