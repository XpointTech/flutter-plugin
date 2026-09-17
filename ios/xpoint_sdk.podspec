#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint xpoint_sdk.podspec` to validate before publishing.
#
# SDK ships via SPM (see Package.swift); this podspec is the CocoaPods fallback.
#
Pod::Spec.new do |s|
  s.name             = 'xpoint_sdk'
  s.version          = '5.5.0'
  s.summary          = 'Xpoint SDK Flutter plugin for iOS'
  s.description      = <<-DESC
Xpoint SDK Flutter plugin for iOS geolocation verification.
                       DESC
  s.homepage         = 'https://xpoint.tech'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Xpoint' => 'support@xpoint.tech' }
  s.source           = { :path => '.' }
  s.source_files = 'xpoint_sdk/Sources/xpoint_sdk/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'XPointSDK', '5.7.0'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
