## 5.5.0
* Official version
* Added signing of library used by the plugin
* Fixed session deletion issue
* Added logs on demand functionality
* Integrate the SDK native version 5.5.0

## 5.4.1
* Official version
* Fixed periodic checker issues on OSX
* Fixed network restoration issues on windows

## 5.4.0-beta.5
* Fixed flutter native compilation errors for OSX
* Add non-admin support for windows for data collection
* Fixed JA and custom data not reflecting on session
* Fixed non-responsive behavior of periodic checker and lite checker if JA or custom data is supplied in the session
* Fixed sample app issues on OSX

## 5.4.0-beta.4

* Fix OSX Compilation Issues
* Added new APIs
  * Session.JurisdictionArea
  * SuitableJurisdictionArea
* Fix application unexpected behavior when client key is invalid

## 5.4.0-beta.3

* Compatibility with OSX

## 5.4.0-beta.2

* Windows Platform Release.
  * Added new APIs
    * Get Device ID
    * Validate Client Key
    * Get Host URL
    * Update User Agent
  * Fixed issue if Jurisdiction Area is tried on an invalid client key 

## 5.4.0-beta.1

* Windows Platform Release.
  * Added new APIs
    * Get SDK Version
    * Get Jurisdiction Areas
    * Create Session
    * Start Periodic Check
    * Stop Periodic Check
    * Lite Check  
