#!/bin/bash
# Bash script to update documentation

(
  sourcekitten doc -- -project TripKit.xcodeproj -scheme TripKitInterApp-iOS > jazzy-temp.TKUIInterApp.json

  jazzy --sourcekitten-sourcefile jazzy-temp.TKUIInterApp.json --config docs/.tripkitinterapp.jazzy.yaml
)
