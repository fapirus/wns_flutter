#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "wns_flutter_plugin.h"

namespace wns_flutter {
namespace test {

namespace {

using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(WnsFlutterPlugin, GetInitialMessageReturnsNullWithoutActivation) {
  WnsFlutterPlugin plugin;
  bool success_called = false;
  const EncodableValue* success_value =
      reinterpret_cast<const EncodableValue*>(1);

  plugin.HandleMethodCall(
      MethodCall<>("getInitialMessage", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&success_called, &success_value](const EncodableValue* result) {
            success_called = true;
            success_value = result;
          },
          nullptr, nullptr));

  EXPECT_TRUE(success_called);
  EXPECT_EQ(success_value, nullptr);
}

TEST(WnsFlutterPlugin, InitializeRejectsInvalidForegroundToastOption) {
  WnsFlutterPlugin plugin;
  flutter::EncodableMap options{
      {EncodableValue("suppressForegroundToasts"), EncodableValue("true")}};
  std::string error_code;

  plugin.HandleMethodCall(
      MethodCall<>("initialize",
                   std::make_unique<EncodableValue>(std::move(options))),
      std::make_unique<MethodResultFunctions<>>(
          nullptr,
          [&error_code](const std::string& code, const std::string&,
                        const EncodableValue*) { error_code = code; },
          nullptr));

  EXPECT_EQ(error_code, "INVALID_ARGUMENT");
}

}  // namespace test
}  // namespace wns_flutter
