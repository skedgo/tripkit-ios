#!/bin/bash
# Bash script to update documentation

(
  # echo "Building TripKit docs..."
  ./docs_tripkit.sh

  # echo "Building TripKitUI docs..."
  ./docs_tripkitui.sh

  # echo "Building TripKitInterApp docs..."
  ./docs_tripkitinterapp.sh

  echo "Building the TripGo iOS Dev site..."
  cd docs
  mkdocs build
  if [[ $? -ne 0 ]]; then
    echo "BUILD FAILED. Check the logs and fix the documentation!"
    exit 1
  fi
  cd ../..
  
  echo "Preparing for deployment..."
  rm -rf public
  mkdir public
  cp -r Scripts/docs/site/ public

  echo "Done"
)
