Pod::Spec.new do |s|
  s.name         = "TripKitBookings"
  s.version      = "1.0-beta"
  s.summary      = "Booking integration for SkedGo's TripKit"
  s.homepage     = "http://www.skedgo.com/"
  s.license      = { 
    type: 'Proprietary',
    text: <<-LICENSE
      Copyright 2012-2016, SkedGo Pty Ltd.
    LICENSE
  }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  s.source       = { path: "." }
  # s.source       = { git: ".", tag: "v#{s.version}" }
#  s.source       = { git: "https://github.com/skedgo/shared-ios.git", :tag => "v#{s.version}" }
  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.dependency 'TripKit'
  s.dependency 'TripKitUI'

  s.dependency 'AFNetworking'  
  s.dependency 'KVNProgress'

  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'SwiftyJSON'
  s.dependency 'KeychainAccess'
  s.dependency 'OAuthSwift'

  s.source_files = "AddOns/Bookings/**/*.{h,m,swift}"
  s.resources = "AddOns/Bookings/**/*.{xib}"

end
