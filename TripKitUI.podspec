Pod::Spec.new do |s|
  s.name         = "TripKitUI"
  s.version      = "2.0-beta4"
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
  # s.source       = { path: "." }
  s.source       = { git: "." }
  # s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "v#{s.version}" }
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.frameworks = ['UIKit', 'MapKit']

  s.dependency 'TripKit', '~> 2.0-beta4'
  s.dependency 'SGPulsingAnnotationView'

  s.dependency 'ASPolylineView'
  s.dependency 'Kingfisher'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'

  s.source_files = "TripKitUI/**/*.{h,m,swift}"
  s.resources    = [
    "Resources/TripKitUI.*",
    "TripKitUI/**/*.xib"
  ]

end
