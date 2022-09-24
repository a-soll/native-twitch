#!/bin/bash

# use Xcode archive and when it's done, copy the app to ~/Desktop
# and run this scirpt from native_twitch project root

SPARKLE_PATH=/Users/$(whoami)/Library/Developer/Xcode/DerivedData/native_twitch-*/SourcePackages/artifacts/sparkle
APP_PATH=$(find ~/Desktop -maxdepth 1 -type d -name 'Native Twitch*')

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH/Native Twitch.app" "$APP_PATH/Native Twitch.app.zip"

$SPARKLE_PATH/bin/generate_appcast -o ./appcast.xml "$APP_PATH"

sed -i '' -e "s/a-soll.github.io\/native-twitch\/Native%20Twitch.app.zip/github.com\/a-soll\/native-twitch\/releases\/latest\/download\/Native.Twitch.app.zip/g" ./appcast.xml
