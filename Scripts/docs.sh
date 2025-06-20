#!/bin/bash
# Bash script to build, merge, and process documentation
#
# This script:
# 1. Builds individual DocC archives for each TripKit module
# 2. Merges them into a single DocC archive with cross-references
# 3. Processes the merged archive for static hosting
# 4. Integrates with MkDocs (if available)

set -e  # Exit immediately on error
set -o pipefail  # Capture errors in pipelines

# Parse command line arguments
VERBOSE=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -v|--verbose) VERBOSE=true; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
done

# Function to execute a command with or without output based on verbose mode
run_command() {
  if [ "$VERBOSE" = true ]; then
    "$@"
  else
    "$@" > /dev/null 2>&1
  fi
}

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"

# Change to project root
cd "$PROJECT_ROOT"

# Constants and Configuration
DOCC_ARCHIVES_DIR="$PROJECT_ROOT/build/docc_archives"        # Directory for individual module archives
MERGED_DOCC_ARCHIVE="$PROJECT_ROOT/build/MergedTripKit.doccarchive"  # Path for the merged DocC archive
MKDOCS_DIR="$SCRIPT_DIR/docs"                                # MkDocs project directory
MKDOCS_SOURCE_DIR="$MKDOCS_DIR/source"                       # MkDocs source directory
MKDOCS_SITE_DIR="$MKDOCS_DIR/site"                           # MkDocs output directory
MKDOCS_DOCS_SUBDIR="sdk"                                     # Where to place DocC within MkDocs site
                                                             # This path is used for cross-references
PUBLIC_DIR="$PROJECT_ROOT/public"                            # Final output directory at project root

# Make sure build directories exist
mkdir -p "$DOCC_ARCHIVES_DIR"
mkdir -p "$(dirname "$MERGED_DOCC_ARCHIVE")"

echo "🚀 Building TripKit documentation... (Verbose: $VERBOSE)"

# Clean previous build artifacts to ensure a fresh build
echo "🧹 Cleaning previous build artifacts..."
rm -rf build/docc_archives                  # Remove previously built module archives
rm -rf "$MERGED_DOCC_ARCHIVE"               # Remove previous merged archive
rm -rf "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"  # Remove previous DocC output in MkDocs source
mkdir -p "$DOCC_ARCHIVES_DIR"               # Create fresh directory for module archives
mkdir -p "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"  # Ensure MkDocs source directory exists

# Step 1: Build individual DocC archives for each module
# Each module is built with the same hosting base path to ensure cross-references work
echo "📚 Building individual module documentation..."

echo "📦 Building TripKitAPI documentation..."
if [ "$VERBOSE" = true ]; then
  "$SCRIPT_DIR/build-docs-module.sh" --verbose TripKitAPI "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
else
  "$SCRIPT_DIR/build-docs-module.sh" TripKitAPI "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
fi

echo "📦 Building TripKit documentation..."
if [ "$VERBOSE" = true ]; then
  "$SCRIPT_DIR/build-docs-module.sh" --verbose TripKit "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
else
  "$SCRIPT_DIR/build-docs-module.sh" TripKit "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
fi

echo "📦 Building TripKitUI documentation..."
if [ "$VERBOSE" = true ]; then
  "$SCRIPT_DIR/build-docs-module.sh" --verbose TripKitUI "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
else
  "$SCRIPT_DIR/build-docs-module.sh" TripKitUI "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
fi

echo "📦 Building TripKitInterApp documentation..."
if [ "$VERBOSE" = true ]; then
  "$SCRIPT_DIR/build-docs-module.sh" --verbose TripKitInterApp "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
else
  "$SCRIPT_DIR/build-docs-module.sh" TripKitInterApp "$DOCC_ARCHIVES_DIR" "$MKDOCS_DOCS_SUBDIR"
fi

# Step 2: Collect all generated DocC archives for merging
echo "🔍 Finding all DocC archives..."
DOCC_ARCHIVES=$(find "$DOCC_ARCHIVES_DIR" -type d -name "*.doccarchive")

if [ -z "$DOCC_ARCHIVES" ]; then
  echo "❌ No .doccarchive files found. Exiting..."
  echo "   Check if the module builds completed successfully."
  exit 1
fi

echo "Found the following .doccarchive files:"
echo "$DOCC_ARCHIVES"

# Step 3: Merge all DocC archives into a single, cross-referenced archive
# This combines documentation from all modules and preserves links between them
echo "🔄 Merging DocC archives..."
# Ensure the output directory doesn't exist before merging (required by docc merge)
rm -rf "$MERGED_DOCC_ARCHIVE"
if [ "$VERBOSE" = true ]; then
  xcrun docc merge \
    --output-path "$MERGED_DOCC_ARCHIVE" \
    $DOCC_ARCHIVES
