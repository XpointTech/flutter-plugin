import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'xpoint_sdk_platform_interface.dart';
import 'xpoint_sdk.dart';

/// [XpointSdkPlatform] implemented over the universal native dispatcher.
///
/// Two channel methods back everything:
/// - `xp_rpc_init` — bind the SDK once at startup (re-run on hot restart);
/// - `xp_rpc_call` — every call, fire-and-forget. The request is
///   `{id, type: once|many|halt, method, args}`.
///
/// All replies arrive over the EventChannel as `{id, type: part|last, payload,
/// error}` and are correlated back by `id`: a `once` call awaits its `last`; a
/// `many` stream routes each `part` to its callback.
class MethodChannelXpointSdk extends XpointSdkPlatform {
  MethodChannelXpointSdk() {
    eventChannel.receiveBroadcastStream().listen(
          _onEnvelope,
          onError: (Object e) => debugPrint('Dispatcher event stream error: $e'),
        );
    // First thing at startup; on hot restart this re-runs and the dispatcher
    // cancels anything still running from the previous Dart lifetime.
    methodChannel.invokeMethod<void>('xp_rpc_init');
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('xpoint_sdk');

  @visibleForTesting
  final eventChannel = const EventChannel('xpoint_sdk/events');

  var _nextId = 0;

  /// Pending `once` calls, keyed by request id, completed by their `last` reply.
  final Map<String, Completer<dynamic>> _pending = {};

  /// Active streams, keyed by id. Each entry decodes its own raw `part` payload,
  /// so the transport stays method-agnostic (not tied to CheckResult).
  final Map<String, void Function(dynamic payload)> _streams = {};

  void _onEnvelope(dynamic event) {
    try {
      final env = json.decode(event as String) as Map<String, dynamic>;
      final id = env['id']?.toString() ?? '';
      final error = env['error'];
      if (env['type'] == 'part') {
        // Deliver the raw payload; the facade that started the stream decodes it.
        _streams[id]?.call(env['payload']);
        return;
      }
      // type == 'last' — terminal for this id.
      final pending = _pending.remove(id);
      if (pending != null) {
        if (error != null) {
          pending.completeError(_error(error));
        } else {
          pending.complete(env['payload']);
        }
      } else if (error != null) {
        // A stream ended with an error; membership of _streams is owned by start()/stop().
        debugPrint('Periodic checker stream "$id" errored: ${error['code']} — ${error['message']}');
      }
    } catch (e) {
      debugPrint('Error handling dispatcher event: $e');
    }
  }

  // --- dispatcher plumbing -------------------------------------------------

  PlatformException _error(dynamic error) => PlatformException(
        code: error['code']?.toString() ?? 'DISPATCH_ERROR',
        message: error['message']?.toString(),
      );

  /// Sends a one-shot request and completes with its payload (or throws).
  Future<dynamic> _once(String method, [Map<String, dynamic>? args]) {
    final id = '${_nextId++}';
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    methodChannel
        .invokeMethod<void>('xp_rpc_call',
            json.encode({'id': id, 'type': 'once', 'method': method, if (args != null) 'args': args}))
        .catchError((Object e) => _pending.remove(id)?.completeError(e));
    return completer.future;
  }

  Map<String, dynamic> _session(String clientKey, String userId, String? clientBrand, [String? sessionId]) => {
        'clientKey': clientKey,
        'userId': userId,
        if (clientBrand != null) 'clientBrand': clientBrand,
        if (sessionId != null) 'sessionId': sessionId,
      };

  /// Stream id shared by [start]/[stop]; must stay in sync across them.
  String _tag(String clientKey, String userId, String? clientBrand) => '$clientKey:$userId:${clientBrand ?? ''}';

  /// Runs a dispatcher call, logging and falling back instead of throwing.
  /// [fallback] receives the caught error so callers can embed it if useful.
  Future<T> _guard<T>(String op, T Function(Object error) fallback, Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      debugPrint('$op failed: $e');
      return fallback(e);
    }
  }

  /// A denied/idle result returned when a lite check cannot reach the dispatcher.
  CheckResult _dispatcherError(String userId, Object error) => CheckResult(
        requestId: 'error-${DateTime.now().millisecondsSinceEpoch}',
        status: CheckResponseStatus.idle,
        errors: [CheckResponseError(code: -3, description: '$error', shortSummary: 'Dispatcher Error')],
        nextCheckInterval: 30000,
        jwt: '',
        userId: userId,
        clientId: '',
        country: '',
        state: '',
      );

  // --- basic methods -------------------------------------------------------

  @override
  Future<String> version() =>
      _guard('version', (_) => '', () async => (await _once('version')) as String? ?? '');

  @override
  Future<String> deviceId() =>
      _guard('deviceId', (_) => '', () async => (await _once('deviceId')) as String? ?? '');

  @override
  Future<bool> isClientKeyValid(String clientKey) async {
    if (clientKey.isEmpty) return false;
    return _guard('isClientKeyValid', (_) => false,
        () async => (await _once('isClientKeyValid', {'clientKey': clientKey})) as bool? ?? false);
  }

  @override
  Future<String> host(String clientKey) async {
    if (clientKey.isEmpty) return '';
    return _guard('host', (_) => '', () async => (await _once('host', {'clientKey': clientKey})) as String? ?? '');
  }

  @override
  Future<void> updateUserAgent(String userAgent) async {
    if (userAgent.isEmpty) return;
    await _once('updateUserAgent', {'userAgent': userAgent});
  }

  @override
  Future<void> startDataCollection() async {
    await _once('startDataCollection');
  }

