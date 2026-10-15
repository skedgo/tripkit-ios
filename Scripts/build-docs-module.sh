#!/bin/bash
# Helper script to build DocC documentation for a specific module
# This script generates documentation for a single TripKit module and
# outputs a .doccarchive file to the specified directory.

set -e
set -o pipefail  # Capture errors in pipelines

# Check for verbose flag
VERBOSE=false
for arg in "$@"; do
  if [ "$arg" = "-v" ] || [ "$arg" = "--verbose" ]; then
    VERBOSE=true
    # Remove the flag so it doesn't interfere with positional arguments
    shift
  fi
done

# Function to display usage
show_usage() {
    echo "Usage: $0 [options] <module_name> [output_directory] [hosting_base_path]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Show detailed build output"
    echo ""
    echo "Available modules:"
    echo "  TripKitAPI"
    echo "  TripKit"
    echo "  TripKitUI"
    echo "  TripKitInterApp"
    echo ""
    echo "Example:"
    echo "  $0 TripKit ./docc_archives documentation"
    echo "  $0 --verbose TripKit ./docc_archives documentation"
}

# Check if module name is provided
if [ $# -eq 0 ]; then
    echo "Error: Module name is required"
    show_usage
    exit 1
fi

MODULE_NAME=$1

# Get output directory (default to current directory if not specified)
OUTPUT_DIR="${2:-./docc_archives}"

# Get hosting base path (default to "documentation" if not specified)
# This path is used by DocC for URL path construction and cross-references between modules
HOSTING_BASE_PATH="${3:-documentation}"

# Validate module name
case $MODULE_NAME in
    TripKitAPI|TripKit|TripKitUI|TripKitInterApp)
        ;;
    *)
        echo "Error: Invalid module name '$MODULE_NAME'"
        show_usage
        exit 1
        ;;
esac

# Change to project root directory
cd "$(dirname "$0")/.."

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Building DocC documentation for $MODULE_NAME..."

# Build the DocC archive
# We use DOCC_HOSTING_BASE_PATH to ensure all modules use the same base path for cross-references
echo "📦 Building DocC archive for $MODULE_NAME (Hosting Base Path: $HOSTING_BASE_PATH)..."
# A generic destination avoids depending on a specific simulator being
# available (and CoreSimulator answering) on the build machine.
DOCBUILD_ARGS=(
    docbuild -scheme "$MODULE_NAME"
    -destination 'generic/platform=iOS Simulator'
    -derivedDataPath ./build
    DOCC_HOSTING_BASE_PATH="$HOSTING_BASE_PATH"
    DOCC_CATALOG_INCLUDE_EXTENSION_SYMBOL_GRAPHS=YES
    DOCC_EXTRACT_EXTENSION_SYMBOLS=YES
    DOCC_CATALOG_IDENTIFIER="$MODULE_NAME"
    DOCC_INCLUDE_DOCUMENTATION_CATALOGS=YES
)
BUILD_RESULT=0
if [ "$VERBOSE" = true ]; then
    xcodebuild "${DOCBUILD_ARGS[@]}" || BUILD_RESULT=$?
else
    # Keep the output out of the way, but print its tail if the build fails
    mkdir -p ./build
    BUILD_LOG="./build/docbuild-$MODULE_NAME.log"
    if ! xcodebuild "${DOCBUILD_ARGS[@]}" > "$BUILD_LOG" 2>&1; then
        BUILD_RESULT=1
        echo "xcodebuild failed. Errors in $BUILD_LOG:"
        grep -E "(^xcodebuild: error:| error: )" "$BUILD_LOG" | head -n 20 || true
        echo "Last 80 lines of $BUILD_LOG:"
        tail -n 80 "$BUILD_LOG"
    fi
fi

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Successfully built DocC archive for $MODULE_NAME"

    # Copy DocC archive to output directory
    echo "🔄 Copying DocC archive..."
    ARCHIVE_PATH="build/Build/Products/Debug-iphonesimulator/$MODULE_NAME.doccarchive"

    if [ -d "$ARCHIVE_PATH" ]; then
        # Copy DocC archive to output directory
        if [ "$VERBOSE" = true ]; then
            cp -r "$ARCHIVE_PATH" "$OUTPUT_DIR/"
            COPY_RESULT=$?
        else
            cp -r "$ARCHIVE_PATH" "$OUTPUT_DIR/" > /dev/null 2>&1
            COPY_RESULT=$?
        fi

        if [ $COPY_RESULT -eq 0 ]; then
            echo "✅ Successfully copied $MODULE_NAME.doccarchive to $OUTPUT_DIR"
        else
            echo "❌ Failed to copy DocC archive"
            exit 1
        fi
    else
        echo "❌ DocC archive not found at: $ARCHIVE_PATH"
        exit 1
    fi
else
    echo "❌ Failed to build DocC archive for $MODULE_NAME"
    exit 1
fi

# Return the path to the DocC archive
# This allows the calling script to capture the output path if needed
echo "$OUTPUT_DIR/$MODULE_NAME.doccarchive"
