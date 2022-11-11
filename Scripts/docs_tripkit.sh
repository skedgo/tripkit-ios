#!/bin/bash
# Bash script to update documentation

(
  cd ..

  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKit-iOS -sdk iphonesimulator > Scripts/docs/jazzy-temp.TripKit.json
  
  cd Scripts/docs
  jazzy \
      --sourcekitten-sourcefile jazzy-temp.TripKit.json \
      --config tripkit.jazzy.yaml
)
