#!/bin/bash
# Bash script to update documentation

(
  cd ..

  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitUI-iOS -sdk iphonesimulator > Scripts/docs/jazzy-temp.TripKitUI.json
  
  cd Scripts/docs
  jazzy --sourcekitten-sourcefile jazzy-temp.TripKitUI.json --config tripkitui.jazzy.yaml
)
