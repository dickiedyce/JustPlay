#!/bin/zsh
#
# generate-icons.sh — Render PNG icons from SVG sources using rsvg-convert.
#
# Usage:
#   ./scripts/generate-icons.sh
#
# Prerequisites:
#   brew install librsvg
#
# Re-run this script any time you update the source SVGs.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="$REPO_ROOT/JustPlay/Resources"
ASSETS="$RESOURCES/Assets.xcassets"

# ---------------------------------------------------------------------------
# Verify rsvg-convert is available
# ---------------------------------------------------------------------------
if ! command -v rsvg-convert &>/dev/null; then
    echo "Error: rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

# ---------------------------------------------------------------------------
# AppIcon — macOS requires 10 sizes (5 point sizes x 2 scales)
# ---------------------------------------------------------------------------
APP_SVG="$RESOURCES/AppIcon.svg"
APP_DEST="$ASSETS/AppIcon.appiconset"

mkdir -p "$APP_DEST"

if [[ ! -f "$APP_SVG" ]]; then
    echo "Error: $APP_SVG not found"
    exit 1
fi

# (point_size, scale, pixel_size, filename)
app_icons=(
    "16   1  16   icon_16x16.png"
    "16   2  32   icon_16x16@2x.png"
    "32   1  32   icon_32x32.png"
    "32   2  64   icon_32x32@2x.png"
    "128  1  128  icon_128x128.png"
    "128  2  256  icon_128x128@2x.png"
    "256  1  256  icon_256x256.png"
    "256  2  512  icon_256x256@2x.png"
    "512  1  512  icon_512x512.png"
    "512  2  1024 icon_512x512@2x.png"
)

echo "Generating AppIcon PNGs..."
for entry in "${app_icons[@]}"; do
    read -r _pt _scale px filename <<< "$entry"
    rsvg-convert -w "$px" -h "$px" "$APP_SVG" > "$APP_DEST/$filename"
    echo "  $filename (${px}x${px})"
done

# Write Contents.json for AppIcon
cat > "$APP_DEST/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
echo "  Contents.json updated"

# ---------------------------------------------------------------------------
# DocumentIcon — 1x and 2x variants for use in Finder / Dock
# ---------------------------------------------------------------------------
DOC_SVG="$RESOURCES/DocumentIcon.svg"
DOC_DEST="$ASSETS/DocumentIcon.imageset"

if [[ -f "$DOC_SVG" ]]; then
    mkdir -p "$DOC_DEST"

    echo "Generating DocumentIcon PNGs..."
    rsvg-convert -w 256 -h 256 "$DOC_SVG" > "$DOC_DEST/DocumentIcon.png"
    echo "  DocumentIcon.png (256x256)"
    rsvg-convert -w 512 -h 512 "$DOC_SVG" > "$DOC_DEST/DocumentIcon@2x.png"
    echo "  DocumentIcon@2x.png (512x512)"

    cat > "$DOC_DEST/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "DocumentIcon.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "DocumentIcon@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    echo "  Contents.json updated"
else
    echo "Skipping DocumentIcon (no SVG found)"
fi

echo "Done."
