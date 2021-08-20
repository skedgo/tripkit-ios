#!/bin/bash
# Bash script to update documentation

(
  cd ..

  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitUI-iOS -sdk iphonesimulator > Scripts/docs/jazzy-temp.TKUISwift.json
  
  cd Scripts/docs
  jazzy --sourcekitten-sourcefile jazzy-temp.TKUISwift.json --config tripkitui.jazzy.yaml
)
