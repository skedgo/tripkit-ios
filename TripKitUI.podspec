Pod::Spec.new do |s|
  s.name         = "TripKitUI"
  s.version      = "1.0-beta"
  s.summary      = "SkedGo's TripKitUI"
  s.homepage     = "http://www.skedgo.com/"
  s.license      = { 
    type: 'Proprietary',
    text: <<-LICENSE
      Copyright 2012-2017, SkedGo Pty Ltd.
    LICENSE
  }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com",
    "Brian Huang" => "brian@skedgo.com"
  }
  s.source       = { path: "." }
  # s.source       = { git: ".", tag: "v#{s.version}" }
  # s.source       = { git: "https://github.com/skedgo/shared-ios.git", :tag => "v#{s.version}" }
  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.frameworks = ['UIKit', 'MapKit']

  s.dependency 'TripKit'
  s.dependency 'SGPulsingAnnotationView'

  s.dependency 'ASPolylineView'
  s.dependency 'Kingfisher'
  s.dependency 'MAKVONotificationCenter'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'

  s.source_files = "TripKitUI/**/*.{h,m,swift}"
  s.resources    = [
    "Resources/TripKitUI.*",
    "TripKitUI/**/*.xib"
  ]

end
