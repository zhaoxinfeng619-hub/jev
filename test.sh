#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
EXE='JEV 微信助手.app/Contents/MacOS/JEVWeChat'
"$EXE" --self-test
python3 Tests/mock_jev.py &
MOCK_PID=$!
trap 'kill "$MOCK_PID" 2>/dev/null || true' EXIT
sleep 0.5
"$EXE" --api-test
wait "$MOCK_PID"

# Run real AppKit save/close flows using isolated persistence spies.
BUILD_DIR="${JEV_BUILD_DIR:-$PWD/work/jev-native-build}"
python3 - "$BUILD_DIR" <<'PYTEST'
from pathlib import Path
import sys
source = Path('Sources/main.swift').read_text()
entry = source.rfind('MainActor.assumeIsolated {')
assert entry >= 0
Path(sys.argv[1], 'window-lifecycle-test.swift').write_text(source[:entry] + Path('Tests/window_lifecycle.swift').read_text())
PYTEST
xcrun swiftc -vfsoverlay "$BUILD_DIR/swift-vfs.json" -module-cache-path "$BUILD_DIR/cache" -swift-version 5 -Onone -target arm64-apple-macosx14.0 "$BUILD_DIR/window-lifecycle-test.swift" -o "$BUILD_DIR/window-lifecycle-test" -framework AppKit -framework ScreenCaptureKit -framework Vision -framework Security > "$BUILD_DIR/window-lifecycle-build.log" 2>&1
"$BUILD_DIR/window-lifecycle-test"
