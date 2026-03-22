#!/bin/bash
set -euo pipefail

PREFIX="${1:?Missing install prefix}"
APP="$PWD/Baobab.app"

echo "Creating macOS app bundle at $APP"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

########################################
# Launcher script
########################################
cat > "$APP/Contents/MacOS/Baobab" << EOF
#!/bin/bash
PREFIX="$PREFIX"

export XDG_DATA_DIRS="\$PREFIX/share:/usr/local/share:/usr/share"
export GSETTINGS_SCHEMA_DIR="\$PREFIX/share/glib-2.0/schemas"

LOADERS=\$(find "\$PREFIX/lib/gdk-pixbuf-2.0" -name loaders.cache 2>/dev/null | head -1)
[ -n "\$LOADERS" ] && export GDK_PIXBUF_MODULE_FILE="\$LOADERS"

exec "\$PREFIX/bin/baobab" "\$@"
EOF

chmod +x "$APP/Contents/MacOS/Baobab"

########################################
# Info.plist
########################################
cat > "$APP/Contents/Info.plist" << 'EOF'
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
RSVG="$(brew --prefix)/opt/librsvg/bin/rsvg-convert"

if [[ -f "$SVG" && -f "$RSVG" ]]; then
  echo "Generating icon..."

  ICONSET="$(mktemp -d)/baobab.iconset"
  mkdir -p "$ICONSET"

  for sz in 16 32 64 128 256 512; do
    "$RSVG" -w $sz -h $sz "$SVG" -o "$ICONSET/icon_${sz}x${sz}.png"
    "$RSVG" -w $((sz*2)) -h $((sz*2)) "$SVG" -o "$ICONSET/icon_${sz}x${sz}@2x.png"
  done

  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/baobab.icns"
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