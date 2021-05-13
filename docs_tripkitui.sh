#!/bin/bash
# Bash script to update documentation

(
  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitUI-iOS -sdk iphonesimulator > docs/jazzy-temp.TKUISwift.json
  
  cd docs
  jazzy --sourcekitten-sourcefile jazzy-temp.TKUISwift.json --config tripkitui.jazzy.yaml
)
