/// XPoint SDK for Flutter
///
/// A comprehensive Flutter plugin that provides access to XPoint's geolocation
/// and compliance checking services. This SDK allows you to create sessions,
/// perform location-based compliance checks, and manage periodic monitoring
/// of user locations for regulatory compliance.
///
/// ## Quick Start
///
/// ```dart
/// // Initialize the SDK
/// final sdk = XpointSdk();
///
/// // Validate client key first
/// final isValid = await sdk.isClientKeyValid('your-client-key');
/// if (!isValid) return;
///
/// // Create a session
/// final session = await sdk.defaultSession('your-client-key', 'user-123');
///
/// // Option 1: Start periodic monitoring
/// final periodicChecker = session.periodicChecker();
/// await periodicChecker.start((result) {
///   print('Check result: ${result.status}');
///   if (result.errors.isNotEmpty) {
///     print('Errors: ${result.errors.map((e) => '${e.code}: ${e.description}').join(', ')}');
///   }
/// });
///
/// // Option 2: Quick one-time check
/// final checkerLite = await session.checkerLite();
/// final result = await checkerLite.check();
/// print('Compliant: ${result.status == CheckResponseStatus.allowed}');
/// if (result.errors.isNotEmpty) {
///   print('Errors: ${result.errors.map((e) => '${e.code}: ${e.description}').join(', ')}');
/// }
///
/// ```
///
/// ## Main Components
///
/// - [XpointSdk]: Main SDK interface for configuration and session creation
/// - [Session]: Represents a user session with compliance checking capabilities
/// - [PeriodicChecker]: Handles automatic periodic location compliance checks
/// - [CheckerLite]: Lightweight one-time compliance checking
/// - [CheckResult]: Contains the results of compliance checks
/// - [JurisdictionArea]: Represents geographical compliance jurisdictions
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'xpoint_sdk_platform_interface.dart';

/// Status enumeration for compliance check responses
///
/// Represents the current state of a compliance check operation.
enum CheckResponseStatus {
  /// Check is idle/not started
  idle,

  /// Check is in progress, waiting for completion
  waiting,

  /// Location is compliant and allowed
  allowed,

  /// Location is not compliant and denied
  denied;

  /// Creates a [CheckResponseStatus] from an integer index
  ///
  /// This is used internally for deserializing responses from the native SDK.
  /// Returns [idle] if the index is invalid.
  static CheckResponseStatus fromIndex(int index) {
    if (index >= 0 && index < CheckResponseStatus.values.length) {
      return CheckResponseStatus.values[index];
    }
    return CheckResponseStatus.idle;
  }

  /// Creates a [CheckResponseStatus] from a string value
  ///
  /// This is used for parsing JSON responses that contain status as strings.
  /// Returns [idle] if the string is not recognized.
  static CheckResponseStatus fromString(String status) {
    final statusStr = status.toLowerCase();
    switch (statusStr) {
      case 'allowed':
        return CheckResponseStatus.allowed;
      case 'denied':
        return CheckResponseStatus.denied;
      case 'waiting':
        return CheckResponseStatus.waiting;
      case 'idle':
        return CheckResponseStatus.idle;
      default:
        return CheckResponseStatus.idle;
    }
  }

  /// Creates a [CheckResponseStatus] from dynamic input (string or int)
  ///
  /// Handles both string and integer representations of status.
  static CheckResponseStatus fromDynamic(dynamic status) {
    if (status is String) {
      return fromString(status);
    } else if (status is int) {
      return fromIndex(status);
    }
    return CheckResponseStatus.idle;
  }
}

/// Represents a geographical jurisdiction area for compliance checking
///
/// A jurisdiction area defines a specific geographical region with its own
/// compliance rules and regulations. This is used to determine which
/// regulatory framework applies to a user's location.
///
/// ## Example
/// ```dart
/// final area = JurisdictionArea(
///   id: 'US-CA',
///   name: 'California, United States'
/// );
/// ```
class JurisdictionArea {
  /// Unique identifier for the jurisdiction area
  final String id;

  /// Human-readable name of the jurisdiction area
  final String name;

  const JurisdictionArea({required this.id, required this.name});

