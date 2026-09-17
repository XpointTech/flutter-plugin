# Xpoint SDK Flutter Plugin Integration Guide

Welcome! This guide will help you integrate the Xpoint SDK Flutter plugin into your application for geolocation compliance checking.

## 📋 Overview

The Xpoint SDK provides **geolocation detection** and **compliance checking** services for Flutter applications. It supports both manual compliance checks and automated periodic monitoring to ensure your application meets regulatory requirements.

### ✨ Key Features
- 🔍 **Real-time geolocation compliance checking**
- 📍 **Automated periodic monitoring** 
- 🛡️ **Regulatory compliance assurance**
- 🚀 **Easy Flutter integration**
- 📱 **Cross-platform support** (Windows, macOS)

## 📚 Table of Contents

- [🚀 Quick Start (< 5 minutes)](#-quick-start--5-minutes)
- [📦 Installation](#-installation)
- [🔧 Platform Setup](#-platform-setup)
- [⚙️ The Xpoint SDK Setup](#-the-xpoint-sdk-setup)
- [💡 Basic Usage](#-basic-usage)
- [🔧 Advanced Features](#-advanced-features)
- [📖 API Reference](#-api-reference)
- [❌ Error Handling](#-error-handling)
- [✅ Best Practices](#-best-practices)
- [🐛 Troubleshooting](#-troubleshooting)
- [💬 Support & Resources](#-support--resources)

## 🚀 Quick Start (< 5 minutes)

Get up and running with Xpoint SDK in just a few steps!

### 🎯 What You'll Build
A Flutter app that validates user location compliance in real-time.

### ⚡ Fastest Integration
```dart
import 'package:xpoint_sdk/xpoint_sdk.dart';

final sdk = XpointSdk();

// 1. Validate your client key
final isValid = await sdk.isClientKeyValid('your-client-key');
if (!isValid) return;

// 2. Create session
final session = await sdk.defaultSession('your-client-key', 'user-id');

// 2a. Optional: Set suitable jurisdiction area
final areas = await sdk.suitableJurisdictionArea('your-client-key');
if (areas?.preferableArea != null) {
  session.jurisdictionArea = Future.value(areas!.preferableArea);
}

// 3a. Option 1: Start continuous monitoring
final periodicChecker = session.periodicChecker();
await periodicChecker.start((result) {
  print('✅ Periodic check - Compliant: ${result.status == CheckResponseStatus.allowed}');
});

// 3b. Option 2: Quick one-time check
final checkerLite = await session.checkerLite();
final result = await checkerLite.check();
print('✅ Compliant: ${result.status == CheckResponseStatus.allowed}');

```

**🎉 That's it!** Your app is now compliance-ready.

> 💡 **Need your client key?** Contact the Xpoint support team for credentials.

---

## 📦 Installation

Choose your integration method based on how you received the SDK:

### 📂 Option 1: Local Development Dependency

When using the Xpoint SDK as a local file dependency:

```yaml
dependencies:
  xpoint_sdk:
    path: ../path/to/xpoint_sdk  # Update this path
```

### 🌐 Option 2: Git Repository Dependency

When using the SDK directly from git:

```yaml
dependencies:
  xpoint_sdk:
    git:
      url: https://github.com/XpointTech/xpoint-sdk-flutter.git
      ref: v5.4.0  # Use latest stable version
```

> 📧 **Need credentials?** Contact Xpoint support team for repository access.

### 🔧 Install Dependencies

Run this command to install the SDK:

```bash
flutter pub get
```

> ✅ **Success!** The SDK is now added to your project.

---

## 🔧 Platform Setup

### 🍎 macOS Requirements

The Xpoint SDK requires specific permissions and setup on macOS to function properly. Follow these steps to avoid HTTP errors and ensure proper location services.

#### Required Permissions

1. **Location Services Permission**
   - Add `NSLocationUsageDescription` key to your app's `Info.plist`
   - This key is required for location permission requests
   - Without this key, the application will ignore all geolocation permission requests

   ```xml
   <key>NSLocationUsageDescription</key>
   <string>This app requires location access for geolocation compliance checking</string>
   ```

2. **Network Access and Location Entitlements**
   - Add required network and location entitlements to your macOS app's entitlements files
   - Network entitlements are essential for HTTP requests and preventing network errors
   - Location entitlement is required for the XPoint SDK to access GPS coordinates for compliance checking

   **For Release.entitlements:**
   ```xml
   <dict>
       <key>com.apple.security.network.client</key>
       <true/>
       <key>com.apple.security.network.server</key>
       <true/>
       <key>com.apple.security.personal-information.location</key>
       <true/>
   </dict>
   ```

   **For Debug.entitlements (if different):**
   ```xml
   <dict>
       <key>com.apple.security.network.client</key>
       <true/>
       <key>com.apple.security.network.server</key>
       <true/>
       <key>com.apple.security.personal-information.location</key>
       <true/>
   </dict>
   ```

#### Avoiding HTTP Errors

Common HTTP errors on macOS can be prevented by:

1. **Ensuring Network Permissions**
   - Verify your app has network access permissions
   - Check that firewall settings allow your application
   - Allow network access when prompted by macOS

2. **Location Services Setup**
   - Enable location services at the system level
   - Grant location permissions to your application

3. **App Permissions**
   - Grant network access when macOS prompts
   - Ensure location permissions are properly configured
   - Check Security & Privacy settings for any blocked permissions

#### Troubleshooting macOS Issues

If you encounter HTTP errors or location issues:

1. **Check System Preferences**
   - Go to System Preferences > Security & Privacy > Location Services
   - Ensure Location Services are enabled system-wide
   - Verify your app is listed and has permission

2. **Verify Network Connectivity**
   - Test with a simple network request
   - Check if other network-dependent apps work
   - Restart network services if needed

3. **Permission Verification**
   - Check if your app is blocked in Security & Privacy settings
   - Verify network access is allowed for your application
   - Reset permissions if needed and restart the app

---

## ⚙️ The Xpoint SDK Setup

### 1️⃣ Import the Plugin

```dart
import 'package:xpoint_sdk/xpoint_sdk.dart';
```

### 2️⃣ Initialize the SDK

```dart
final sdk = XpointSdk();
```

### 3️⃣ Use the SDK functions

```dart
const clientKey = 'your-client-key';
const userId = 'your-user-id';

// ✅ Validate client key before proceeding
final isValidKey = await sdk.isClientKeyValid(clientKey);

if (!isValidKey) {
  print('❌ Invalid client key - check your credentials');
  return;
}

// 🎉 Create session with validated client key
final session = await sdk.defaultSession(clientKey, userId);
print('✅ Session created successfully!');
```

> 💡 **Why validate first?** Invalid keys can cause unexpected application behavior. Always validate before creating sessions.

---

## 💡 Basic Usage

### 🎯 Complete Example

Here's a complete working example:

```dart
import 'package:flutter/material.dart';
import 'package:xpoint_sdk/xpoint_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XPoint SDK Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ComplianceExample(),
    );
  }
}

class ComplianceExample extends StatefulWidget {
  @override
  _ComplianceExampleState createState() => _ComplianceExampleState();
}

class _ComplianceExampleState extends State<ComplianceExample> {
  final sdk = XpointSdk();
  Session? currentSession;
  PeriodicChecker? periodicChecker;
  String status = 'Ready to start';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeSDK();
  }

  Future<void> initializeSDK() async {
    setState(() => isLoading = true);
    
    try {
      const clientKey = 'your-client-key';
      const userId = 'user-123';
      
      // Step 1: Validate client key
      setState(() => status = 'Validating client key...');

      final isValidKey = await sdk.isClientKeyValid(clientKey);
      if (!isValidKey) {
        setState(() {
          status = '❌ Invalid Client Key';
          isLoading = false;
        });
        return;
      }

      // Step 2: Create session
      setState(() => status = 'Creating session...');

      currentSession = await sdk.defaultSession(clientKey, userId);

      // Step 3: Start monitoring
      setState(() => status = 'Starting monitoring...');

      periodicChecker = currentSession!.periodicChecker();
      await periodicChecker!.start((result) {
        setState(() {
          status = '=== PERIODIC CHECK RESULT ===\n'
                  'Status: ${result.status.name}\n'
                  'Allowed: ${result.status == CheckResponseStatus.allowed}\n'
                  'Location: ${result.country}, ${result.state}\n'
                  'Request ID: ${result.requestId}\n'
                  'Next Check: ${result.nextCheckInterval}ms'
                  '${result.errors.isNotEmpty ? '\nErrors: ${result.errors.map((e) => '${e.code}: ${e.description}').join(', ')}' : ''}'
                  '\n================================';
        });
      });

      setState(() {
        status = 'Monitoring started successfully ✅\nWaiting for periodic check results...';
        isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        status = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    periodicChecker?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Xpoint Compliance')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) 
              CircularProgressIndicator(),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (!isLoading)
              ElevatedButton.icon(
                onPressed: initializeSDK,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
```

### Key Features

- Loading states during operations
- Client key validation before session creation  
- Error handling with retry functionality
- Real-time status updates

## 🔧 Other Features

### 1. CheckerLite - Lightweight Compliance Checking

CheckerLite provides fast, one-time compliance checks with minimal overhead. Perfect for applications that need quick compliance decisions without continuous monitoring.

#### Creating and Using CheckerLite

```dart
// Create session
final session = await sdk.defaultSession('client-key', 'user-id');

// Get lightweight checker
final checkerLite = await session.checkerLite();

// Perform quick compliance check
final result = await checkerLite.check();

print('Quick check result: ${result.status == CheckResponseStatus.allowed}');
print('Status: ${result.status.name}');
print('Location: ${result.country}, ${result.state}');
```

#### CheckerLite with Force Refresh

```dart
// Force a fresh check (bypass cache)
final result = await checkerLite.check(force: true);

if (result.status == CheckResponseStatus.allowed) {
  // Proceed with user action
  processUserRequest();
} else {
  // Handle compliance violation
  showComplianceMessage(result.errors.map((e) => '${e.code}: ${e.description}').join(', '));
}
```

#### CheckerLite vs Periodic Monitoring

| Feature | CheckerLite | Periodic Monitoring |
|---------|-------------|-------------------|
| **Use Case** | One-time checks | Continuous monitoring |
| **Performance** | Fast, lightweight | Full-featured |
| **Resource Usage** | Minimal | Higher (background) |
| **Best For** | Quick decisions | Real-time compliance |

#### Complete CheckerLite Example

```dart
import 'package:flutter/material.dart';
import 'package:xpoint_sdk/xpoint_sdk.dart';

void main() {
  runApp(CheckerLiteApp());
}

class CheckerLiteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XPoint CheckerLite Example',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: QuickComplianceCheck(),
    );
  }
}

class QuickComplianceCheck extends StatefulWidget {
  @override
  _QuickComplianceCheckState createState() => _QuickComplianceCheckState();
}

class _QuickComplianceCheckState extends State<QuickComplianceCheck> {
  final sdk = XpointSdk();
  CheckerLite? checkerLite;
  String status = 'Ready to start';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> performQuickCheck() async {
    setState(() => isLoading = true);

    try {
      const clientKey = 'your-client-key';
      const userId = 'user-123';

      // Step 1: Validate client key
      setState(() => status = 'Validating client key...');

      final isValidKey = await sdk.isClientKeyValid(clientKey);
      if (!isValidKey) {
        setState(() {
          status = '❌ Invalid Client Key';
          isLoading = false;
        });
        return;
      }

      // Step 2: Create session and checker
      setState(() => status = 'Creating CheckerLite...');

      final session = await sdk.defaultSession(clientKey, userId);
      checkerLite = await session.checkerLite();

      // Step 3: Perform check
      setState(() => status = 'Performing compliance check...');

      final result = await checkerLite!.check();
      final timestamp = DateTime.now().toIso8601String();

      setState(() {
        status = '=== CHECKER LITE RESULT ===\n'
                'Timestamp: $timestamp\n'
                'Request ID: ${result.requestId}\n'
                'Status: ${result.status.name.toUpperCase()}\n'
                'User ID: ${result.userId}\n'
                'Client ID: ${result.clientId}\n'
                'Country: ${result.country}\n'
                'State: ${result.state}\n'
                'Is Allowed: ${result.status == CheckResponseStatus.allowed}\n'
                'Next Check: ${result.nextCheckInterval}ms'
                '${result.errors.isNotEmpty ? '\nErrors: ${result.errors.map((e) => '${e.code}: ${e.description}').join(', ')}' : ''}'
                '\n===============================';
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        status = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('XPoint CheckerLite')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (!isLoading)
              ElevatedButton.icon(
                onPressed: performQuickCheck,
                icon: Icon(Icons.flash_on),
                label: Text('Perform Quick Check'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Jurisdiction Area Management

The SDK provides powerful jurisdiction area management capabilities, allowing you to set specific geographical compliance rules for sessions.

#### Get Available Areas

```dart
final areas = await sdk.availableJurisdictionAreas('client-key');
for (final area in areas) {
  print('Available: ${area.name} (${area.id})');
}
```

#### Assign Jurisdiction Area to Session

You can assign specific jurisdiction areas to sessions using the modern property API:

```dart
// Create session
final session = await sdk.defaultSession('client-key', 'user-id');

// Option 1: Assign a specific jurisdiction area
final californiaArea = JurisdictionArea(id: 'US-CA', name: 'California, United States');
session.jurisdictionArea = Future.value(californiaArea);

// Option 2: Find and assign from available areas
final areas = await sdk.availableJurisdictionAreas('client-key');
final targetArea = areas.firstWhere((area) => area.id == 'US-NY');
session.jurisdictionArea = Future.value(targetArea);

// Check current jurisdiction area
final currentArea = await session.jurisdictionArea;
if (currentArea != null) {
  print('Session jurisdiction: ${currentArea.name} (${currentArea.id})');
} else {
  print('No specific jurisdiction area - using automatic detection');
}

// Clear jurisdiction area (revert to automatic detection)
session.jurisdictionArea = Future.value(null);
```

### 3. Periodic Monitoring

#### Start with Custom Callback

```dart
final periodicChecker = session.periodicChecker();

await periodicChecker.start((result) {
  // Handle different compliance states
  switch (result.status) {
    case CheckResponseStatus.allowed:
      print('✅ Location is compliant');
      enableAppFeatures();
      break;
    case CheckResponseStatus.denied:
      print('❌ Compliance violation detected');
      showComplianceAlert(result.errorDescription);
      disableRestrictedFeatures();
      break;
    case CheckResponseStatus.waiting:
      print('⏳ Check in progress...');
      showLoadingIndicator();
      break;
    case CheckResponseStatus.idle:
      print('💤 Checker is idle');
      break;
  }

  // Log comprehensive result data
  print('Periodic check result:');
  print('  Request ID: ${result.requestId}');
  print('  Status: ${result.status.name}');
  print('  Allowed: ${result.status == CheckResponseStatus.allowed}');
  print('  Location: ${result.country}, ${result.state}');
  print('  Next check in: ${result.nextCheckInterval}ms');

  if (result.jurisdictionArea != null) {
    print('  Jurisdiction: ${result.jurisdictionArea!.name}');
  }

  if (result.errors.isNotEmpty) {
    print('  Errors: ${result.errors.map((e) => '${e.code}: ${e.description}').join(', ')}');
  }
});
```

#### Using Streams for Real-time UI Updates

```dart
final periodicChecker = session.periodicChecker();

// Start without callback to use stream exclusively
await periodicChecker.start(null);

// Listen to the stream for UI updates
periodicChecker.results.listen((result) {
  // Update UI based on compliance status
  setState(() {
    complianceStatus = result.status == CheckResponseStatus.allowed ? 'Compliant' : 'Non-Compliant';
    locationText = '${result.country}, ${result.state}';
    lastCheckTime = DateTime.now();
    errorMessage = result.errors.isNotEmpty ? result.errors.map((e) => '${e.code}: ${e.description}').join(', ') : null;
  });

  // Handle background actions
  if (result.status != CheckResponseStatus.allowed) {
    logComplianceViolation(result);
    notifyComplianceTeam(result);
  }
});

// Remember to stop when done
await periodicChecker.stop();
```

### 4. Resource Management and Cleanup

Proper resource management is crucial for maintaining app performance and preventing memory leaks.

#### Session Cleanup

```dart
// Delete session when no longer needed
await session.deleteSession();

// This automatically:
// - Stops any active periodic checkers
// - Cleans up associated resources
// - Removes session from the system
```

#### Periodic Checker Cleanup

```dart
// Always stop periodic checkers when done
await periodicChecker.stop();

// Or in dispose methods:
@override
void dispose() {
  periodicChecker?.stop();
  super.dispose();
}
```

#### CheckerLite Reset Pattern

CheckerLite instances are designed for reuse, but you may want to reset for new parameters:

```dart
class CheckerLiteManager {
  CheckerLite? _checkerLite;
  Session? _currentSession;

  // Create or reuse checker
  Future<CheckerLite> getChecker(String clientKey, String userId) async {
    if (_checkerLite == null) {
      _currentSession = await sdk.defaultSession(clientKey, userId);
      _checkerLite = await _currentSession!.checkerLite();
    }
    return _checkerLite!;
  }

  // Reset for new parameters
  void resetChecker() {
    _checkerLite = null;
    _currentSession = null;
  }

  // Complete cleanup
  Future<void> cleanup() async {
    _checkerLite = null;
    if (_currentSession != null) {
      await _currentSession!.deleteSession();
      _currentSession = null;
    }
  }
}
```

#### Best Practices for Resource Management

1. **Always Clean Up**
```dart
// ✅ GOOD: Proper cleanup
try {
  await periodicChecker.stop();
  await session.deleteSession();
} catch (e) {
  debugPrint('Cleanup error: $e');
}

// ❌ BAD: No cleanup
// Leaving resources active can cause memory leaks
```

2. **Handle Cleanup Errors Gracefully**
```dart
Future<void> safeCleanup() async {
  try {
    await periodicChecker?.stop();
  } catch (e) {
    debugPrint('Warning: Failed to stop checker: $e');
  }

  try {
    await session?.deleteSession();
  } catch (e) {
    debugPrint('Warning: Failed to delete session: $e');
  }
}
```

3. **Use Try-Finally for Guaranteed Cleanup**
```dart
Future<void> performChecksWithCleanup() async {
  CheckerLite? checkerLite;
  Session? session;

  try {
    session = await sdk.defaultSession('key', 'user');
    checkerLite = await session.checkerLite();

    // Perform checks...
    final result = await checkerLite.check();

  } finally {
    // Guaranteed cleanup
    if (session != null) {
      await session.deleteSession();
    }
  }
}
```

## 📖 API Reference
For the complete class and method reference, the API reference guide can be generated using dart commands.

**API Reference Generation:** Run `dart doc` in the plugin directory to generate API Reference Guide

**To view:** Open `doc/api/index.html` in your browser after generation

**Direct access:** Browse the documented source code in [`lib/xpoint_sdk.dart`](lib/xpoint_sdk.dart)

## ❌ Error Handling

### Common Error Scenarios

```dart
try {
  final session = await sdk.defaultSession('client-key', 'user-id');
} catch (e) {
  // Handle other errors
  showGeneralError(e.toString());
}
```

## 🐛 Troubleshooting

### 🚨 Common Issues & Solutions

#### 1. "Invalid Client Key" Error
**Problem:** App shows client key validation failed

**Solutions:**
1. ✅ Double-check your client key spelling and format
2. 🌐 Verify you have internet connectivity
3. 📧 Contact Xpoint support to verify your key is active
4. 🔄 Try using a fresh client key from support

#### 2. App Crashes During Session Creation
**Problem:** App crashes when calling `defaultSession()`

**Root Cause:** Usually invalid client key passed to session creation

**Solutions:**
1. ✅ **Always validate client key first** 
2. 🛡️ Wrap session creation in try-catch blocks
3. 🔍 Check logs for specific error messages

```dart
// ✅ GOOD: Validate first
final isValid = await sdk.isClientKeyValid(clientKey);
if (!isValid) {
  print('Invalid key - stopping here');
  return;
}
final session = await sdk.defaultSession(clientKey, userId);

// ❌ BAD: Direct creation without validation
final session = await sdk.defaultSession(clientKey, userId); // Can crash!
```

#### 3. Location Permission Issues
**Problem:** Monitoring starts but no location updates

**Solutions:**
1. 🛡️ Make sure that the application is running as an administrator (or with highest privileges)
2. 📱 Check device location services are enabled
3. ⚙️ Verify app has location permissions

#### 4. Network/Connectivity Issues  
**Problem:** Intermittent failures or timeouts

**Solutions:**
1. 🔄 Implement retry logic with delays
2. 📶 Check internet connectivity before operations
3. ⏰ Use reasonable timeouts for operations

#### 5. Periodic Checker Not Working
**Problem:** Started monitoring but no updates received

**Solutions:**
1. ✅ Verify session was created successfully
2. 📱 Check device location permissions
3. 🌐 Confirm internet connectivity
4. 🔄 Try stopping and restarting the checker

```dart
// Restart monitoring
await periodicChecker.stop();
await periodicChecker.start(callback);
```

### 🔧 Debug Mode

Enable detailed logging to troubleshoot issues:

```dart
import 'package:flutter/foundation.dart';

// Add this for more detailed output
if (kDebugMode) {
  print('🐛 Debug: Client key validation starting...');
  // Your SDK calls here
  print('🐛 Debug: Operation completed');
}
```

### 📞 Getting Help

**Before contacting support, gather this info:**
- 📱 Platform (Windows/macOS)
- 🔢 Flutter version (`flutter --version`)
- 📦 SDK version
- 📋 Complete error messages/stack traces
- 🔑 Whether client key validation passes

---

## 💬 Support & Resources

### 🆘 Need Help?

| Type | Contact | Response Time |
|------|---------|---------------|
| 🐛 **Bug Reports** | Xpoint Support Team | 24-48 hours |
| 💡 **Integration Help** | Technical Support | Same day |
| 📚 **Documentation** | Check example app | Immediate |
| 🔑 **Client Keys** | Account Manager | Same day |

### 📚 Additional Resources

- 📖 **Example App:** Check the plugin repository for working examples
- 🔍 **API Docs:** Review SDK method documentation  
- 💾 **Sample Code:** Copy-paste ready code snippets above

---

🎉 **You're all set!** This guide should help you integrate Xpoint SDK successfully. For the most up-to-date information, always refer to the latest plugin documentation and example code.