Pod::Spec.new do |s|
  s.name         = "TripKitAddOns"
  s.version      = "1.0-beta"
  s.summary      = "Add ons to SkedGo's TripKit"
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
#  s.source       = { git: "https://github.com/skedgo/shared-ios.git", :tag => "v#{s.version}" }
  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.subspec 'Agenda' do |cs|
    cs.dependency 'TripKit'
    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'

    cs.source_files = "AddOns/Agenda/**/*.{h,m,swift}"
  end

  s.subspec 'Bookings' do |cs|
    cs.dependency 'TripKit'
    cs.dependency 'AFNetworking'  
    cs.dependency 'KVNProgress'

    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'
    cs.dependency 'SwiftyJSON'
    cs.dependency 'KeychainAccess'
    cs.dependency 'OAuthSwift'

    cs.source_files = "AddOns/Bookings/**/*.{h,m,swift}"
    cs.resources = "AddOns/Bookings/**/*.{xib}"

  end

  s.subspec 'InterApp' do |cs|
    cs.dependency 'TripKit'
    cs.source_files = "AddOns/InterApp/**/*.{h,m,swift}"
  end

  s.subspec 'Share' do |cs|
    cs.dependency 'TripKit'
    cs.dependency 'AFNetworking'
    cs.dependency 'RxSwift'
    cs.source_files = "AddOns/Share/**/*"
  end

end
