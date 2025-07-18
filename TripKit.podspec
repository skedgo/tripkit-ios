Pod::Spec.new do |s|
  s.name         = "TripKit"
  s.version      = "5.0.0"
  s.summary      = "SkedGo's TripKit"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Apache-2.0", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "#{s.version}" }
  s.swift_version = '5.5'
  s.ios.deployment_target = '15'
  s.osx.deployment_target = '11'
  s.requires_arc = true

  s.dependency 'TripKitAPI', "~> #{s.version}"
  
  s.source_files = [
    "Sources/TripKit/**/*.swift"
  ]

  s.resources    = [
    "Sources/TripKit/Resources/*.lproj",
    "Sources/TripKit/Resources/TripKit.xcassets",
    "Sources/TripKit/Resources/TripKitModel.xcdatamodeld",
    "Sources/TripKit/Resources/TripKitModel.xcdatamodeld/*."
  ]
  s.preserve_paths = 'Sources/TripKit/Resources/TripKitModel.xcdatamodeld'
  s.frameworks = 'CoreData'

end
