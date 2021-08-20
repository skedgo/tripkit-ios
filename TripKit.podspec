Pod::Spec.new do |s|
  s.name         = "TripKit"
  s.version      = "4.0-rc2"
  s.summary      = "SkedGo's TripKit"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Closed", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios", tag: "#{s.version}" }
  s.swift_version = '5.2'
  s.ios.deployment_target = '12.4'
  s.osx.deployment_target = '10.14'
  s.requires_arc = true
  
  s.source_files = [
    "Sources/TripKit/**/*.swift",
    "Sources/TripKitObjc/**/*.{h,m}"
  ]
  s.osx.exclude_files = [
    "Sources/TripKitObjc/**/TKActions.{h,m}",
    "Sources/TripKitObjc/**/TKStyleManager+UIKit.{h,m}",
    "Sources/TripKitObjc/**/UIFont+CustomFonts.{h,m}",
  ]

  s.resources    = [
    "Sources/TripKit/Resources/*.lproj",
    "Sources/TripKit/Resources/TripKit.xcassets",
    "Sources/TripKit/Resources/TripKitModel.xcdatamodeld",
    "Sources/TripKit/Resources/TripKitModel.xcdatamodeld/*."
  ]
  s.preserve_paths = 'TripKitModel.xcdatamodeld'
  s.frameworks = 'CoreData'

end
