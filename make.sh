#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# make.sh — Build mega_llms for all platforms
#
# Usage:
#   ./make.sh                  # auto-detect host, build what makes sense
#   ./make.sh android web      # build only android and web
#   ./make.sh windows          # build only windows (run on Windows host)
#   ./make.sh ios macos        # build only iOS and macOS (run on macOS host)
#
# Available platforms: android, ios, macos, web, linux, windows
#
# Recommended CI split:
#   macOS runner:   ./make.sh android ios macos web
#   Linux runner:   ./make.sh linux
#   Windows runner: ./make.sh windows
# ─────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RELEASES_DIR="$SCRIPT_DIR/releases"
HOST_OS="$(uname -s)"
VERSION=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f2)

SUCCESSES=()
FAILURES=()

# ─────────────────────────────────────────────
# Determine which platforms to build
# ─────────────────────────────────────────────

VALID_PLATFORMS=(android ios macos web linux windows)

if [[ $# -gt 0 ]]; then
  # User specified platforms explicitly
  PLATFORMS=("$@")
  for p in "${PLATFORMS[@]}"; do
    valid=false
    for v in "${VALID_PLATFORMS[@]}"; do
      [[ "$p" == "$v" ]] && valid=true
    done
    if ! $valid; then
      echo "Unknown platform: $p"
      echo "Valid platforms: ${VALID_PLATFORMS[*]}"
      exit 1
    fi
  done
else
  # Auto-detect based on host OS
  case "$HOST_OS" in
    Darwin)  PLATFORMS=(android ios macos web) ;;
    Linux)   PLATFORMS=(linux) ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORMS=(windows) ;;
    *)       PLATFORMS=(android web) ;;
  esac
fi

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

info()  { printf '\n\033[1;34m=> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m   ✓ %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m   ⚠ %s\033[0m\n' "$*"; }
fail()  { printf '\033[1;31m   ✗ %s\033[0m\n' "$*"; }

file_size() {
  if [[ -f "$1" ]]; then
    du -sh "$1" | awk '{print $1}'
  elif [[ -d "$1" ]]; then
    du -sh "$1" | awk '{print $1}'
  else
    echo "N/A"
  fi
}

# ─────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────

info "mega_llms build script — v${VERSION}+${BUILD_NUMBER}"
echo "   Host OS:    $HOST_OS"
echo "   Platforms:  ${PLATFORMS[*]}"
echo "   Flutter:    $(flutter --version --machine 2>/dev/null | head -1 || echo 'unknown')"

info "Cleaning previous build artifacts..."
flutter clean
flutter pub get

rm -rf "$RELEASES_DIR"
mkdir -p "$RELEASES_DIR"

# Debug symbols are split out to reduce binary size
DEBUG_INFO_DIR="$RELEASES_DIR/.debug-symbols"
mkdir -p "$DEBUG_INFO_DIR"

# Common flags for size optimization
RELEASE_FLAGS=(
  --release
  --split-debug-info="$DEBUG_INFO_DIR"
  --obfuscate
  --tree-shake-icons
)

# ─────────────────────────────────────────────
# Android
# ─────────────────────────────────────────────

build_android() {
  info "Building Android..."

  if ! command -v flutter &>/dev/null; then
    fail "Flutter not found"; return 1
  fi

  warn "Using debug signing — configure key.properties for production releases"

  local out="$RELEASES_DIR"

  # Fat APK
  info "  Building universal APK..."
  if flutter build apk "${RELEASE_FLAGS[@]}"; then
    cp build/app/outputs/flutter-apk/app-release.apk "$out/android-megallm-${VERSION}.apk"
    ok "android-megallm-${VERSION}.apk ($(file_size "$out/android-megallm-${VERSION}.apk"))"
  else
    fail "Universal APK build failed"
  fi

  # Split APKs
  info "  Building split APKs..."
  if flutter build apk --release --split-per-abi; then
    for abi in arm64-v8a armeabi-v7a x86_64; do
      local src="build/app/outputs/flutter-apk/app-${abi}-release.apk"
      if [[ -f "$src" ]]; then
        cp "$src" "$out/android-megallm-${VERSION}-${abi}.apk"
        ok "android-megallm-${VERSION}-${abi}.apk ($(file_size "$out/android-megallm-${VERSION}-${abi}.apk"))"
      else
        warn "Split APK for $abi not found"
      fi
    done
  else
    fail "Split APK build failed"
  fi

  # App Bundle
  info "  Building App Bundle..."
  if flutter build appbundle "${RELEASE_FLAGS[@]}"; then
    cp build/app/outputs/bundle/release/app-release.aab "$out/android-megallm-${VERSION}.aab"
    ok "android-megallm-${VERSION}.aab ($(file_size "$out/android-megallm-${VERSION}.aab"))"
  else
    fail "App Bundle build failed"
  fi

  SUCCESSES+=("Android")
}

