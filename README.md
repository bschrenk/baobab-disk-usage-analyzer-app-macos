# Baobab – Disk Usage Analyzer for macOS

An unofficial macOS build and distribution of [Baobab](https://apps.gnome.org/Baobab/), the GNOME Disk Usage Analyzer.

Baobab helps you understand where your disk space is going. It scans folders and storage devices and visualizes the results as an interactive ring chart and tree view, making it easy to find what's taking up space.

## Installation

Download the latest `Baobab.dmg` from the [Releases](../../releases) page, open it, and drag `Baobab.app` to your Applications folder.

**Requirements:** macOS 11.0 (Big Sur) or later.

> **Note:** The app depends on GTK4/GNOME libraries installed via Homebrew. If Baobab fails to launch, install the runtime dependencies:
> ```bash
> brew install gtk4 libadwaita adwaita-icon-theme
> ```

## How It Works

This repository does not contain Baobab's source code. It provides automation to:

1. **Detect** new upstream releases from [download.gnome.org](https://download.gnome.org/sources/baobab/) (checked weekly)
2. **Build** Baobab on macOS using Homebrew-provided GTK4/GNOME dependencies and the Meson build system
3. **Package** the result as a native macOS `.app` bundle and `.dmg` installer
4. **Publish** a GitHub Release automatically when a new version is detected

## Building Locally

```bash
# Install build dependencies
brew install meson ninja pkgconf vala gettext itstool desktop-file-utils
brew install gtk4 libadwaita glib pango cairo graphene adwaita-icon-theme hicolor-icon-theme librsvg

# Download and build (replace VERSION with e.g. 50.0)
VERSION=50.0
curl -LO https://download.gnome.org/sources/baobab/${VERSION%.*}/baobab-${VERSION}.tar.xz
tar -xf baobab-${VERSION}.tar.xz
cd baobab-${VERSION}
meson setup build --prefix="$PWD/../install"
meson compile -C build
meson install -C build
cd ..

# Create the .app bundle and DMG
./scripts/create_app.sh "$PWD/install"
hdiutil create -volname "Baobab" -srcfolder Baobab.app -ov -format UDZO Baobab.dmg
```

## Upstream

- **Project page:** https://apps.gnome.org/Baobab/
- **Source code:** https://gitlab.gnome.org/GNOME/baobab
- **License:** GPL-2.0+
- **Maintainers:** Paolo Borelli, Christopher Davis
