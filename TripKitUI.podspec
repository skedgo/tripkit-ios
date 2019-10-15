Pod::Spec.new do |s|
  s.name         = "TripKitUI"
  s.version      = "4.0-rc1"
  s.summary      = "SkedGo's TripKitUI"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Closed", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  # s.source       = { git: "." }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "v#{s.version}" }
  s.swift_version = '5.1'
  s.ios.deployment_target = '10.3'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.frameworks = ['UIKit', 'MapKit']

  s.dependency 'TripKit', "~> #{s.version}"

  s.dependency 'TGCardViewController'

  s.dependency 'Kingfisher', '~> 5.8'
  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'RxCocoa', '~> 5.0'
  s.dependency 'RxDataSources', '~> 4.0'

  
  s.source_files = [
    "TripKitUI-iOS/*.h",
    "TripKitUI/**/*.{h,m,swift}"
  ]
  s.resources    = [
    "TripKitUI/TripKitUI.xcassets",
    "TripKitUI/**/*.xib"
  ]

end
