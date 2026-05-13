#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${STICK_REPO_URL:-https://github.com/jvalaj/stick.git}"
INSTALL_DIR="${STICK_INSTALL_DIR:-$HOME/Applications}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

command -v git >/dev/null 2>&1 || {
  echo "git is required. Install Xcode Command Line Tools with: xcode-select --install" >&2
  exit 1
}

command -v swift >/dev/null 2>&1 || {
  echo "swift is required. Install Xcode Command Line Tools with: xcode-select --install" >&2
  exit 1
}

git clone --depth 1 "$REPO_URL" "$TMP_DIR/stick"
cd "$TMP_DIR/stick"

./scripts/build-app.sh
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/Stick.app"
cp -R "$TMP_DIR/stick/dist/Stick.app" "$INSTALL_DIR/Stick.app"

echo "Installed Stick to $INSTALL_DIR/Stick.app"
echo "Unsigned app note: if macOS blocks launch, right-click Stick.app and choose Open."
