# Xpoint SDK Flutter Plugin

A comprehensive Flutter plugin that provides access to Xpoint's geolocation and compliance checking services. This SDK allows you to create sessions perform location-based compliance checks, and manage periodic monitoring of user locations for regulatory compliance.

[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20macOS-blue)](https://flutter.dev)

> **Desktop-focused Flutter plugin** for compliance checking applications on Windows and macOS platforms.

---

## 🚀 Quick Navigation

**Choose your path based on your role:**

### 👨‍💻 **For Developers and Integrators**
*Implementing the Xpoint SDK in your Flutter application*

📖 **[Integration Guide](INTEGRATION_GUIDE.md)** - Complete setup and implementation guide
- Installation and platform setup
- Code examples and best practices
- API usage patterns
- Error handling and troubleshooting

🔗 **API Reference** - Generated API documentation
- Complete class and method reference
- Detailed parameter descriptions
- Code examples from source comments

**API Reference Generation:** Run `dart doc` in the plugin directory to generate API Reference Guide  
**To view:** Open `doc/api/index.html` in your browser after generation  
**Direct access:** Browse the documented source code in [`lib/xpoint_sdk.dart`](lib/xpoint_sdk.dart)

### 🧪 **For Testers and QA Engineers**
*Testing and validating Xpoint SDK functionality*

📱 **[Example App User Guide](example/README.md)** - Comprehensive testing manual
- Step-by-step testing procedures for all available APIs
- Expected results and validation criteria
- Prerequisites and testing sequence
- Troubleshooting common issues

📋 **Platform Support:**
- **Windows** 10+ (native libraries included)
- **macOS** 10.14+ (Catalina) (native libraries included)

---

## ⚡ Quick Start
On a high level, this is the sample source for starting the geolocation services and receiving values periodically:

```dart
import 'package:xpoint_sdk/xpoint_sdk.dart';

final sdk = XpointSdk();

// Validate client key before proceeding
const clientKey = 'your-client-key';
const userId = 'user-id';

final isValidKey = await sdk.isClientKeyValid(clientKey);
if (!isValidKey) {
  print('Invalid client key - cannot start monitoring');
  return;
}

// Create session with validated client key
final session = await sdk.defaultSession(clientKey, userId);

// Start automated monitoring
await session.periodicChecker().start((result) {
  print('Compliance: ${result.status == CheckResponseStatus.allowed ? 'ALLOWED' : 'DENIED'}');
});
```

## 📦 Installation

### Local Development Dependency

When using the Xpoint SDK as a local file dependency in your project:

```yaml
dependencies:
  xpoint_sdk:
    path: ../path/to/xpoint_sdk
```

Replace `../path/to/xpoint_sdk` with the actual relative path to this plugin directory from your Flutter project.

### Git Repository Dependency

When using the Xpoint SDK directly from a git repository:

```yaml
dependencies:
  xpoint_sdk:
    git:
      url: https://github.com/XpointTech/xpoint-sdk-flutter.git
      ref: v5.4.0  # specific version tag
```
For the exact credentials, please reach out to support team for the information

[→ See Integration Guide for complete setup](INTEGRATION_GUIDE.md)

---

## 📞 Support

- 📧 Contact Xpoint support team
- 📖 Check documentation links above for detailed guidance

