#!/bin/bash
# Bash script to update documentation

(
  # Checking that we have mkdocs
  mkdocs --version
  if [[ $? -ne 0 ]]; then
    echo "mkdocs is missing. Check the logs and install it."
    exit 1
  fi

  # echo "Building SDK docs..."
  cd ..
  jazzy

  echo "Building the TripGo iOS Dev site..."
  cd Scripts/docs
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