# ─────────────────────────────────────────────
# iOS
# ─────────────────────────────────────────────

build_ios() {
  info "Building iOS..."

  if ! xcode-select -p &>/dev/null; then
    fail "Xcode not found — skipping iOS"; return 1
  fi

  local out="$RELEASES_DIR"

  warn "Building without codesign — IPA will not be installable on devices without re-signing"

  if flutter build ios "${RELEASE_FLAGS[@]}" --no-codesign; then
    local app_path="build/ios/iphoneos/Runner.app"
    if [[ -d "$app_path" ]]; then
      # Package as IPA (Payload/Runner.app zipped)
      local payload_dir
      payload_dir="$(mktemp -d)"
      mkdir -p "$payload_dir/Payload"
      cp -R "$app_path" "$payload_dir/Payload/Runner.app"
      (cd "$payload_dir" && zip -r -y "$out/ios-megallm-${VERSION}.ipa" Payload)
      rm -rf "$payload_dir"
      ok "ios-megallm-${VERSION}.ipa ($(file_size "$out/ios-megallm-${VERSION}.ipa"))"
      SUCCESSES+=("iOS")
    else
      fail "Runner.app not found after build"
      return 1
    fi
  else
    fail "iOS build failed"
    return 1
  fi
}

# ─────────────────────────────────────────────
# macOS
# ─────────────────────────────────────────────

build_macos() {
  info "Building macOS..."

  local out="$RELEASES_DIR"

  if flutter build macos "${RELEASE_FLAGS[@]}"; then
    local app_path="build/macos/Build/Products/Release/mega_llms.app"
    if [[ -d "$app_path" ]]; then
      # Create DMG installer
      local dmg_path="$out/macos-megallm-${VERSION}.dmg"
      hdiutil create -volname "MegaLLM ${VERSION}" \
        -srcfolder "$app_path" \
        -ov -format UDZO \
        "$dmg_path"
      ok "macos-megallm-${VERSION}.dmg ($(file_size "$dmg_path"))"

      # Also create a zip for portability
      (cd "$(dirname "$app_path")" && zip -r -y "$out/macos-megallm-${VERSION}.app.zip" "mega_llms.app")
      ok "macos-megallm-${VERSION}.app.zip ($(file_size "$out/macos-megallm-${VERSION}.app.zip"))"

      SUCCESSES+=("macOS")
    else
      fail "mega_llms.app not found after build"
      return 1
    fi
  else
    fail "macOS build failed"
    return 1
  fi
}

# ─────────────────────────────────────────────
# Web
# ─────────────────────────────────────────────

build_web() {
  info "Building Web..."

  local out="$RELEASES_DIR"

  if flutter build web --release --tree-shake-icons --pwa-strategy offline-first; then
    # Create a deployable zip archive
    (cd build/web && zip -r "$out/web-megallm-${VERSION}.zip" .)
    ok "web-megallm-${VERSION}.zip ($(file_size "$out/web-megallm-${VERSION}.zip"))"
    SUCCESSES+=("Web")
  else
    fail "Web build failed"
    return 1
  fi
}

# ─────────────────────────────────────────────
# Linux
# ─────────────────────────────────────────────

