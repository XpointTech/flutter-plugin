package tech.xpoint.flutter.plugin

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import tech.xpoint.XpointRpc
import tech.xpoint.sdk.XpointSdk

/**
 * Dumb forwarder: hands every Flutter call to the universal Kotlin dispatcher and
 * pushes its replies to the event channel. No SDK logic, no routing here — the
 * dispatcher owns all of it on Kotlin coroutines.
 *
 * `xp_rpc_init` binds the SDK once at startup; `xp_rpc_call` forwards every
 * request. Replies arrive on a background thread via the emit closure and are
 * hopped to the main thread, as Flutter's EventSink requires.
 */
class XpointSdkPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var events: EventChannel
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "xpoint_sdk")
        channel.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "xpoint_sdk/events")
        events.setStreamHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "xp_rpc_init" -> {
                XpointRpc.bind(XpointSdk.getInstance())
                result.success(null)
            }

            "xp_rpc_call" -> {
                val request = call.arguments as? String
                    ?: return result.error("BAD_ARGS", "xp_rpc_call expects a request string", null)
                XpointRpc.call(request) { envelope ->
                    mainHandler.post { sink?.success(envelope) }
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(
        arguments: Any?,
        sink: EventChannel.EventSink?
    ) {
        this.sink = sink
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }
}
