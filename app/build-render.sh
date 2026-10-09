#!/usr/bin/env bash
set -euo pipefail
SDK_DIR="${RENDER_BUILD_CACHE_DIR:-/tmp}/kisaan-flutter-3.27.4"
if [ ! -x "$SDK_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch 3.27.4 https://github.com/flutter/flutter.git "$SDK_DIR"
fi
export PATH="$SDK_DIR/bin:$PATH"
flutter config --no-analytics
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://kisaan-ml-render.onrender.com/api/v1