  @override
  Future<void> initializeLogSender() async {
    await _once('initializeLogSender');
  }

  // --- jurisdiction --------------------------------------------------------

  @override
  Future<List<JurisdictionArea>> availableJurisdictionAreas(String clientKey, {String? clientBrand}) async {
    if (clientKey.isEmpty) return [];
    return _guard('availableJurisdictionAreas', (_) => <JurisdictionArea>[], () async {
      final list = (await _once('availableJurisdictionAreas', {
        'clientKey': clientKey,
        if (clientBrand != null) 'clientBrand': clientBrand,
      })) as List?;
      return list?.map((a) => JurisdictionArea.fromMap(Map<String, dynamic>.from(a))).toList() ?? [];
    });
  }

  @override
  Future<JurisdictionAreas?> suitableJurisdictionArea(String clientKey, String? clientBrand) async {
    if (clientKey.isEmpty) return null;
    return _guard('suitableJurisdictionArea', (_) => null, () async {
      final map = await _once('suitableJurisdictionArea', {
        'clientKey': clientKey,
        if (clientBrand != null) 'clientBrand': clientBrand,
      });
      return map == null ? null : JurisdictionAreas.fromMap(Map<String, dynamic>.from(map));
    });
  }

  // --- session -------------------------------------------------------------

  @override
  Future<Session> defaultSession(String clientKey, String userId, {String? clientBrand, String? sessionId}) async {
    if (clientKey.isEmpty || userId.isEmpty) {
      throw ArgumentError('Client key and user ID cannot be empty');
    }
    final id = (await _once('session.id', {'session': _session(clientKey, userId, clientBrand, sessionId)})) as String? ?? '';
    return Session(sessionId: id, clientKey: clientKey, userId: userId, clientBrand: clientBrand);
  }

  @override
  Future<Session?> getDefaultSession() async {
    // The dispatcher is stateless and keeps no implicit default session.
    return null;
  }

  @override
  Future<CheckResult> check(String clientKey, String userId, String? clientBrand, {bool force = false}) async {
    if (clientKey.isEmpty || userId.isEmpty) {
      throw ArgumentError('Client key and user ID cannot be empty');
    }
    return _guard('lite check', (e) => _dispatcherError(userId, e), () async {
      final map = await _once('session.checkerLite.check', {
        'session': _session(clientKey, userId, clientBrand),
        'force': force,
      });
      return CheckResult.fromMap(Map<String, dynamic>.from(map));
    });
  }

  @override
  Future<void> deleteSession(String clientKey, String userId, String? clientBrand) async {
    await _once('session.delete', {'session': _session(clientKey, userId, clientBrand)});
  }

  @override
  Future<String?> getCustomData(String clientKey, String userId, String? clientBrand) async {
    if (clientKey.isEmpty || userId.isEmpty) return null;
    return _guard('getCustomData', (_) => null,
        () async => (await _once('session.customData.get', {'session': _session(clientKey, userId, clientBrand)})) as String?);
  }

  @override
  Future<void> setCustomData(String clientKey, String userId, String? clientBrand, String customData) async {
    await _once('session.customData.set', {
      'session': _session(clientKey, userId, clientBrand),
      'customData': customData,
    });
  }

  @override
  Future<JurisdictionArea?> getSessionJurisdictionArea(String clientKey, String userId, String? clientBrand) async {
    if (clientKey.isEmpty || userId.isEmpty) return null;
    return _guard('getSessionJurisdictionArea', (_) => null, () async {
      final map = await _once('session.jurisdictionArea.get', {'session': _session(clientKey, userId, clientBrand)});
      return map == null ? null : JurisdictionArea.fromMap(Map<String, dynamic>.from(map));
    });
  }

  @override
  Future<void> setSessionJurisdictionArea(String clientKey, String userId, String? clientBrand, JurisdictionArea? area) async {
    await _once('session.jurisdictionArea.set', {
      'session': _session(clientKey, userId, clientBrand),
      'area': {'id': area?.id ?? '', 'name': area?.name ?? ''},
    });
  }

  // --- periodic (streaming) ------------------------------------------------

  @override
  Future<void> start(String clientKey, String userId, String? clientBrand, Function(CheckResult) onResult) async {
    if (clientKey.isEmpty || userId.isEmpty) {
      throw ArgumentError('Client key and user ID cannot be empty');
    }
    final id = _tag(clientKey, userId, clientBrand);
    // Periodic-checker parts are CheckResult maps; non-map parts (e.g. the
    // 'scheduled' lifecycle ping) carry no result and are ignored here.
    _streams[id] = (payload) {
      if (payload is Map) onResult(CheckResult.fromMap(Map<String, dynamic>.from(payload)));
    };
    try {
      await methodChannel.invokeMethod<void>(
        'xp_rpc_call',
        json.encode({
          'id': id,
          'type': 'many',
          'method': 'session.periodicChecker.start',
          'args': {'session': _session(clientKey, userId, clientBrand)},
        }),
      );
    } catch (e) {
      _streams.remove(id);
      debugPrint('Failed to start periodic checker: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop(String clientKey, String userId, String? clientBrand) async {
    final id = _tag(clientKey, userId, clientBrand);
    try {
      await methodChannel.invokeMethod<void>('xp_rpc_call', json.encode({'id': id, 'type': 'halt'}));
    } finally {
      _streams.remove(id);
    }
  }

  @override
  Future<bool> triggerCheck({String? reason}) async {
    // The dispatcher needs session credentials; the facade does not carry them
    // here, so this path is not served over the dispatcher transport.
    debugPrint('triggerCheck is not supported on the dispatcher transport');
    return false;
  }
}
