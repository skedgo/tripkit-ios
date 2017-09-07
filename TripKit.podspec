Pod::Spec.new do |s|
  s.name         = "TripKit"
  s.version      = "2.0-beta4"
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
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.11'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.dependency 'ASPolygonKit'
  s.dependency 'Marshal'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'

  s.source_files = "Classes/**/*.{h,m,swift}"

  s.resources    = [
    "Resources/*.lproj",
    "Resources/TripKit.*",
    "TripKitModel.xcdatamodeld",
    "TripKitModel.xcdatamodeld/*."
  ]
  s.preserve_paths = 'TripKitModel.xcdatamodeld'
  s.frameworks = 'CoreData'

end
