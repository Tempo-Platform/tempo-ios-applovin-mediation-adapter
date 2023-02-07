Pod::Spec.new do |spec|

  spec.name         = "tempo-applovin-mediation"
  spec.version      = "0.2.2"
  spec.summary      = "Tempo AppLovin iOS Mediation Adapter."

  spec.description  = <<-DESC
  Using this adapter you will be able to integrate Tempo SDK via AppLovin mediation
                   DESC

  spec.homepage     = "https://www.tempoplatform.com"
  spec.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  spec.author       = { "Kieran" => "kieran@tempoplatform.com" }
  
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/Tempo-Platform/tempo-ios-applovin-mediation-adapter.git", :tag => spec.version.to_s }
  
  spec.frameworks   = "Foundation", "UIKit"
  spec.requires_arc = true
  spec.static_framework = true
  spec.swift_version = '5.0'

  spec.dependency "TempoSDK", "~> 0.2.3"
  spec.dependency "AppLovinSDK"
  
  spec.source_files = "TempoAdapter/*.*"
   
  spec.pod_target_xcconfig = { 'VALID_ARCHS' => 'arm64 armv7 x86_64', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'VALID_ARCHS' => 'arm64 armv7 x86_64', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.pod_target_xcconfig = { 'PRODUCT_BUNDLE_IDENTIFIER': 'com.tempoplatform.applovin-adapter-sdk' }
  
end
