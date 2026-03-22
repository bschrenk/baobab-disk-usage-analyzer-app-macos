#!/bin/bash
set -euo pipefail

PREFIX="${1:?Missing install prefix}"
BREW="$(brew --prefix)"
APP="$PWD/Baobab.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
FRAMEWORKS="$CONTENTS/Frameworks"

echo "Creating macOS app bundle at $APP"

mkdir -p "$MACOS" "$RESOURCES" "$FRAMEWORKS"

########################################
# Binary
########################################
cp "$PREFIX/bin/baobab" "$MACOS/baobab-bin"

########################################
# App data
########################################
mkdir -p "$RESOURCES/share"
[ -d "$PREFIX/share/baobab" ]  && cp -R "$PREFIX/share/baobab"  "$RESOURCES/share/baobab"
[ -d "$PREFIX/share/locale" ]  && cp -R "$PREFIX/share/locale"  "$RESOURCES/share/locale"

########################################
# GSettings schemas (merge & compile)
########################################
SCHEMA_DIR="$RESOURCES/share/glib-2.0/schemas"
mkdir -p "$SCHEMA_DIR"
cp "$PREFIX/share/glib-2.0/schemas/"*.xml "$SCHEMA_DIR/" 2>/dev/null || true
cp "$BREW/share/glib-2.0/schemas/"*.xml   "$SCHEMA_DIR/" 2>/dev/null || true
glib-compile-schemas "$SCHEMA_DIR/"

########################################
# Icons
########################################
mkdir -p "$RESOURCES/share/icons"
[ -d "$BREW/share/icons/hicolor" ] && cp -R "$BREW/share/icons/hicolor" "$RESOURCES/share/icons/"
[ -d "$BREW/share/icons/Adwaita" ] && cp -R "$BREW/share/icons/Adwaita" "$RESOURCES/share/icons/"

########################################
# GDK-Pixbuf loaders
########################################
PIXBUF_VER=$(ls "$BREW/lib/gdk-pixbuf-2.0/" 2>/dev/null | head -1)
if [ -n "$PIXBUF_VER" ]; then
  SRC_LOADERS="$BREW/lib/gdk-pixbuf-2.0/$PIXBUF_VER/loaders"
  DEST_LOADERS="$RESOURCES/lib/gdk-pixbuf-2.0/$PIXBUF_VER/loaders"
  mkdir -p "$DEST_LOADERS"
  cp "$SRC_LOADERS/"*.so "$DEST_LOADERS/" 2>/dev/null || true
  # Bundle dylibs inside each loader
  for loader in "$DEST_LOADERS/"*.so; do
    [ -f "$loader" ] && dylibbundler -of -b -x "$loader" -d "$FRAMEWORKS/" \
      -p @executable_path/../Frameworks/ -i /usr/lib -i /System 2>/dev/null || true
  done
  # Regenerate loaders.cache with bundled paths
  CACHE="$RESOURCES/lib/gdk-pixbuf-2.0/$PIXBUF_VER/loaders.cache"
  gdk-pixbuf-query-loaders "$DEST_LOADERS/"*.so > "$CACHE" 2>/dev/null || true
fi

########################################
# Bundle dylibs for the main binary
########################################
dylibbundler -od -b \
  -x "$MACOS/baobab-bin" \
  -d "$FRAMEWORKS/" \
  -p @executable_path/../Frameworks/

########################################
# Launcher script
########################################
cat > "$MACOS/Baobab" << 'LAUNCHER'
#!/bin/bash
BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="$BUNDLE/Resources"

export XDG_DATA_DIRS="$RESOURCES/share:/usr/local/share:/usr/share"
export GSETTINGS_SCHEMA_DIR="$RESOURCES/share/glib-2.0/schemas"

CACHE=$(find "$RESOURCES/lib/gdk-pixbuf-2.0" -name loaders.cache 2>/dev/null | head -1)
[ -n "$CACHE" ] && export GDK_PIXBUF_MODULE_FILE="$CACHE"

exec "$BUNDLE/MacOS/baobab-bin" "$@"
LAUNCHER

chmod +x "$MACOS/Baobab"

########################################
# Info.plist
########################################
cat > "$CONTENTS/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>       <string>Baobab</string>
  <key>CFBundleIconFile</key>         <string>baobab</string>
  <key>CFBundleIdentifier</key>       <string>org.gnome.baobab</string>
  <key>CFBundleName</key>             <string>Baobab</string>
  <key>CFBundleDisplayName</key>      <string>Disk Usage Analyzer</string>
  <key>CFBundlePackageType</key>      <string>APPL</string>
  <key>LSMinimumSystemVersion</key>   <string>11.0</string>
  <key>NSHighResolutionCapable</key>  <true/>
</dict>
</plist>
EOF

########################################
# Icon generation (SVG → ICNS)
########################################
SVG="$PREFIX/share/icons/hicolor/scalable/apps/org.gnome.baobab.svg"
RSVG="$BREW/opt/librsvg/bin/rsvg-convert"

if [[ -f "$SVG" && -f "$RSVG" ]]; then
  echo "Generating icon..."

  ICONSET="$(mktemp -d)/baobab.iconset"
  mkdir -p "$ICONSET"

  for sz in 16 32 64 128 256 512; do
    "$RSVG" -w $sz -h $sz "$SVG" -o "$ICONSET/icon_${sz}x${sz}.png"
    "$RSVG" -w $((sz*2)) -h $((sz*2)) "$SVG" -o "$ICONSET/icon_${sz}x${sz}@2x.png"
  done

  iconutil -c icns "$ICONSET" -o "$RESOURCES/baobab.icns"
else
  echo "Skipping icon generation (missing SVG or librsvg)"
fi

########################################
# Optional: register with LaunchServices
########################################
if command -v /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister &>/dev/null; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" || true
fi

echo "✅ Baobab.app created"