  /// Creates a [JurisdictionArea] from a map representation
  ///
  /// Used internally for deserializing data from the native SDK.
  factory JurisdictionArea.fromMap(Map<String, dynamic> map) {
    return JurisdictionArea(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  /// Converts this [JurisdictionArea] to a map representation
  ///
  /// Used internally for serializing data to the native SDK.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'JurisdictionArea(id: $id, name: $name)';
}

/// Container for multiple jurisdiction areas with recommendations
///
/// When requesting suitable jurisdiction areas, the SDK returns both a
/// preferred area (if available) and a list of candidate areas that
/// could apply to the user's situation.
///
/// ## Example
/// ```dart
/// final areas = await sdk.suitableJurisdictionArea(clientKey, clientBrand);
/// if (areas?.preferableArea != null) {
///   print('Recommended: ${areas!.preferableArea!.name}');
/// }
/// print('Candidates: ${areas?.candidateAreas.length ?? 0}');
/// ```
class JurisdictionAreas {
  /// The recommended jurisdiction area for the current context
  final JurisdictionArea? preferableArea;

  /// List of all jurisdiction areas that could potentially apply
  final List<JurisdictionArea> candidateAreas;

  const JurisdictionAreas({
    this.preferableArea,
    required this.candidateAreas,
  });

  /// Creates a [JurisdictionAreas] from a map representation
  ///
  /// Used internally for deserializing data from the native SDK.
  factory JurisdictionAreas.fromMap(Map<String, dynamic> map) {
    return JurisdictionAreas(
      preferableArea: map['preferableArea'] != null
        ? JurisdictionArea.fromMap(Map<String, dynamic>.from(map['preferableArea']))
        : null,
      candidateAreas: (map['candidateAreas'] as List? ?? [])
        .map((area) => JurisdictionArea.fromMap(Map<String, dynamic>.from(area)))
        .toList(),
    );
  }

  @override
  String toString() => 'JurisdictionAreas(preferableArea: $preferableArea, candidateAreas: $candidateAreas)';
}

/// Represents an error that occurred during a compliance check
///
/// When a compliance check encounters issues, detailed error information
/// is provided to help understand what went wrong and how to resolve it.
///
/// ## Example
/// ```dart
/// if (result.errors.isNotEmpty) {
///   for (final error in result.errors) {
///     print('Error ${error.code}: ${error.description}');
///   }
/// }
/// ```
class CheckResponseError {
  /// Numerical error code for programmatic handling
  final int code;

  /// Detailed description of the error
  final String description;

  /// Short summary of the error for UI display
  final String shortSummary;

  const CheckResponseError({
    required this.code,
    required this.description,
    required this.shortSummary,
  });

  @override
  String toString() => 'CheckResponseError(code: $code, description: $description)';
}

/// Complete result of a compliance check operation
///
/// Contains all information returned from a compliance check, including
/// the compliance status, location data, errors (if any), and metadata
/// for follow-up actions.
///
/// ## Example
/// ```dart
/// final result = await checker.check();
///
/// print('Status: ${result.status}');
/// print('Location: ${result.country}, ${result.state}');
///
/// if (result.errors.isNotEmpty) {
///   print('Errors: ${result.errorDescription}');
/// }
/// ```
class CheckResult {
  /// Unique identifier for this specific check request
  final String requestId;

  /// Current status of the compliance check
  final CheckResponseStatus status;

  /// List of errors encountered during the check (empty if successful)
  final List<CheckResponseError> errors;

  /// Recommended interval in milliseconds until the next check should be performed
  final int nextCheckInterval;

  /// JSON Web Token containing signed check results (for verification)
  final String jwt;

  /// User ID associated with this check
  final String userId;

  /// Client ID associated with this check
  final String clientId;

  /// Country code where the user is located
  final String country;

  /// State/province code where the user is located
  final String state;

  /// Latitude coordinate of the user's location (if available)
  final double? latitude;

  /// Longitude coordinate of the user's location (if available)
  final double? longitude;

  /// Jurisdiction area that applies to this location (if determined)
  final JurisdictionArea? jurisdictionArea;

  const CheckResult({
    required this.requestId,
    required this.status,
    required this.errors,
    required this.nextCheckInterval,
    required this.jwt,
    required this.userId,
    required this.clientId,
    required this.country,
    required this.state,
    this.latitude,
    this.longitude,
    this.jurisdictionArea
  });

  factory CheckResult.fromMap(Map<String, dynamic> map) {
    List<CheckResponseError> parseErrors(dynamic errorsData) {
      if (errorsData == null) return [];
      if (errorsData is! List) return [];

      return errorsData.map((errorMap) {
        if (errorMap is Map<String, dynamic>) {
          return CheckResponseError(
            code: errorMap['code'] ?? 0,
            description: errorMap['description'] ?? '',
            shortSummary: errorMap['shortSummary'] ?? '',
          );
        }
        return CheckResponseError(code: 0, description: errorMap.toString(), shortSummary: '');
      }).toList();
    }

    final status = CheckResponseStatus.fromDynamic(map['status']);
    return CheckResult(
      requestId: map['requestId'] ?? '',
      status: status,
      errors: parseErrors(map['errors']),
      nextCheckInterval: map['nextCheckInterval'] ?? 0,
      jwt: map['jwt'] ?? '',
      userId: map['userId'] ?? '',
      clientId: map['clientId'] ?? '',
      country: map['country'] ?? '',
      state: map['state'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      jurisdictionArea: map['jurisdictionArea'] != null
        ? JurisdictionArea.fromMap(Map<String, dynamic>.from(map['jurisdictionArea']))
        : null
    );
  }

  /// Returns a concatenated string of all error descriptions
  ///
  /// Useful for displaying error information in UI components.
  /// Returns an empty string if there are no errors.
  String get errorDescription {
    return errors.map((e) => e.description).join(', ');
  }

  /// Returns error descriptions with their codes for detailed debugging
  ///
  /// Format: "code1: description1, code2: description2"
  /// Returns an empty string if there are no errors.
  String get errorDescriptionWithCodes {
    return errors.map((e) => '${e.code}: ${e.description}').join(', ');
  }

  @override
  String toString() => 'CheckResult(status: $status, requestId: $requestId)';
}

/// Represents a user session for compliance checking
///
/// A session encapsulates all the information needed to perform compliance
/// checks for a specific user. It maintains the user's identity, client
/// credentials, and provides access to various checking mechanisms.
///
/// Sessions are created through the [XpointSdk] and provide access to:
/// - Periodic compliance monitoring
/// - One-time compliance checks
/// - Session data management
/// - Jurisdiction area configuration
///
/// ## Example
/// ```dart
/// // Create a session
/// final session = await sdk.defaultSession('client-key', 'user-123');
///
/// // Use the session for periodic monitoring
/// final periodicChecker = session.periodicChecker();
/// await periodicChecker.start((result) {
///   print('Check result: ${result.status}');
/// });
///
/// // Or for one-time checks
/// final checker = await session.getSessionChecker();
/// final result = await checker.check();
/// ```
class Session {
  /// Unique identifier for this session
  final String sessionId;

  /// Client key used for authentication and authorization
  final String clientKey;

  /// User identifier associated with this session
  final String userId;

  /// Optional client brand identifier for multi-brand scenarios
  final String? clientBrand;

  Session({
    required this.sessionId,
    required this.clientKey,
    required this.userId,
    this.clientBrand,
  });

  /// Creates a periodic checker for automated compliance monitoring
  ///
  /// Returns a [PeriodicChecker] that can be used to start automated
  /// location compliance checks at regular intervals.
  ///
  /// ## Example
  /// ```dart
  /// final periodicChecker = session.periodicChecker();
  /// await periodicChecker.start((result) {
  ///   if (result.status == CheckResponseStatus.allowed) {
  ///     print('Location is compliant');
  ///   } else {
  ///     print('Location is not compliant: ${result.errorDescription}');
  ///   }
  /// });
  /// ```
  PeriodicChecker periodicChecker() {
    return PeriodicChecker(
      sessionId: sessionId,
      clientKey: clientKey,
      userId: userId,
      clientBrand: clientBrand,
    );
  }

  /// Permanently removes this session from the system
  ///
  /// This will stop any active periodic checkers associated with the session
  /// and clean up all related resources. Once deleted, the session cannot be used
  /// for further operations.
  ///
  /// **Warning:** This action cannot be undone.
  Future<void> deleteSession() async {
    try {
      await XpointSdkPlatform.instance.deleteSession(clientKey, userId, clientBrand);
    } catch (e) {
      debugPrint('Failed to delete session: $e');
      rethrow;
    }
  }


  /// Creates a lightweight session checker for basic compliance checks
  ///
  /// Returns a [CheckerLite] that provides essential compliance
  /// checking functionality with reduced overhead and faster response times.
  /// Use this for applications where performance is critical and full
  /// feature set is not required.
  ///
  /// ## Example
  /// ```dart
  /// final checker = await session.checkerLite();
  /// final result = await checker.check();
  /// print('Quick compliance check: ${result.status == CheckResponseStatus.allowed}');
  /// ```
  Future<CheckerLite> checkerLite() async {
    return CheckerLite(
      clientKey: clientKey,
      userId: userId,
      sessionId: sessionId,
      clientBrand: clientBrand,
    );
  }

  /// Gets the current jurisdiction area for this session
  ///
  /// Returns the currently set jurisdiction area, or null if using automatic detection.
  Future<JurisdictionArea?> get jurisdictionArea async {
    debugPrint('[XPoint SDK] Session.jurisdictionArea getter called for sessionId: $sessionId');
    try {
      final result = await XpointSdkPlatform.instance.getSessionJurisdictionArea(clientKey, userId, clientBrand);
      debugPrint('[XPoint SDK] Session.jurisdictionArea getter result: ${result?.toMap()}');
      return result;
    } catch (e) {
      debugPrint('Failed to get jurisdiction area: $e');
      return null;
    }
  }

  /// Sets the jurisdiction area for this session
  ///
  /// When set, all compliance checks for this session will be performed
  /// according to the rules of the specified jurisdiction area.
  set jurisdictionArea(Future<JurisdictionArea?> areaFuture) {
    areaFuture.then((area) {
      debugPrint('[XPoint SDK] Session.jurisdictionArea setter called for sessionId: $sessionId with area: ${area?.toMap()}');
      return XpointSdkPlatform.instance.setSessionJurisdictionArea(clientKey, userId, clientBrand, area);
    }).then((_) {
      debugPrint('[XPoint SDK] Session.jurisdictionArea setter completed successfully');
    }).catchError((e) {
      debugPrint('Failed to set jurisdiction area: $e');
    });
  }

  /// Sets custom data for this session
  ///
  /// Stores custom string data associated with this session. This data can be
  /// retrieved later using [getCustomData] and will be available during
  /// periodic checks for additional context.
  ///
  /// [customData] A string containing any custom data to store
  ///
  /// ## Example
  /// ```dart
  /// await session.setCustomData('{"userId": "user123", "gameLevel": 5}');
  /// // Or any other format
  /// await session.setCustomData('user123:level5:premium');
  /// ```
  Future<void> setCustomData(String customData) async {
    debugPrint('[XPoint SDK] Session.setCustomData called for sessionId: $sessionId');
    try {
      await XpointSdkPlatform.instance.setCustomData(clientKey, userId, clientBrand, customData);
      debugPrint('[XPoint SDK] Session.setCustomData completed successfully');
    } catch (e) {
      debugPrint('Failed to set custom data: $e');
      rethrow;
    }
  }

  /// Gets custom data for this session
  ///
  /// Retrieves custom string data previously stored with [setCustomData].
  /// Returns null if no custom data has been set for this session.
  ///
  /// Returns the string data exactly as it was stored.
  ///
  /// ## Example
  /// ```dart
  /// final data = await session.getCustomData();
  /// if (data != null) {
  ///   print('Custom data: $data');
  /// }
  /// ```
  Future<String?> getCustomData() async {
    debugPrint('[XPoint SDK] Session.getCustomData called for sessionId: $sessionId');
    try {
      final result = await XpointSdkPlatform.instance.getCustomData(clientKey, userId, clientBrand);
      debugPrint('[XPoint SDK] Session.getCustomData result: $result');
      return result;
    } catch (e) {
      debugPrint('Failed to get custom data: $e');
      rethrow;
    }
  }

}

/// Lightweight compliance checker optimized for performance
///
/// Provides essential compliance checking functionality with reduced overhead
/// and faster response times. Use this when you need quick compliance decisions
/// and can accept reduced detail in the response.
///
/// Created through [Session.checkerLite()].
///
/// ## Example
/// ```dart
/// final checker = await session.checkerLite();
///
/// // Perform a lightweight check
/// final result = await checker.check();
///
/// // Quick compliance decision
/// if (result.status == CheckResponseStatus.allowed) {
///   // Proceed with user action
///   processUserRequest();
/// } else {
///   // Handle compliance violation
///   if (result.errors.isNotEmpty) {
///     final errorMessage = result.errors.map((e) => '${e.code}: ${e.description}').join(', ');
///     showComplianceMessage(errorMessage);
///   }
/// }
///
/// // Force a fresh check (bypass cache)
/// final freshResult = await checker.check(force: true);
/// ```
class CheckerLite {
  /// Session parameters needed for checker lite operations
  final String clientKey;
  final String userId;
  final String sessionId;
  final String? clientBrand;

  CheckerLite({
    required this.clientKey,
    required this.userId,
    required this.sessionId,
    this.clientBrand,
  });

  /// Performs a lightweight compliance check
  ///
  /// Executes an optimized compliance check using this checker lite instance.
  /// Returns essential compliance information with minimal latency.
  ///
  /// [force] When `true`, bypasses any caching and performs a fresh check.
  ///         When `false` (default), may return cached results if available.
  ///
  /// Returns a [CheckResult] with essential compliance information including:
  /// - Compliance status (allowed/denied/waiting/idle)
  /// - Error details with proper formatting: `result.errors.map((e) => '${e.code}: ${e.description}').join(', ')`
  /// - Location information (country, state, coordinates)
  /// - Jurisdiction area details
  /// - Next check interval recommendation
  ///
  /// ## Example
  /// ```dart
  /// final result = await checkerLite.check();
  ///
  /// if (result.status == CheckResponseStatus.allowed) {
  ///   print('✅ Compliance check passed');
  /// } else {
  ///   print('❌ Compliance violation');
  ///   if (result.errors.isNotEmpty) {
  ///     final errorMsg = result.errors.map((e) => '${e.code}: ${e.description}').join(', ');
  ///     print('Errors: $errorMsg');
  ///   }
  /// }
  /// ```
  ///
  /// Throws an exception if the check fails due to network, authentication,
  /// or other system issues.
  Future<CheckResult> check({bool force = false}) async {
    try {
      return await XpointSdkPlatform.instance.check(
        clientKey, userId, clientBrand, force: force);
    } catch (e) {
      debugPrint('Checker lite check failed: $e');
      rethrow;
    }
  }
}

/// Automated periodic compliance checker
///
/// Manages continuous compliance monitoring by automatically performing
/// location checks at regular intervals. This is ideal for applications
/// that need to maintain ongoing compliance awareness without manual
/// intervention.
///
/// Created through [Session.periodicChecker()].
///
/// ## Key Features
/// - Automatic scheduling based on compliance rules
/// - Real-time result notifications via callbacks and streams
/// - Intelligent interval adjustment based on location and compliance status
/// - Background operation with minimal impact on app performance
///
/// ## Example
/// ```dart
/// final periodicChecker = session.periodicChecker();
///
/// // Start monitoring with callback
/// await periodicChecker.start((result) {
///   print('Periodic check result: ${result.status}');
///
///   if (result.status != CheckResponseStatus.allowed) {
///     // Handle non-compliant state
///     handleComplianceViolation(result);
///   }
/// });
///
/// // Or listen to the stream
/// periodicChecker.results.listen((result) {
///   updateUI(result);
/// });
///
/// // Stop monitoring when no longer needed
/// await periodicChecker.stop();
/// ```
class PeriodicChecker {
  final String _sessionId;
  final String _clientKey;
  final String _userId;
  final String? _clientBrand;
  bool _isRunning = false;
  StreamController<CheckResult>? _resultController;

  PeriodicChecker({
    required String sessionId,
    required String clientKey,
    required String userId,
    String? clientBrand,
  }) : _sessionId = sessionId,
        _clientKey = clientKey,
        _userId = userId,
        _clientBrand = clientBrand;

  /// Stream of compliance check results
  ///
  /// Provides real-time updates whenever a periodic check completes.
  /// The stream is active only while the periodic checker is running.
  Stream<CheckResult> get results => _resultController?.stream ?? const Stream.empty();

  /// Starts automated periodic compliance monitoring
  ///
  /// Begins continuous compliance checking at intervals determined by the
  /// compliance service. The checker will automatically adjust intervals
  /// based on various factors including location stability, compliance
  /// status, and regulatory requirements.
  ///
  /// [callback] Optional callback function invoked for each check result.
  ///            This is in addition to the [results] stream.
  ///
  /// Does nothing if the checker is already running.
  ///
  /// ## Example
  /// ```dart
  /// await periodicChecker.start((result) {
  ///   if (result.status == CheckResponseStatus.denied) {
  ///     // Immediately handle compliance violation
  ///     showComplianceWarning();
  ///   }
  /// });
  /// ```
  Future<void> start(Function(CheckResult)? callback) async {
    if (_isRunning) {
      return;
    }

    StreamController<CheckResult>? tempController;
    try {
      tempController = StreamController<CheckResult>.broadcast();

      // Start the native periodic checker using full session parameters
      await XpointSdkPlatform.instance.start(_clientKey, _userId, _clientBrand, (result) {
        try {
          tempController?.add(result);
          callback?.call(result);
        } catch (callbackError) {
          debugPrint('Error in periodic checker callback: $callbackError');
          tempController?.addError(callbackError);
        }
      });

      _resultController = tempController;
      _isRunning = true;

    } catch (error) {
      debugPrint('Failed to start periodic checker: $error');
      tempController?.addError(error);
      await tempController?.close();
      rethrow;
    }
  }

  /// Stops the automated periodic compliance monitoring
  ///
  /// Halts all scheduled compliance checks and cleans up associated
  /// resources. After stopping, no further check results will be
  /// generated until [start] is called again.
  ///
  /// Safe to call multiple times or when not running.
  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;

    Exception? stopError;
    try {
      await XpointSdkPlatform.instance.stop(_clientKey, _userId, _clientBrand);
    } catch (error) {
      debugPrint('Error stopping periodic checker: $error');
      stopError = Exception('Failed to stop periodic checker: $error');
    }

    // Always clean up the stream controller
    try {
      await _resultController?.close();
    } catch (error) {
      debugPrint('Error closing result stream: $error');
    } finally {
      _resultController = null;
    }

    // Re-throw stop error if one occurred
    if (stopError != null) {
      throw stopError;
    }
  }

  /// Triggers an immediate location check regardless of the scheduled interval
  ///
  /// Use this method to force a compliance check when a significant event occurs,
  /// such as placing a bet or starting a wagering session.
  ///
  /// [reason] Optional reason for the triggered check (e.g., "bet", "wager_start").
  ///          When null/empty, indicates an automation-triggered check.
  ///
  /// Returns `true` if the check was successfully triggered, `false` otherwise.
  ///
  /// ## Example
  /// ```dart
  /// // Trigger check when user places a bet
  /// final success = await periodicChecker.triggerCheck(reason: "bet");
  /// if (success) {
  ///   print('Check triggered successfully');
  /// }
  /// ```
  Future<bool> triggerCheck({String? reason}) async {
    return XpointSdkPlatform.instance.triggerCheck(reason: reason);
  }
}

/// Main entry point for the XPoint SDK
///
/// This singleton class provides the primary interface for interacting with
/// XPoint's geolocation compliance services. Use this class to configure
/// the SDK, validate credentials, query jurisdiction information, and create
/// user sessions for compliance monitoring.
///
/// ## Singleton Pattern
/// The SDK uses a singleton pattern to ensure consistent configuration
/// across your application:
///
/// ```dart
/// final sdk = XpointSdk(); // Always returns the same instance
/// ```
///
/// ## Basic Usage Flow
///
/// 1. **Initialize**
/// 2. **Query available jurisdictions** (optional)
/// 3. **Create user sessions**
/// 4. **Start compliance monitoring**
///
/// ## Example
/// ```dart
/// final sdk = XpointSdk();
///
///
/// // Create a user session
/// final session = await sdk.defaultSession('your-client-key', 'user-123');
///
/// // Start monitoring
/// final checker = session.periodicChecker();
/// await checker.start((result) {
///   print('Compliance status: ${result.status}');
/// });
/// ```
class XpointSdk {
  static final XpointSdk _instance = XpointSdk._internal();

  /// Returns the singleton instance of the XPoint SDK
  factory XpointSdk() => _instance;
  XpointSdk._internal();

  /// Gets the current SDK version
  ///
  /// Returns the version string of the XPoint SDK currently in use.
  /// Useful for debugging and support purposes.
  Future<String> version() async {
    try {
      return await XpointSdkPlatform.instance.version();
    } catch (e) {
      debugPrint('Failed to get SDK version: $e');
      return 'unknown';
    }
  }

  /// Gets a unique device identifier
  ///
  /// Returns a unique identifier for the current device. This identifier
  /// is used internally by the compliance system and remains consistent
  /// across app sessions on the same device.
  Future<String> deviceId() async {
    try {
      return await XpointSdkPlatform.instance.deviceId();
    } catch (e) {
      debugPrint('Failed to get device ID: $e');
      return 'unknown';
    }
  }

  /// Validates a client key
  ///
  /// Checks if the provided client key is valid and can be used for
  /// compliance operations. Returns true if valid, false otherwise.
  ///
  /// [clientKey] Your XPoint client key to validate
  ///
  /// ## Example
  /// ```dart
  /// final isValid = await sdk.isClientKeyValid('your-client-key');
  /// if (isValid) {
  ///   print('Client key is valid');
  /// } else {
  ///   print('Invalid client key');
  /// }
  /// ```
  Future<bool> isClientKeyValid(String clientKey) async {
    if (clientKey.isEmpty) {
      return false;
    }

    try {
      return await XpointSdkPlatform.instance.isClientKeyValid(clientKey);
    } catch (e) {
      debugPrint('Failed to validate client key: $e');
      return false;
    }
  }

  /// Gets the host URL for a client key
  ///
  /// Returns the host URL that should be used for API requests
  /// with the given client key. This is useful for debugging
  /// connectivity issues or for informational purposes.
  ///
  /// [clientKey] Your XPoint client key
  ///
  /// ## Example
  /// ```dart
  /// final host = await sdk.getHost('your-client-key');
  /// print('API host: $host');
  /// ```
  Future<String> host(String clientKey) async {
    if (clientKey.isEmpty) {
      return '';
    }

    try {
      return await XpointSdkPlatform.instance.host(clientKey);
    } catch (e) {
      debugPrint('Failed to get host: $e');
      return '';
    }
  }

  /// Updates the user agent string
  ///
  /// Sets a custom user agent string that will be used in HTTP requests
  /// made by the SDK. This can be useful for tracking or identification
  /// purposes.
  ///
  /// [userAgent] The user agent string to use
  ///
  /// ## Example
  /// ```dart
  /// await sdk.updateUserAgent('MyApp/1.0.0 (iOS 15.0)');
  /// ```
  Future<void> updateUserAgent(String userAgent) async {
    if (userAgent.isEmpty) {
      throw ArgumentError('User agent cannot be empty');
    }

    try {
      await XpointSdkPlatform.instance.updateUserAgent(userAgent);
    } catch (e) {
      debugPrint('Failed to update user agent: $e');
      rethrow;
    }
  }

  /// Retrieves all available jurisdiction areas for a client
  ///
  /// Returns a list of all jurisdiction areas that are available
  /// for compliance checking with the given client credentials.
  /// This can be used to populate UI selection lists or to understand
  /// the scope of available compliance regions.
  ///
  /// [clientKey] Your XPoint client key
  /// [clientBrand] Optional client brand identifier for multi-brand clients
  ///
  /// ## Example
  /// ```dart
  /// final areas = await sdk.availableJurisdictionAreas('your-client-key');
  /// for (final area in areas) {
  ///   print('Available: ${area.name} (${area.id})');
  /// }
  /// ```
  Future<List<JurisdictionArea>> availableJurisdictionAreas(String clientKey, {String? clientBrand}) async {
    if (clientKey.isEmpty) {
      throw ArgumentError('Client key cannot be empty');
    }

    try {
      return await XpointSdkPlatform.instance.availableJurisdictionAreas(clientKey, clientBrand: clientBrand);
    } catch (e) {
      debugPrint('Failed to get available jurisdiction areas: $e');
      return [];
    }
  }

  /// Gets suitable jurisdiction areas with contextual recommendations
  ///
  /// Returns a [JurisdictionAreas] object containing both a recommended area
  /// (if available) and a list of candidate areas that could apply to the
  /// current context. This is more intelligent than [availableJurisdictionAreas]
  /// as it provides contextual recommendations based on user location and other factors.
  ///
  /// [clientKey] Your XPoint client key
  /// [clientBrand] Optional client brand identifier for multi-brand clients
  ///
  /// ## Example
  /// ```dart
  /// final areas = await sdk.suitableJurisdictionArea('your-client-key');
  /// if (areas?.preferableArea != null) {
  ///   print('Recommended: ${areas!.preferableArea!.name}');
  ///   // Use the recommended area
  ///   session.jurisdictionArea = Future.value(areas.preferableArea);
  /// } else if (areas?.candidateAreas.isNotEmpty == true) {
  ///   print('Available candidates: ${areas!.candidateAreas.length}');
  ///   // Choose from candidates or let user select
  /// }
  /// ```
  Future<JurisdictionAreas?> suitableJurisdictionArea(String clientKey, {String? clientBrand}) async {
    if (clientKey.isEmpty) {
      throw ArgumentError('Client key cannot be empty');
    }

    try {
      return await XpointSdkPlatform.instance.suitableJurisdictionArea(clientKey, clientBrand);
    } catch (e) {
      debugPrint('Failed to get suitable jurisdiction area: $e');
      return null;
    }
  }

  /// Creates a new session with automatically generated session ID
  ///
  /// Creates a new user session for compliance monitoring using an
  /// automatically generated unique session identifier. This is the
  /// most common way to create sessions.
  ///
  /// [clientKey] Your XPoint client key
  /// [userId] Unique identifier for the user
  /// [clientBrand] Optional client brand identifier for multi-brand clients
  ///
  /// Returns a [Session] object that can be used for compliance operations.
  ///
  /// ## Example
  /// ```dart
  /// final session = await sdk.defaultSession('your-client-key', 'user-123');
  /// print('Created session: ${session.sessionId}');
  /// ```
  Future<Session> defaultSession(String clientKey, String userId, {String? clientBrand, String? sessionId}) async {
    if (clientKey.isEmpty || userId.isEmpty) {
      throw ArgumentError('Client key and user ID cannot be empty');
    }

    try {
        return await XpointSdkPlatform.instance.defaultSession(
            clientKey,
            userId,
            clientBrand: clientBrand,
            sessionId: sessionId
        );
    } catch (e) {
      debugPrint('Failed to create default session: $e');
      rethrow;
    }
  }

  /// Gets the last created default session
  ///
  /// Returns the most recently created session through [defaultSession], or null if no session exists.
  /// This is useful for accessing session state without creating a new session.
  ///
  /// ## Example
  /// ```dart
  /// final sdk = XpointSdk();
  ///
  /// // Create a session first
  /// await sdk.defaultSession('client-key', 'user-123');
  ///
  /// // Later, retrieve the same session
  /// final session = await sdk.getDefaultSession();
  /// if (session != null) {
  ///   print('Found existing session: ${session.sessionId}');
  /// }
  /// ```
  Future<Session?> getDefaultSession() async {
    try {
      return await XpointSdkPlatform.instance.getDefaultSession();
    } catch (e) {
      debugPrint('Failed to get default session: $e');
      return null;
    }
  }

  /// Initializes the log sender for on-demand log submission
  ///
  /// This method sets up the logging infrastructure to send SDK logs
  /// to the server for debugging and monitoring purposes.
  ///
  /// ## Example
  /// ```dart
  /// final sdk = XpointSdk();
  /// await sdk.initializeLogSender();
  /// print('Log sender initialized');
  /// ```
  Future<void> initializeLogSender() async {
    try {
      await XpointSdkPlatform.instance.initializeLogSender();
    } catch (e) {
      debugPrint('Failed to initialize log sender: $e');
      rethrow;
    }
  }

}
