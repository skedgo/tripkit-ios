#!/bin/bash
# Bash script to update documentation

(
  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitInterApp-iOS -sdk iphonesimulator > jazzy-temp.TKInterApp.json

  cd docs
  jazzy --sourcekitten-sourcefile ../jazzy-temp.TKInterApp.json --config docs/.tripkitinterapp.jazzy.yaml
)
