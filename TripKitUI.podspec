Pod::Spec.new do |s|
  s.name         = "TripKitUI"
  s.version      = "4.7.1"
  s.summary      = "SkedGo's TripKitUI"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Apache-2.0", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "#{s.version}" }
  s.swift_version = '5.5'
  s.ios.deployment_target = '15'
  s.requires_arc = true
  
  s.frameworks = ['UIKit', 'MapKit']

  s.dependency 'TripKit', "~> #{s.version}"

  s.dependency 'TGCardViewController', '>= 2.2.10'
  s.dependency 'GeoMonitor', '~> 0.1.2'
  
  s.dependency 'RxSwift', '~> 6.5'
  s.dependency 'RxCocoa', '~> 6.5'
  s.dependency 'Kingfisher', '~> 7.0'
  
  s.source_files = [
    "Sources/TripKitUI/**/*.swift"
  ]
  s.resources    = [
    "Sources/TripKitUI/Resources/TripKitUI.xcassets",
    "Sources/TripKitUI/**/*.xib"
  ]

end
