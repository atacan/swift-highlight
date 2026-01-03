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
LANGUAGES=("python" "json" "json5")

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
echo "✓ Fixture sync complete!"
echo ""
echo "To sync fixtures after updating highlight.js:"
echo "  cd highlight.js && git fetch && git checkout <version> && cd .."
echo "  ./scripts/sync-fixtures.sh"
