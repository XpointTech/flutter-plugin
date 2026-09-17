#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>

#include "xpoint_sdk_plugin.h"

namespace xpoint_sdk {
namespace test {

using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

// The thin RPC bridge only knows xp_rpc_init / xp_rpc_call;
// anything else is reported as not implemented.
TEST(XpointSdkPlugin, UnknownMethodIsNotImplemented) {
  XpointSdkPlugin plugin;

  bool not_implemented = false;
  MethodCall<EncodableValue> call("does_not_exist", nullptr);
  auto handler = std::make_unique<MethodResultFunctions<EncodableValue>>(
      [](const EncodableValue*) {},
      [](const std::string&, const std::string&, const EncodableValue*) {},
      [&]() { not_implemented = true; });

  plugin.HandleMethodCall(call, std::move(handler));

  EXPECT_TRUE(not_implemented);
}

}  // namespace test
}  // namespace xpoint_sdk
