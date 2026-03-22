# Baobab – Disk Usage Analyzer for macOS

An unofficial macOS build of [Baobab](https://apps.gnome.org/Baobab/), the GNOME Disk Usage Analyzer — automated for distribution via **Homebrew Cask** as `baobab-app`.

Baobab helps you understand where your disk space is going. It scans folders and storage devices and visualizes the results as an interactive ring chart and tree view.

## Installing via Homebrew

If `baobab-app` is available in the official [homebrew-cask](https://github.com/Homebrew/homebrew-cask) tap:

```bash
brew install --cask baobab-app
```

If the official cask is not yet available, you can install directly from this repository's cask:

```bash
brew install --cask bschrenk/homebrew-cask/baobab-app
```

> The `baobab-app` cask points to the versioned `Baobab.dmg` published by this repository's CI pipeline.

## Manual Installation

Download the latest `Baobab.dmg` from the [Releases](../../releases) page, open it, and drag `Baobab.app` to your Applications folder.

**Requirements:** macOS 11.0 (Big Sur) or later.

## Purpose of This Repository

This repo is a **CI/CD packaging pipeline** whose primary output is a versioned `Baobab.dmg` and `Baobab.app` suitable for consumption by the [Homebrew Cask](https://github.com/Homebrew/homebrew-cask) formula for `baobab-app`.

It does not contain Baobab's source code. Each release:

1. **Detects** new upstream releases from [download.gnome.org](https://download.gnome.org/sources/baobab/) (checked daily)
2. **Builds** Baobab on macOS using Homebrew-provided GTK4/GNOME dependencies and the Meson build system
3. **Packages** the result as a macOS `.app` bundle and `.dmg` installer
4. **Publishes** a GitHub Release with the DMG attached — the URL and SHA256 are what the `baobab-app` cask formula references

See [Homebrew's contributing guide](https://github.com/Homebrew/homebrew-core/blob/HEAD/CONTRIBUTING.md) for how cask formulas are structured and updated.

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
./scripts/create_app.sh "$PWD/install" "$VERSION"
hdiutil create -volname "Baobab" -srcfolder Baobab.app -ov -format UDZO Baobab.dmg
```

## Upstream

- **Project page:** https://apps.gnome.org/Baobab/
- **Source code:** https://gitlab.gnome.org/GNOME/baobab
- **License:** GPL-2.0+
- **Maintainers:** Paolo Borelli, Christopher Davis
