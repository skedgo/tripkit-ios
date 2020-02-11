#!/bin/bash
# Bash script to update documentation

(
  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitInterApp-iOS > jazzy-temp.TKInterApp.json

  jazzy --sourcekitten-sourcefile jazzy-temp.TKInterApp.json --config docs/.tripkitinterapp.jazzy.yaml
)
