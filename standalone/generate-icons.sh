#!/usr/bin/env bash
set -e

# ===============================
# Generate icons for all platforms
# ===============================

SVG_PATH="$1"
if [[ -z "$SVG_PATH" ]]; then
  echo "Usage: $0 path/to/icon.svg"
  exit 1
fi

# Detect ImageMagick command
if command -v magick >/dev/null 2>&1; then
  IMAGEMAGICK_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
  IMAGEMAGICK_CMD="convert"
else
  echo "Error: ImageMagick is not installed."
  exit 1
fi

# Output filenames
ICO="icon.ico"
ICNS="icon.icns"
PNG="icon.png"

echo "Generating Windows ICO..."
$IMAGEMAGICK_CMD "$SVG_PATH" -define icon:auto-resize=256,128,64,48,32 "$ICO"
echo "  -> $ICO created"

echo "Generating Linux PNG..."
$IMAGEMAGICK_CMD "$SVG_PATH" -resize 256x256 "$PNG"
echo "  -> $PNG created"

# macOS .icns
if command -v iconutil >/dev/null 2>&1; then
  echo "Generating macOS ICNS..."
  ICONSET="icon.iconset"
  mkdir -p "$ICONSET"

  # Sizes needed for icns
  sizes=(16 32 128 256 512 1024)
  for size in "${sizes[@]}"; do
    $IMAGEMAGICK_CMD "$SVG_PATH" -resize "${size}x${size}" "$ICONSET/icon_${size}x${size}.png"
    # For @2x variants
    if [[ $size -le 512 ]]; then
      $IMAGEMAGICK_CMD "$SVG_PATH" -resize "$((size*2))x$((size*2))" "$ICONSET/icon_${size}x${size}@2x.png"
    fi
  done

  iconutil -c icns "$ICONSET" -o "$ICNS"
  rm -r "$ICONSET"
  echo "  -> $ICNS created"
else
  echo "Skipping macOS ICNS: 'iconutil' not found (only works on macOS)"
fi

echo "All done!"
