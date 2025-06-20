#!/bin/bash
# Script to clean up Jazzy-related files after migrating to DocC

set -e

echo "🧹 TripKit iOS - Jazzy Cleanup Script"
echo "====================================="
echo ""
echo "This script will remove Jazzy-related files that are no longer needed"
echo "after migrating to Swift DocC documentation."
echo ""

# Function to remove file if it exists
remove_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "🗑️  Removing: $file"
        rm "$file"
    else
        echo "ℹ️  File not found (already removed?): $file"
    fi
}

# Function to remove directory if it exists
remove_directory() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "🗑️  Removing directory: $dir"
        rm -rf "$dir"
    else
        echo "ℹ️  Directory not found (already removed?): $dir"
    fi
}

# Change to project root
cd "$(dirname "$0")/.."

echo "Files to be removed:"
echo "- .jazzy.yaml (Jazzy configuration)"
echo "- Gemfile (Ruby dependencies)"
echo "- Gemfile.lock (Ruby lock file)"
echo "- Scripts/docs/jazzy-temp.*.json (Jazzy temporary files)"
echo ""

# Ask for confirmation
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled."
    exit 1
fi

echo ""
echo "🚀 Starting cleanup..."
echo ""

# Remove main Jazzy configuration
remove_file ".jazzy.yaml"

# Remove Ruby dependencies
remove_file "Gemfile"
remove_file "Gemfile.lock"

# Remove temporary Jazzy files
echo "🔍 Looking for Jazzy temporary files..."
find Scripts/docs -name "jazzy-temp.*.json" -type f | while read -r file; do
    echo "🗑️  Removing: $file"
    rm "$file"
done

# Check for any remaining Jazzy-related files
echo ""
echo "🔍 Checking for any remaining Jazzy-related files..."

# Look for any files containing "jazzy" in their name
jazzy_files=$(find . -name "*jazzy*" -type f 2>/dev/null || true)
if [ -n "$jazzy_files" ]; then
    echo "⚠️  Found additional files that might be Jazzy-related:"
    echo "$jazzy_files"
    echo ""
    read -p "Do you want to review these files manually? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📝 Please review these files manually and remove if appropriate."
    fi
else
    echo "✅ No additional Jazzy-related files found."
fi

# Check if .bundle directory exists (bundler gem cache)
if [ -d ".bundle" ]; then
    echo ""
    echo "📦 Found .bundle directory (Ruby gem cache)"
    read -p "Do you want to remove the .bundle directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        remove_directory ".bundle"
    fi
fi

# Check if vendor directory exists (bundler gems)
if [ -d "vendor" ]; then
    echo ""
    echo "📦 Found vendor directory (bundler gems)"
    read -p "Do you want to remove the vendor directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        remove_directory "vendor"
    fi
fi

echo ""
echo "✅ Jazzy cleanup completed!"
echo ""
echo "📝 Summary of changes:"
echo "- Removed Jazzy configuration files"
echo "- Removed Ruby dependency files"
echo "- Removed temporary Jazzy files"
echo ""
echo "🎉 Your project is now ready for DocC-only documentation!"
echo ""
echo "Next steps:"
echo "1. Test DocC documentation generation: ./Scripts/docs.sh"
echo "2. Update your CI/CD pipeline to remove Jazzy dependencies"
echo "3. Update README.md to reflect the new documentation system"
echo ""
