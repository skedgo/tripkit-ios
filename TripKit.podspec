Pod::Spec.new do |s|
  s.name         = "TripKit"
  s.version      = "4.0-rc2"
  s.summary      = "SkedGo's TripKit"
  s.homepage     = "https://gitlab.com/skedgo/ios/tripkit-ios"
  s.license      = { type: "Closed", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  # s.source       = { git: "." }
  s.source       = { git: "https://gitlab.com/skedgo/ios/tripkit-ios.git", tag: "v#{s.version}" }
  s.swift_version = '5.2'
  s.ios.deployment_target = '12.4'
  s.osx.deployment_target = '10.14'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.source_files = [
    "TripKit/TripKit.h",
    "TripKit/Classes/**/*.{h,m,swift}"
  ]
  s.osx.exclude_files = [
    "TripKit/Classes/core/Actions/TKActions.{h,m}",
    "TripKit/Classes/UIKit/TKStyleManager+UIKit.{h,m}",
    "TripKit/Classes/UIKit/UIFont+CustomFonts.{h,m}",
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
