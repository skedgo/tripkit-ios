#!/bin/bash
# Bash script to update documentation

(
  cd ..

  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitInterApp-iOS -sdk iphonesimulator > Scripts/docs/jazzy-temp.TKInterApp.json

  cd Scripts/docs
  jazzy --sourcekitten-sourcefile jazzy-temp.TKInterApp.json --config tripkitinterapp.jazzy.yaml
)
