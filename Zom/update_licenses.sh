#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Update license info
license-plist --add-version-numbers --cartfile-path "$DIR/Cartfile" --pods-path "$DIR/Pods" --config-path "$DIR/license_plist.yml" --output-path "$DIR/com.mono0926.LicensePlist.Output"
rm -rf "$DIR/Settings.bundle/com.mono0926.LicensePlist"
cp -R "$DIR/com.mono0926.LicensePlist.Output/com.mono0926.LicensePlist" "$DIR/Settings.bundle/"
cp "$DIR/com.mono0926.LicensePlist.Output/com.mono0926.LicensePlist.plist" "$DIR/Settings.bundle/"
echo "Updated license info"
