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
#  s.source       = { git: "https://github.com/skedgo/shared-ios.git", :tag => "v#{s.version}" }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.subspec 'Core' do |cs|
    cs.dependency 'SkedGoKit/Core'
    cs.source_files = "Classes/**/*.{h,m,swift}"
    cs.resources    = [
      "Resources/*",
      "TripKitModel.xcdatamodeld",
      "TripKitModel.xcdatamodeld/*."
    ]
    cs.preserve_paths = 'TripKitModel.xcdatamodeld'
    cs.frameworks = 'CoreData'
  end

  s.subspec 'Agenda' do |cs|
    cs.dependency 'TripKit/Core'
    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'
    cs.dependency 'SwiftyJSON'

    cs.source_files = "AddOns/Agenda/**/*.{h,m,swift}"
  end

  s.subspec 'Bookings' do |cs|
    cs.dependency 'TripKit/Core'
    cs.dependency 'SGBookingKit'
    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'

    cs.source_files = "AddOns/Bookings/**/*.{h,m,swift}"
  end

  s.subspec 'InterApp' do |cs|
    cs.dependency 'TripKit/Core'
    cs.source_files = "AddOns/InterApp/**/*.{h,m,swift}"
  end

  s.subspec 'Share' do |cs|
    cs.dependency 'TripKit/Core'
    cs.dependency 'SGSearch'

    cs.source_files = "AddOns/Share/**/*"
  end

end
