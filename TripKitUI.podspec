Pod::Spec.new do |s|
  s.name         = "TripKitUI"
  s.version      = "4.0-rc2"
  s.summary      = "SkedGo's TripKitUI"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Closed", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "#{s.version}" }
  s.swift_version = '5.4'
  s.ios.deployment_target = '12.4'
  s.requires_arc = true
  
  s.frameworks = ['UIKit', 'MapKit']

  s.dependency 'TripKit', "~> #{s.version}"

  s.dependency 'TGCardViewController', '>= 1.6.1'
  
  s.dependency 'RxSwift', '~> 6.1.0'
  s.dependency 'RxCocoa', '~> 6.1.0'
  s.dependency 'Kingfisher', '~> 5.8'
  
  s.source_files = [
    "Sources/TripKitUI/**/*.swift"
  ]
  s.resources    = [
    "Sources/TripKitUI/Resources/TripKitUI.xcassets",
    "Sources/TripKitUI/**/*.xib"
  ]

end
