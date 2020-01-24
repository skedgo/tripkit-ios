#!/bin/bash
# Bash script to update documentation

(
  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKit-iOS > jazzy-temp.TKSwift.json

  sourcekitten doc --objc $(pwd)/TripKit/TripKit.h \
      -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \
      -I $(pwd)/TripKit/Classes \
      -I $(pwd)/TripKit/Classes/core \
      -I $(pwd)/TripKit/Classes/core/Actions \
      -I $(pwd)/TripKit/Classes/core/CustomEvent \
      -I $(pwd)/TripKit/Classes/core/Permissions \
      -I $(pwd)/TripKit/Classes/core/RootKit \
      -I $(pwd)/TripKit/Classes/core/RootKit/Categories \
      -I $(pwd)/TripKit/Classes/core/RootKit/Model \
      -I $(pwd)/TripKit/Classes/core/Search \
      -I $(pwd)/TripKit/Classes/core/ServerKit \
      -I $(pwd)/TripKit/Classes/core/TransportKit \
      -I $(pwd)/TripKit/Classes/deprecated \
      -I $(pwd)/TripKit/Classes/helpers \
      -I $(pwd)/TripKit/Classes/helpers/classification \
      -I $(pwd)/TripKit/Classes/model \
      -I $(pwd)/TripKit/Classes/model/CoreData \
      -I $(pwd)/TripKit/Classes/server \
      -I $(pwd)/TripKit/Classes/server/parsing \
      -fmodules \
      > jazzy-temp.TKObjc.json
  
  jazzy \
      --sourcekitten-sourcefile jazzy-temp.TKSwift.json,jazzy-temp.TKObjc.json \
      --config docs/.tripkit.jazzy.yaml
)