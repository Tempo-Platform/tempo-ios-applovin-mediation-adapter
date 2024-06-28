#
# Run `pod spec lint tempo-applovin-mediation.podspec' to validate the spec after any changes
#
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name          = 'tempo-applovin-mediation'
  spec.version       = '1.6.1-rc.1'
  spec.swift_version = '5.6.1'
  spec.author        = { 'Tempo Engineering' => 'development@tempoplatform.com' }
  spec.license       = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  spec.homepage      = 'https://www.tempoplatform.com'
  spec.readme        = 'https://github.com/Tempo-Platform/tempo-ios-applovin-mediation-adapter/blob/main/README.md'
  spec.source        = { :git => 'https://github.com/Tempo-Platform/tempo-ios-applovin-mediation-adapter.git', :tag => spec.version.to_s }
  spec.summary       = 'Tempo AppLovin iOS Mediation Adapter.'
  spec.description   = <<-DESC
  Using this adapter you will be able to integrate Tempo SDK via AppLovin mediation
                   DESC
  
  spec.platform = :ios, '11.0'

  spec.source_files = 'TempoAdapter/*.*'
  spec.resource_bundles = {
      'TempoAdapter' => ['TempoAdapter/Resources/**/*']
    }

  spec.dependency 'TempoSDK', '1.6.2-rc.0'
  spec.dependency 'AppLovinSDK'
  spec.requires_arc     = true
  spec.frameworks       = 'Foundation', 'UIKit'
  spec.static_framework = true
   
  spec.pod_target_xcconfig  = { 'VALID_ARCHS' => 'arm64 armv7 x86_64', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'VALID_ARCHS' => 'arm64 armv7 x86_64', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.pod_target_xcconfig  = { 'PRODUCT_BUNDLE_IDENTIFIER': 'com.tempoplatform.applovin-adapter-sdk' }
end
