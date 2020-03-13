Pod::Spec.new do |s|
  s.name         = "TripKit"
  s.version      = "4.0-rc1"
  s.summary      = "SkedGo's TripKit"
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
  s.osx.deployment_target = '10.13'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.dependency 'ASPolygonKit'
  s.dependency 'RxSwift', '~> 5.1'
  s.dependency 'RxCocoa', '~> 5.1'

  s.source_files = [
    "TripKit/TripKit.h",
    "TripKit/Classes/**/*.{h,m,swift}"
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