else
  xcrun docc merge \
    --output-path "$MERGED_DOCC_ARCHIVE" \
    $DOCC_ARCHIVES 2>/dev/null
fi

if [ ! -d "$MERGED_DOCC_ARCHIVE" ]; then
  echo "❌ Failed to merge DocC archives. Exiting..."
  echo "   Try running with the --verbose flag to see error details."
  exit 1
fi

echo "✅ Successfully merged DocC archives into: $MERGED_DOCC_ARCHIVE"

# Step 4: Prepare directory structure for MkDocs integration
echo "📁 Preparing MkDocs directory structure..."
mkdir -p "$MKDOCS_DIR"
mkdir -p "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"

# Verify directories exist
echo "📂 Verifying directories:"
echo "   - MkDocs source directory: $MKDOCS_SOURCE_DIR"
echo "   - DocC subdirectory: $MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"

# Step 5: Process the merged archive for static web hosting
# This transforms the DocC archive into static HTML/CSS/JS that can be served by any web server
# We place it directly into the MkDocs directory structure at the specified subdirectory
echo "🌐 Transforming DocC for static hosting in MkDocs structure..."
HOSTING_BASE_PATH="$MKDOCS_DOCS_SUBDIR"  # The URL path where documentation will be available

# Ensure the output directory is clean and ready
rm -rf "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"
mkdir -p "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"

if [ "$VERBOSE" = true ]; then
  echo "📄 Verbose: Processing archive with command:"
  echo "xcrun docc process-archive transform-for-static-hosting \"$MERGED_DOCC_ARCHIVE\" --output-path \"$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR\" --hosting-base-path \"$HOSTING_BASE_PATH\""

  xcrun docc process-archive transform-for-static-hosting \
    "$MERGED_DOCC_ARCHIVE" \
    --output-path "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" \
    --hosting-base-path "$HOSTING_BASE_PATH"
else
  xcrun docc process-archive transform-for-static-hosting \
    "$MERGED_DOCC_ARCHIVE" \
    --output-path "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" \
    --hosting-base-path "$HOSTING_BASE_PATH" 2>/dev/null
fi

# Double-check that the command worked by checking for index.html
if [ ! -f "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR/index.html" ]; then
  echo "⚠️ Warning: index.html not found in DocC output directory"
  echo "   Trying again with verbose output..."
  xcrun docc process-archive transform-for-static-hosting \
    "$MERGED_DOCC_ARCHIVE" \
    --output-path "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" \
    --hosting-base-path "$HOSTING_BASE_PATH"
fi

# Verify the output directory has content
echo "🔍 Checking DocC output directory contents:"
ls -la "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" || echo "❌ Failed to list directory contents - directory may be empty"

if [ ! -d "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" ]; then
  echo "❌ Failed to process archive for static hosting. Exiting..."
  echo "   Try running with the --verbose flag to see error details."
  echo "   Check if the merged DocC archive at $MERGED_DOCC_ARCHIVE is valid."
  exit 1
fi

echo "✅ Successfully processed DocC documentation for static hosting"

# Step 6: Build the MkDocs site (if available)
# MkDocs provides the overall site structure, with DocC integrated as a subdirectory
# MkDocs will process the source directory, verify links, and generate the site
if [ -f "$MKDOCS_DIR/mkdocs-dev.sh" ]; then
  echo "🏗️ Building the MkDocs site with source from: $MKDOCS_SOURCE_DIR"
  chmod +x "$MKDOCS_DIR/mkdocs-dev.sh"

  cd "$MKDOCS_DIR"
  ./mkdocs-dev.sh build

  if [ $? -ne 0 ]; then
    echo "❌ MkDocs BUILD FAILED. Check the logs and fix the documentation!"
    echo "   Verify that all references to DocC pages use the correct path: /$MKDOCS_DOCS_SUBDIR/..."
    exit 1
  fi

  # Verify that MkDocs processed the DocC content
  if [ -d "$MKDOCS_SITE_DIR/$MKDOCS_DOCS_SUBDIR" ] && [ -f "$MKDOCS_SITE_DIR/$MKDOCS_DOCS_SUBDIR/index.html" ]; then
    echo "✅ MkDocs site built successfully with DocC content included"
  else
    echo "⚠️ MkDocs build completed but DocC content may be missing - check $MKDOCS_SITE_DIR"
  fi
