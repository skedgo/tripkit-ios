Pod::Spec.new do |s|
  s.name         = "TripKitUI"
  s.version      = "4.0.0-beta"
  s.summary      = "SkedGo's TripKitUI"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = 'Apache License, Version 2.0'
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  # s.source       = { path: "." }
  # s.source       = { git: "." }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "v#{s.version}" }
  s.swift_version = '5.0'
  s.ios.deployment_target = '10.3'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.frameworks = ['UIKit', 'MapKit']

  s.dependency 'TripKit', "~> #{s.version}"

  s.dependency 'Kingfisher', '~> 5.4'
  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'RxCocoa', '~> 5.0'
  s.dependency 'RxDataSources', '~> 4.0'

  s.dependency 'TGCardViewController'

  s.source_files = [
    "TripKitUI-iOS/*.h",
    "TripKitUI/**/*.{h,m,swift}"
  ]
  s.resources    = [
    "TripKitUI/TripKitUI.xcassets",
    "TripKitUI/**/*.xib"
  ]

end
