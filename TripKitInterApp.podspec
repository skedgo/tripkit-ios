Pod::Spec.new do |s|
  s.name         = "TripKitInterApp"
  s.version      = "3.2"
  s.summary      = "Add-ons to SkedGo's TripKit"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = 'Apache License, Version 2.0'
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com"
  }
  # s.source       = { path: "." }
  # s.source       = { git: "." }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "v#{s.version}" }
  s.swift_version = '5.0'
  s.ios.deployment_target = '10.3'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.dependency 'TripKit', "~> #{s.version}"
  
  s.source_files = [
    "TripKitInterApp-iOS/*.h",
    "TripKit/AddOns/InterApp/**/*.{h,m,swift}",
  ]
end
