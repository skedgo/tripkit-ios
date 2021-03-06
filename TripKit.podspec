Pod::Spec.new do |s|
  s.name         = "TripKit"
  s.version      = "3.2"
  s.summary      = "SkedGo's TripKit"
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
  s.osx.deployment_target = '10.12'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.dependency 'ASPolygonKit'
  s.dependency 'RxSwift', '~> 5.0.0'
  s.dependency 'RxCocoa', '~> 5.0.0'

  s.source_files = [
    "TripKit/TripKit.h",
    "TripKit/Classes/**/*.{h,m,swift}",
    "TripKit/AddOns/Share/**/*"
  ]

  s.resources    = [
    "TripKit/Resources/*.lproj",
    "TripKit/Resources/TripKit.*",
    "TripKitModel.xcdatamodeld",
    "TripKitModel.xcdatamodeld/*."
  ]
  s.preserve_paths = 'TripKitModel.xcdatamodeld'
  s.frameworks = 'CoreData'

end
