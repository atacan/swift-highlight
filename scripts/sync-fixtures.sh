#!/bin/bash

# Script to sync test fixtures from highlight.js submodule to SwiftHighlight tests
# This keeps fixtures in sync with the highlight.js version without duplicating them in git

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HIGHLIGHTJS_DIR="$PROJECT_ROOT/highlight.js"
FIXTURES_DIR="$PROJECT_ROOT/Tests/SwiftHighlightTests/Fixtures"

# Check if highlight.js submodule exists
if [ ! -d "$HIGHLIGHTJS_DIR/test/markup" ]; then
    echo "Error: highlight.js submodule not found or not initialized"
    echo "Run: git submodule update --init --recursive"
    exit 1
fi

# Create Fixtures directory if it doesn't exist
mkdir -p "$FIXTURES_DIR"

# Languages to sync (add more as needed)
LANGUAGES=("python" "json" "json5" "swift" "ini" "nginx" "yaml" "diff")

echo "Syncing test fixtures from highlight.js..."
echo "Source: $HIGHLIGHTJS_DIR/test/markup"
echo "Target: $FIXTURES_DIR"
echo ""

for lang in "${LANGUAGES[@]}"; do
    SOURCE="$HIGHLIGHTJS_DIR/test/markup/$lang"
    TARGET="$FIXTURES_DIR/$lang"

    if [ -d "$SOURCE" ]; then
        echo "Syncing $lang..."

        # Remove old fixtures for this language
        rm -rf "$TARGET"

        # Copy new fixtures
        cp -r "$SOURCE" "$TARGET"

        # Count files
        FILE_COUNT=$(find "$TARGET" -type f -name "*.txt" | wc -l | tr -d ' ')
        echo "  ✓ Copied $FILE_COUNT files"
    else
        echo "⚠ Warning: $lang not found in highlight.js/test/markup/"
    fi
done

echo ""
echo "Applying SwiftHighlight-specific fixture patches..."

# Fix class_self.expect.txt - remove incorrect trailing newline from highlight.js
# The input file has no trailing newline, so output shouldn't either
# (matches behavior of other fixtures like diacritic_identifiers)
if [ -f "$FIXTURES_DIR/python/class_self.expect.txt" ]; then
    perl -pi -e 'chomp if eof' "$FIXTURES_DIR/python/class_self.expect.txt"
    echo "  ✓ Fixed class_self.expect.txt trailing newline"
fi

# Fix ownership.expect.txt - remove trailing newline to match input
if [ -f "$FIXTURES_DIR/swift/ownership.expect.txt" ]; then
    perl -pi -e 'chomp if eof' "$FIXTURES_DIR/swift/ownership.expect.txt"
    echo "  ✓ Fixed ownership.expect.txt trailing newline"
fi

# Fix tuples.expect.txt - add trailing newline to match input
if [ -f "$FIXTURES_DIR/swift/tuples.expect.txt" ]; then
    echo "" >> "$FIXTURES_DIR/swift/tuples.expect.txt"
    echo "  ✓ Fixed tuples.expect.txt trailing newline"
fi

echo ""
echo "✓ Fixture sync complete!"
echo ""
echo "To sync fixtures after updating highlight.js:"
echo "  cd highlight.js && git fetch && git checkout <version> && cd .."
echo "  ./scripts/sync-fixtures.sh"
