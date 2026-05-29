#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint qibla.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'qibla'
  s.version          = '0.0.1'
  s.summary          = 'Qibla is a package that allows you to display Qibla direction in you app with support for both Android and iOS'
  s.description      = <<-DESC
Qibla is a package that allows you to display Qibla direction in you app with support for both Android and iOS
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'qibla/Sources/qibla/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