else
  echo "⚠️ mkdocs-dev.sh not found. Skipping MkDocs build."
  # Copy DocC content directly to the site directory
  mkdir -p "$MKDOCS_SITE_DIR"
  echo "📂 Copying DocC content directly to site directory..."
  mkdir -p "$MKDOCS_SITE_DIR/$MKDOCS_DOCS_SUBDIR"
  cp -R "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"/* "$MKDOCS_SITE_DIR/$MKDOCS_DOCS_SUBDIR/"
fi

# Step 7: Prepare final output site for deployment
# Copy the complete site (MkDocs + DocC) to the public directory
echo "📦 Preparing final documentation site for deployment..."
rm -rf "$PUBLIC_DIR"
mkdir -p "$PUBLIC_DIR"

# Ensure the SDK directory exists in the MkDocs source directory
if [ ! -d "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" ] || [ ! -f "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR/index.html" ]; then
  echo "⚠️ Warning: DocC content directory ($MKDOCS_DOCS_SUBDIR) not found in MkDocs source or is empty"
  echo "   Creating directory and copying directly from processed archive..."

  # Create the directory
  mkdir -p "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR"

  # Process the archive directly to the MkDocs source directory as a fallback
  echo "🛠️ Processing DocC archive directly to MkDocs source directory..."
  xcrun docc process-archive transform-for-static-hosting \
    "$MERGED_DOCC_ARCHIVE" \
    --output-path "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" \
    --hosting-base-path "$MKDOCS_DOCS_SUBDIR"

  # If that failed, try a direct copy of the archive content
  if [ ! -f "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR/index.html" ]; then
    echo "🔄 Trying direct copy of archive contents..."
    cp -R "$MERGED_DOCC_ARCHIVE"/* "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR/"
  fi
fi

# Verify the content is there before building MkDocs
echo "📋 Verifying content before building MkDocs..."
if [ -d "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" ] && [ -f "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR/index.html" ]; then
  echo "✅ DocC content found in MkDocs source directory"
  ls -la "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR" | head -n 10
else
  echo "❌ ERROR: DocC content not found in MkDocs source directory"
  ls -la "$MKDOCS_SOURCE_DIR" || echo "Failed to list MkDocs source directory"
fi

# Copy theme settings file to the SDK directory
echo "🔧 Copying theme-settings.json to SDK directory..."
if [ -f "$MKDOCS_SOURCE_DIR/theme-settings.json" ]; then
  cp "$MKDOCS_SOURCE_DIR/theme-settings.json" "$MKDOCS_SOURCE_DIR/$MKDOCS_DOCS_SUBDIR/"
  echo "✅ Successfully copied theme-settings.json"
else
  echo "⚠️ Warning: theme-settings.json not found in $MKDOCS_SOURCE_DIR"
fi

# Copy everything to the public directory at the project root
echo "📂 Copying final site content to project root directory: $PUBLIC_DIR..."
cp -R "$MKDOCS_SITE_DIR"/* "$PUBLIC_DIR/"

echo "✨ Documentation build complete! ✨"
echo "📂 Static site available at: $PUBLIC_DIR"
echo "📘 DocC documentation available at: $PUBLIC_DIR/$MKDOCS_DOCS_SUBDIR/index.html"
echo ""
# Verify the final output
if [ -d "$PUBLIC_DIR/$MKDOCS_DOCS_SUBDIR" ] && [ -f "$PUBLIC_DIR/$MKDOCS_DOCS_SUBDIR/index.html" ]; then
  echo "✅ DocC content successfully copied to public directory"
  ls -la "$PUBLIC_DIR/$MKDOCS_DOCS_SUBDIR" | head -n 10
  echo "   (showing first 10 entries)"
else
  echo "❌ WARNING: DocC content directory not found in public directory or is empty"

  # Last-resort fallback - copy directly to public
  if [ -d "$MERGED_DOCC_ARCHIVE" ]; then
    echo "🔄 Attempting final fallback: direct copy to public directory..."
    mkdir -p "$PUBLIC_DIR/$MKDOCS_DOCS_SUBDIR"
    cp -R "$MERGED_DOCC_ARCHIVE"/* "$PUBLIC_DIR/$MKDOCS_DOCS_SUBDIR/"

    if [ -f "$PUBLIC_DIR/$MKDOCS_DOCS_SUBDIR/index.html" ]; then
      echo "✅ DocC content successfully copied directly to public directory"
    else
      echo "❌ All attempts to copy DocC content failed"
    fi
  fi
fi
echo ""
echo "💡 Run with --verbose or -v flag for detailed build output"
echo "🔍 To test the site locally: cd $PUBLIC_DIR && python3 -m http.server 8000"
