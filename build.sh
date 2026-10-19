#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
APP="JEV 微信助手.app"
mkdir -p "$APP/Contents/MacOS"
BUILD_DIR="${JEV_BUILD_DIR:-$PWD/work/jev-native-build}"
mkdir -p "$BUILD_DIR"
# A project-local VFS overlay handles stale duplicate maps in some CLT installations.
# It does not modify system files.
python3 - "$BUILD_DIR" "$(xcrun --find swiftc)" <<'PYBUILD'
import os,sys,json
build,compiler=sys.argv[1:]
include=os.path.join(os.path.dirname(os.path.dirname(compiler)), 'include', 'swift')
old=os.path.join(include,'module.modulemap'); new=os.path.join(include,'bridging.modulemap')
roots=[]
if os.path.isfile(old) and os.path.isfile(new) and 'module SwiftBridging {' in open(old).read():
 empty=os.path.abspath(os.path.join(build,'empty.modulemap'))
 open(empty,'w').write('// Hide duplicate module map only during this project build.\n')
 roots=[{'type':'file','name':old,'external-contents':empty}]
open(os.path.join(build,'swift-vfs.json'),'w').write(json.dumps({'version':0,'roots':roots}))
PYBUILD
xcrun swiftc -vfsoverlay "$BUILD_DIR/swift-vfs.json" -module-cache-path "$BUILD_DIR/cache" -swift-version 5 -Onone -target arm64-apple-macosx14.0 Sources/main.swift -o "$APP/Contents/MacOS/JEVWeChat" -framework AppKit -framework ScreenCaptureKit -framework Vision -framework Security
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>JEVWeChat</string>
<key>CFBundleIdentifier</key><string>local.jev.wechat</string>
<key>CFBundleName</key><string>JEV 微信助手</string>
<key>CFBundleVersion</key><string>2</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign "${JEV_SIGNING_IDENTITY:--}" "$APP"
print "Built: ${PWD}/$APP"
