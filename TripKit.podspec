Pod::Spec.new do |s|
  s.name         = "TripKit"
  s.version      = "1.0-beta"
  s.summary      = "SkedGo's TripKit"
  s.homepage     = "http://www.skedgo.com/"
  s.license      = { 
    type: 'Proprietary',
    text: <<-LICENSE
      Copyright 2012-2016, SkedGo Pty Ltd.
    LICENSE
  }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com"
  }
  s.source       = { path: "." }
  # s.source       = { git: ".", tag: "v#{s.version}" }
  # s.source       = { git: "https://github.com/skedgo/shared-ios.git", :tag => "v#{s.version}" }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.dependency 'SGCoreKit/Core'
  s.dependency 'SGCoreKit/Rx'
  s.dependency 'Marshal'
  s.source_files = "Classes/**/*.{h,m,swift}"
  s.resources    = [
    "Resources/*.lproj",
    "TripKitModel.xcdatamodeld",
    "TripKitModel.xcdatamodeld/*."
  ]
  s.preserve_paths = 'TripKitModel.xcdatamodeld'
  s.frameworks = 'CoreData'

end
