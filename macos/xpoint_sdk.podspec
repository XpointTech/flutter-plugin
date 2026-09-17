#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint xpoint_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'xpoint_sdk'
  s.version          = '5.5.0'
  s.summary          = 'XPoint SDK Flutter plugin for macOS'
  s.description      = <<-DESC
XPoint SDK Flutter plugin for macOS geolocation verification.
                       DESC
  s.homepage         = 'https://xpoint.tech'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'XPoint' => 'support@xpoint.tech' }

  s.source           = { :path => '.' }
  s.source_files = 'xpoint_sdk/Sources/xpoint_sdk/**/*.swift'

  s.dependency 'XPointSDK', '5.7.0'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'xpoint_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
