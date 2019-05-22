#!/bin/bash
# Bash script to update documentation

(
  jazzy \
  --clean \
  --author SkedGo \
  --author_url https://skedgo.com \
  --module TripKit \
  --output docs/TripKit/

  jazzy \
  --clean \
  --author SkedGo \
  --author_url https://skedgo.com \
  --xcodebuild-arguments -scheme,TripKitUI-iOS \
  --module TripKitUI \
  --output docs/TripKitUI/

  jazzy \
  --clean \
  --author SkedGo \
  --author_url https://skedgo.com \
  --xcodebuild-arguments -scheme,TripKitInterApp-iOS \
  --module TripKitInterApp \
  --output docs/TripKitInterApp/
)
