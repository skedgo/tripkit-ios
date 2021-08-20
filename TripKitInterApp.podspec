Pod::Spec.new do |s|
  s.name         = "TripKitInterApp"
  s.version      = "4.0-rc2"
  s.summary      = "Add-ons to SkedGo's TripKit"
  s.homepage     = "https://github.com/skedgo/tripkit-ios"
  s.license      = { type: "Closed", file: "LICENSE" }
  s.authors      = {
    "Adrian Schoenig" => "adrian@skedgo.com"
  }
  s.source       = { git: "https://github.com/skedgo/tripkit-ios.git", tag: "#{s.version}" }
  s.swift_version = '5.2'
  s.ios.deployment_target = '12.4'
  s.requires_arc = true

  s.dependency 'TripKit', "~> #{s.version}"

  s.source_files = "Sources/TripKitInterApp/**/*.{swift}"
end
