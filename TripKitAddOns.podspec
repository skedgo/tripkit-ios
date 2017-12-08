Pod::Spec.new do |s|
  s.name         = "TripKitAddOns"
  s.version      = "3.0.1"
  s.summary      = "Add-ons to SkedGo's TripKit"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = 'Apache License, Version 2.0'
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com"
  }
  # s.source       = { path: "." }
  # s.source       = { git: "." }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "v#{s.version}" }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.source_files = "AddOns/TripKitAddOns.h"

  s.subspec 'InterApp' do |cs|
    cs.ios.deployment_target = '9.0'

    cs.dependency 'TripKit', "~> #{s.version}"
    cs.source_files = "AddOns/InterApp/**/*.{h,m,swift}"
  end

end