build_linux() {
  info "Building Linux..."

  local out="$RELEASES_DIR"

  if flutter build linux "${RELEASE_FLAGS[@]}"; then
    local bundle_path="build/linux/x64/release/bundle"
    if [[ -d "$bundle_path" ]]; then
      # tar.gz — standard Linux distributable
      tar -czf "$out/linux-megallm-${VERSION}.tar.gz" -C "$bundle_path" .
      ok "linux-megallm-${VERSION}.tar.gz ($(file_size "$out/linux-megallm-${VERSION}.tar.gz"))"

      # Also create a .deb if dpkg-deb is available
      if command -v dpkg-deb &>/dev/null; then
        local deb_root
        deb_root="$(mktemp -d)"
        mkdir -p "$deb_root/DEBIAN"
        mkdir -p "$deb_root/usr/local/bin"
        mkdir -p "$deb_root/usr/local/lib/megallm"
        mkdir -p "$deb_root/usr/share/applications"

        cat > "$deb_root/DEBIAN/control" <<CTRL
Package: megallm
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: MegaLLM
Description: MegaLLM — multi-platform LLM client
CTRL

        cp -R "$bundle_path"/* "$deb_root/usr/local/lib/megallm/"
        ln -sf /usr/local/lib/megallm/mega_llms "$deb_root/usr/local/bin/megallm"

        cat > "$deb_root/usr/share/applications/megallm.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=MegaLLM
Exec=/usr/local/bin/megallm
Icon=megallm
Categories=Utility;
DESKTOP

        dpkg-deb --build "$deb_root" "$out/linux-megallm-${VERSION}.deb"
        rm -rf "$deb_root"
        ok "linux-megallm-${VERSION}.deb ($(file_size "$out/linux-megallm-${VERSION}.deb"))"
      else
        warn "dpkg-deb not found — skipping .deb package"
      fi

      SUCCESSES+=("Linux")
    else
      fail "Linux bundle not found after build"
      return 1
    fi
  else
    fail "Linux build failed"
    return 1
  fi
}

# ─────────────────────────────────────────────
# Windows
# ─────────────────────────────────────────────

build_windows() {
  info "Building Windows..."

  local out="$RELEASES_DIR"

  if flutter build windows "${RELEASE_FLAGS[@]}"; then
    local bundle_path="build/windows/x64/runner/Release"
    if [[ -d "$bundle_path" ]]; then
      # Zip bundle as portable distributable
      (cd "$bundle_path" && zip -r "$out/windows-megallm-${VERSION}.zip" .)
      ok "windows-megallm-${VERSION}.zip ($(file_size "$out/windows-megallm-${VERSION}.zip"))"

      # Build MSIX installer if flutter_distributor / msix is configured
      if flutter pub deps 2>/dev/null | grep -q msix; then
        info "  Building MSIX installer..."
        if flutter pub run msix:create --release; then
          local msix_file
          msix_file=$(find build -name "*.msix" -type f 2>/dev/null | head -1)
          if [[ -n "$msix_file" ]]; then
            cp "$msix_file" "$out/windows-megallm-${VERSION}.msix"
            ok "windows-megallm-${VERSION}.msix ($(file_size "$out/windows-megallm-${VERSION}.msix"))"
          fi
        else
          warn "MSIX build failed — zip is still available"
        fi
      else
        warn "msix package not found in dependencies — only zip produced"
        warn "Add 'msix' to dev_dependencies for MSIX installer support"
      fi

      SUCCESSES+=("Windows")
    else
      fail "Windows bundle not found after build"
      return 1
    fi
  else
    fail "Windows build failed"
    return 1
  fi
}

# ─────────────────────────────────────────────
# Run all builds
# ─────────────────────────────────────────────

for platform in "${PLATFORMS[@]}"; do
  if ! "build_${platform}"; then
    FAILURES+=("$platform")
  fi
done

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo ""
info "Build Summary — mega_llms v${VERSION}+${BUILD_NUMBER}"
echo "   ──────────────────────────────────────"

if [[ ${#SUCCESSES[@]} -gt 0 ]]; then
  for p in "${SUCCESSES[@]}"; do
    ok "$p"
  done
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  for p in "${FAILURES[@]}"; do
    fail "$p"
  done
fi

echo ""
echo "   Outputs: $RELEASES_DIR"
echo ""

# List all files in releases/
if command -v tree &>/dev/null; then
  tree -sh "$RELEASES_DIR"
else
  find "$RELEASES_DIR" -type f -exec du -sh {} \;
fi

echo ""
if [[ ${#FAILURES[@]} -gt 0 ]]; then
  warn "${#FAILURES[@]} platform(s) failed. Check logs above."
  exit 1
else
  ok "All platforms built successfully!"
fi
