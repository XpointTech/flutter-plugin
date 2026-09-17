#ifndef FLUTTER_PLUGIN_XPOINT_SDK_PLUGIN_H_
#define FLUTTER_PLUGIN_XPOINT_SDK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <string>

#include "check_result_stream_handler.h"

namespace xpoint_sdk {

// C ABI of the universal dispatcher exported by sdk.dll (Kotlin @CName).
// `xp_rpc_call` is non-blocking: the dispatcher runs the work on Kotlin
// coroutines and invokes `emit` (on a background thread) as replies arrive.
extern "C" {
typedef void (*XpEmit)(const char* envelope);
typedef void (*XpRpcInitFn)();
typedef void (*XpRpcCallFn)(const char* request, XpEmit emit);
}

// Dumb forwarder: `xp_rpc_init` binds the SDK once at startup;
// `xp_rpc_call` forwards every request and acks immediately. All replies
// arrive via the emit callback and are pushed to the event channel as a single
// envelope string. The only logic here is hopping that callback onto the
// platform thread (Flutter requires it) through a message-only window.
class XpointSdkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  XpointSdkPlugin();
  virtual ~XpointSdkPlugin();

  XpointSdkPlugin(const XpointSdkPlugin&) = delete;
  XpointSdkPlugin& operator=(const XpointSdkPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  static CheckResultStreamHandler* stream_handler_;

  // Replies arrive on background threads; marshal them onto the platform thread
  // through a message-only window.
  static HWND callback_window_;
  static constexpr UINT WM_STREAM_EVENT = WM_USER + 1;
  static LRESULT CALLBACK CallbackWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

 private:
  HMODULE sdk_dll_handle_ = nullptr;
  XpRpcInitFn xp_rpc_init_ = nullptr;
  XpRpcCallFn xp_rpc_call_ = nullptr;

  bool LoadSdkDll();
  void CreateCallbackWindow();
  void DestroyCallbackWindow();

  // Dispatcher emit callback (non-capturing C function pointer); pushes to the
  // single static event sink, so it needs no per-call context.
  static void StreamEmit(const char* envelope);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
};

}  // namespace xpoint_sdk

#endif  // FLUTTER_PLUGIN_XPOINT_SDK_PLUGIN_H_
