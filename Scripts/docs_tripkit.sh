#!/bin/bash
# Bash script to update documentation

(
  cd ..

  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKit-iOS -sdk iphonesimulator > Scripts/docs/jazzy-temp.TKSwift.json

  sourcekitten doc --objc $(pwd)/Sources/TripKitObjc/TripKit.h \
      -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \
      -I $(pwd)/Sources/TripKitObjc/Classes \
      -I $(pwd)/Sources/TripKitObjc/include/TripKitObjc \
      -fmodules \
      > Scripts/docs/jazzy-temp.TKObjc.json
  
  cd Scripts/docs
  jazzy \
      --sourcekitten-sourcefile jazzy-temp.TKSwift.json,jazzy-temp.TKObjc.json \
      --config tripkit.jazzy.yaml
)
