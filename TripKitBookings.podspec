Pod::Spec.new do |s|
  s.name         = "TripKitBookings"
  s.version      = "3.2.0"
  s.summary      = "Booking integration for SkedGo's TripKit"
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
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.dependency 'TripKit', "~> #{s.version}"
  s.dependency 'TripKitUI', "~> #{s.version}"

  s.dependency 'RxSwift', '~> 5.0.0'
  s.dependency 'RxCocoa', '~> 5.0.0'
  s.dependency 'KeychainAccess'
  s.dependency 'OAuthSwift'

  s.dependency 'SwiftyJSON'
  s.dependency 'KVNProgress'

  s.source_files = [
    "TripKitBookings-iOS/*.h",
    "TripKit/AddOns/Bookings/**/*.{h,m,swift}"
  ]
  s.resources = "TripKit/AddOns/Bookings/**/*.{xib}"

end
