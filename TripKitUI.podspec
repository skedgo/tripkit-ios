Pod::Spec.new do |s|
  s.name         = "TripKitUI"
  s.version      = "3.1.1"
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
  s.swift_version = '4.0'
  s.ios.deployment_target = '9.0'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.frameworks = ['UIKit', 'MapKit']

  s.dependency 'TripKit', "~> #{s.version}"

  s.dependency 'ASPolylineView'
  s.dependency 'Kingfisher'
  s.dependency 'RxSwift', '~> 4.0.0'
  s.dependency 'RxCocoa', '~> 4.0.0'
  s.dependency 'RxDataSources', '~> 3.0.0'

  s.source_files = [
    "TripKitUI-iOS/*.h",
    "TripKitUI/**/*.{h,m,swift}"
  ]
  s.resources    = [
    "Resources/TripKitUI.*",
    "TripKitUI/**/*.xib"
  ]

end
