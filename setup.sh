#!/bin/bash
# setup.sh
# --------
# Run this ONCE from inside the "gammaai_mvvm" folder (this bundle) to
# generate the native iOS/Android project shell and drop this MVVM source
# code into it. Requires the Flutter SDK to already be installed on your
# Mac (this script cannot install Flutter itself).
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh

set -e  # stop immediately if any command fails

APP_NAME="gammaai_app"

echo "Checking for Flutter SDK..."
if ! command -v flutter &> /dev/null; then
    echo "ERROR: 'flutter' command not found."
    echo "Install Flutter first: https://docs.flutter.dev/get-started/install/macos"
    exit 1
fi

echo "Creating native Flutter project shell ($APP_NAME)..."
flutter create "$APP_NAME"

echo "Copying MVVM source files into $APP_NAME/..."
cp -r lib "$APP_NAME/lib"
cp pubspec.yaml "$APP_NAME/pubspec.yaml"

echo "Installing dependencies..."
cd "$APP_NAME"
flutter pub get

echo ""
echo "Done. Project created at: $(pwd)"
echo ""
echo "IMPORTANT — two manual edits still needed before running (see README.md):"
echo "  1. android/app/src/main/AndroidManifest.xml -> add android:usesCleartextTraffic=\"true\""
echo "  2. ios/Runner/Info.plist -> add NSAppTransportSecurity / NSAllowsArbitraryLoads"
echo ""
echo "Then run: flutter run"
