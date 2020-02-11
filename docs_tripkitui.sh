#!/bin/bash
# Bash script to update documentation

(
  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitUI-iOS -sdk iphonesimulator > jazzy-temp.TKUISwift.json

  # This isn't quite working yet
#   sourcekitten doc --objc $(pwd)/TripKitUI/TripKitUIUmbrella.h \
#       -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \
#       -I $(pwd)/TripKitUI/deprecated \
#       -I $(pwd)/TripKitUI/helper/Categories \
#       -I $(pwd)/TripKitUI/views \
#       -I '$(pwd)/TripKitUI/views/map annotations' \
#       -I $(pwd)/TripKitUI/views/results \
#       -F '/Users/adrian/Library/Developer/Xcode/DerivedData/TripGo-etkaspjcznsxksapayelzffdokiv/Build/Products/Debug/TripKit.framework/' \
#       -fmodules \
#       > jazzy-temp.TKUIObjc.json
  
  jazzy --sourcekitten-sourcefile jazzy-temp.TKUISwift.json --config docs/.tripkitui.jazzy.yaml
)
