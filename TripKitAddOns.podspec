Pod::Spec.new do |s|
  s.name         = "TripKitAddOns"
  s.version      = "2.0-beta3"
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
  # s.source       = { path: "." }
  # s.source       = { git: "." }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "v#{s.version}" }
  s.requires_arc = true
  
  s.prefix_header_file = "prefix.pch"

  s.source_files = "AddOns/TripKitAddOns.h"

  # TODO: Agenda module is not yet available in 2.0 branch
  # s.subspec 'Agenda' do |cs|
  #   cs.ios.deployment_target = '8.0'
  #   cs.osx.deployment_target = '10.11'

  #   cs.dependency 'TripKit', '~> 2.0-beta1'
  #   cs.dependency 'RxSwift'
  #   cs.dependency 'RxCocoa'

  #   cs.source_files = "AddOns/Agenda/**/*.{h,m,swift}"
  # end

  s.subspec 'InterApp' do |cs|
    s.ios.deployment_target = '8.0'

    cs.dependency 'TripKit', '~> 2.0-beta3'
    cs.source_files = "AddOns/InterApp/**/*.{h,m,swift}"
  end

  s.subspec 'Share' do |cs|
    cs.ios.deployment_target = '8.0'
    cs.osx.deployment_target = '10.11'

    cs.dependency 'TripKit', '~> 2.0-beta3'
    cs.dependency 'RxSwift'
    cs.source_files = "AddOns/Share/**/*"
  end

end
