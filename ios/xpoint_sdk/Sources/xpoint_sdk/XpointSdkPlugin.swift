import Flutter
import Foundation
import XPointSDK

/// Dumb forwarder: hands every Flutter call to the universal Kotlin dispatcher
/// and pushes its replies to the event channel. No SDK logic, no routing, no
/// threading here — the dispatcher owns all of it on Kotlin coroutines.
///
/// `xp_rpc_init` binds the SDK once at startup; `xp_rpc_call` forwards
/// every request. Replies arrive (on a background thread) via the emit closure
/// and are hopped to the main thread, as Flutter requires.
public class XpointSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = XpointSdkPlugin()
    let method = FlutterMethodChannel(name: "xpoint_sdk", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: method)

    let events = FlutterEventChannel(name: "xpoint_sdk/events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "xp_rpc_init":
      SdkXpointRpc.shared.bind(instance: SdkIosSdk.companion.shared)
      result(nil)

    case "xp_rpc_call":
      guard let request = call.arguments as? String else { return result(Self.argError) }
      SdkXpointRpc.shared.call(request: request) { [weak self] envelope in
        DispatchQueue.main.async { self?.sink?(envelope) }
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private static var argError: FlutterError {
    FlutterError(code: "BAD_ARGS", message: "xp_rpc_call expects a request string", details: nil)
  }
}
