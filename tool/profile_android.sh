#!/usr/bin/env bash
set -euo pipefail

flutter clean
flutter pub get
flutter build apk \
  --profile \
  --target-platform android-arm64 \
  --split-per-abi

echo
echo "Profile APK selesai dibuat."
echo "Gunakan APK arm64 pada perangkat fisik, lalu hubungkan Flutter DevTools"
echo "untuk melihat UI thread, Raster thread, shader compilation, dan frame time."