# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

**Baobab** (Disk Usage Analyzer) is a GNOME application that helps users manage storage by scanning folders and devices and visualizing where disk space is used. It provides both a tree view and a graphical ring chart for exploring folder sizes. Upstream project: https://apps.gnome.org/Baobab/ — maintained by the GNOME project (Paolo Borelli, Christopher Davis), licensed GPL-2.0+.

This repo is a **CI/CD packaging project** — it does not contain Baobab source code. It automates:
1. Detecting new upstream GNOME Baobab releases (weekly cron job, Mondays)
2. Building Baobab on macOS from the upstream source tarball
3. Wrapping the result in a macOS `.app` bundle
4. Packaging as a DMG and publishing a GitHub release

## Key Files

- `.github/workflows/build.yml` — the entire pipeline (version check → tag → build → release)
- `scripts/create_app.sh` — creates the macOS `.app` bundle from a compiled Meson install prefix

## Local Build

To build and install locally (outside CI):

```bash
# Install build dependencies
brew install meson ninja pkgconf vala gettext itstool desktop-file-utils
brew install gtk4 libadwaita glib pango cairo graphene adwaita-icon-theme hicolor-icon-theme librsvg

# Download and build upstream source (replace VERSION with actual version, e.g. 47.0)
VERSION=47.0
curl -LO https://download.gnome.org/sources/baobab/${VERSION%.*}/baobab-${VERSION}.tar.xz
tar -xf baobab-${VERSION}.tar.xz
cd baobab-${VERSION}
meson setup build --prefix="$PWD/../install"
meson compile -C build
meson install -C build
cd ..

# Create the app bundle
./scripts/create_app.sh "$PWD/install"

# Create DMG
hdiutil create -volname "Baobab" -srcfolder Baobab.app -ov -format UDZO Baobab.dmg
```

## Architecture

### CI Pipeline (`build.yml`)

Three jobs, each depending on the previous:

1. **check** (ubuntu): Scrapes `download.gnome.org/sources/baobab/` for the latest version number, checks if a git tag already exists for it. Outputs `version` and `should_build`.

2. **tag** (ubuntu): If a new version is detected, creates and pushes a `v{VERSION}` git tag. This tag push re-triggers the workflow.

3. **build** (macos-latest): Downloads the upstream source tarball, builds it with Meson, then calls `scripts/create_app.sh` to produce `Baobab.app`. Creates a DMG and uploads as an artifact.

4. **release** (ubuntu): Only runs on tag pushes. Creates a GitHub release and attaches `Baobab.dmg`.

### App Bundle (`scripts/create_app.sh`)

Takes the Meson install prefix as its only argument and produces `Baobab.app` in the current directory. It:

- Writes `Contents/MacOS/Baobab` — a launcher shell script that sets `XDG_DATA_DIRS`, `GSETTINGS_SCHEMA_DIR`, and `GDK_PIXBUF_MODULE_FILE` before exec-ing the actual baobab binary from the prefix
- Writes `Contents/Info.plist` with bundle metadata (identifier: `org.gnome.baobab`, min macOS 11.0)
- Converts the upstream SVG icon to `.icns` using `rsvg-convert` and `iconutil`

**Important:** The launcher script embeds the absolute `PREFIX` path at build time. This means the app bundle is not relocatable — it depends on the Homebrew-installed libraries at the path where they were built.
