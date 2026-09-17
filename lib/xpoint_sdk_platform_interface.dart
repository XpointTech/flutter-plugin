import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'xpoint_sdk_method_channel.dart';
import 'xpoint_sdk.dart';

abstract class XpointSdkPlatform extends PlatformInterface {
  /// Constructs a XpointSdkPlatform.
  XpointSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static XpointSdkPlatform _instance = MethodChannelXpointSdk();

  /// The default instance of [XpointSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelXpointSdk].
  static XpointSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [XpointSdkPlatform] when
  /// they register themselves.
  static set instance(XpointSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> version() {
    throw UnimplementedError('version() has not been implemented.');
  }

  Future<String> deviceId() {
    throw UnimplementedError('deviceId() has not been implemented.');
  }

  Future<bool> isClientKeyValid(String clientKey) {
    throw UnimplementedError('isClientKeyValid() has not been implemented.');
  }

  Future<String> host(String clientKey) {
    throw UnimplementedError('host() has not been implemented.');
  }
  
  Future<void> updateUserAgent(String userAgent) {
    throw UnimplementedError('updateUserAgent() has not been implemented.');
  }
  
  Future<List<JurisdictionArea>> availableJurisdictionAreas(String clientKey, {String? clientBrand}) {
    throw UnimplementedError('availableJurisdictionAreas() has not been implemented.');
  }
  
  Future<JurisdictionAreas?> suitableJurisdictionArea(String clientKey, String? clientBrand) {
    throw UnimplementedError('suitableJurisdictionArea() has not been implemented.');
  }

  Future<Session> defaultSession(String clientKey, String userId, {String? clientBrand, String? sessionId}) {
    throw UnimplementedError('defaultSession() has not been implemented.');
  }

  Future<Session?> getDefaultSession() {
    throw UnimplementedError('getDefaultSession() has not been implemented.');
  }

  Future<void> start(String clientKey, String userId, String? clientBrand, Function(CheckResult) onResult) {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> stop(String clientKey, String userId, String? clientBrand) {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<bool> triggerCheck({String? reason}) {
    throw UnimplementedError('triggerCheck() has not been implemented.');
  }

  Future<CheckResult> check(
    String clientKey,
    String userId,
    String? clientBrand,
    {bool force = false}
  ) {
    throw UnimplementedError('check() has not been implemented.');
  }

  Future<void> deleteSession(String clientKey, String userId, String? clientBrand) {
    throw UnimplementedError('deleteSession() has not been implemented.');
  }

  Future<String?> getCustomData(String clientKey, String userId, String? clientBrand) {
    throw UnimplementedError('getCustomData() has not been implemented.');
  }

  Future<void> setCustomData(String clientKey, String userId, String? clientBrand, String customData) {
    throw UnimplementedError('setCustomData() has not been implemented.');
  }

  Future<JurisdictionArea?> getSessionJurisdictionArea(String clientKey, String userId, String? clientBrand) {
    throw UnimplementedError('getSessionJurisdictionArea() has not been implemented.');
  }

  Future<void> setSessionJurisdictionArea(String clientKey, String userId, String? clientBrand, JurisdictionArea? area) {
    throw UnimplementedError('setSessionJurisdictionArea() has not been implemented.');
  }

  Future<void> startDataCollection() {
    throw UnimplementedError('startDataCollection() has not been implemented.');
  }

  Future<void> initializeLogSender() {
    throw UnimplementedError('initializeLogSender() has not been implemented.');
  }
}
