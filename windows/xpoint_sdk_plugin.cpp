#include "xpoint_sdk_plugin.h"

#include <windows.h>

#include <string>

namespace xpoint_sdk {

HWND XpointSdkPlugin::callback_window_ = nullptr;
CheckResultStreamHandler* XpointSdkPlugin::stream_handler_ = nullptr;

void XpointSdkPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  auto method = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "xpoint_sdk", &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<XpointSdkPlugin>();
  plugin->method_channel_ = std::move(method);
  plugin->method_channel_->SetMethodCallHandler(
      [p = plugin.get()](const auto& call, auto result) { p->HandleMethodCall(call, std::move(result)); });

  auto events = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "xpoint_sdk/events", &flutter::StandardMethodCodec::GetInstance());
  auto handler = std::make_unique<CheckResultStreamHandler>();
  stream_handler_ = handler.get();
  events->SetStreamHandler(std::move(handler));
  plugin->event_channel_ = std::move(events);

  registrar->AddPlugin(std::move(plugin));
}

XpointSdkPlugin::XpointSdkPlugin() {
  LoadSdkDll();
  CreateCallbackWindow();
}

XpointSdkPlugin::~XpointSdkPlugin() {
  stream_handler_ = nullptr;
  DestroyCallbackWindow();
  // Do not FreeLibrary: the Kotlin/Native runtime may keep background threads;
  // the OS reclaims the DLL at process exit.
}

bool XpointSdkPlugin::LoadSdkDll() {
  if (sdk_dll_handle_) return true;

  sdk_dll_handle_ = LoadLibraryW(L"sdk.dll");
  if (!sdk_dll_handle_) return false;

  xp_rpc_init_ = reinterpret_cast<XpRpcInitFn>(GetProcAddress(sdk_dll_handle_, "xp_rpc_init"));
  xp_rpc_call_ = reinterpret_cast<XpRpcCallFn>(GetProcAddress(sdk_dll_handle_, "xp_rpc_call"));
  return xp_rpc_init_ && xp_rpc_call_;
}

void XpointSdkPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();

  if (method == "xp_rpc_init") {
    if (!xp_rpc_init_) {
      result->Error("SDK_NOT_LOADED", "Dispatcher unavailable");
      return;
    }
    xp_rpc_init_();
    result->Success();
  } else if (method == "xp_rpc_call") {
    const auto* request = std::get_if<std::string>(method_call.arguments());
    if (!request) {
      result->Error("BAD_ARGS", "xp_rpc_call expects a request string");
      return;
    }
    if (!xp_rpc_call_) {
      result->Error("SDK_NOT_LOADED", "Dispatcher unavailable");
      return;
    }
    // Non-blocking: the dispatcher launches the work on a coroutine and returns.
    // Replies arrive later via StreamEmit. Ack the channel call immediately.
    xp_rpc_call_(request->c_str(), &XpointSdkPlugin::StreamEmit);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void XpointSdkPlugin::StreamEmit(const char* envelope) {
  if (!callback_window_ || !envelope) return;
  // Hand the envelope to the platform thread; freed in the window proc.
  auto* copy = new std::string(envelope);
  if (!PostMessage(callback_window_, WM_STREAM_EVENT, 0, reinterpret_cast<LPARAM>(copy))) {
    delete copy;
  }
}

LRESULT CALLBACK XpointSdkPlugin::CallbackWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
  if (uMsg == WM_STREAM_EVENT) {
    auto* envelope = reinterpret_cast<std::string*>(lParam);
    if (stream_handler_ && envelope) {
      stream_handler_->SendEvent(flutter::EncodableValue(*envelope));
    }
    delete envelope;
    return 0;
  }
  return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

void XpointSdkPlugin::CreateCallbackWindow() {
  const wchar_t kClassName[] = L"XpointSdkCallbackWindow";
  WNDCLASS wc = {};
  wc.lpfnWndProc = CallbackWindowProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = kClassName;
  RegisterClass(&wc);

  callback_window_ = CreateWindowEx(0, kClassName, L"XPoint SDK Callback", 0, 0, 0, 0, 0,
                                    HWND_MESSAGE, nullptr, GetModuleHandle(nullptr), nullptr);
}

void XpointSdkPlugin::DestroyCallbackWindow() {
  if (callback_window_) {
    DestroyWindow(callback_window_);
    callback_window_ = nullptr;
  }
  UnregisterClass(L"XpointSdkCallbackWindow", GetModuleHandle(nullptr));
}

}  // namespace xpoint_sdk
