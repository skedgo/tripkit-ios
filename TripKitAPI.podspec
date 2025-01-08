Pod::Spec.new do |s|
  s.name         = "TripKitAPI"
  s.version      = "4.7.1"
  s.summary      = "SkedGo's TripKit"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Apache-2.0", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com"
  }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "#{s.version}" }
  s.swift_version = '5.5'
  s.ios.deployment_target = '15'
  s.osx.deployment_target = '11'
  s.requires_arc = true
  
  s.source_files = [
    "Sources/TripKitAPI/**/*.swift"
  ]

end
