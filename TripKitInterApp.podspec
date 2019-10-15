Pod::Spec.new do |s|
  s.name         = "TripKitInterApp"
  s.version      = "4.0-rc1"
  s.summary      = "Add-ons to SkedGo's TripKit"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Closed", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com"
  }
  # s.source       = { git: "." }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "v#{s.version}" }
  s.swift_version = '5.1'
  s.ios.deployment_target = '10.3'
  s.requires_arc = true

  s.dependency 'TripKit', "~> #{s.version}"

  s.source_files = "TripKit/AddOns/InterApp/**/*.{swift}"
end
