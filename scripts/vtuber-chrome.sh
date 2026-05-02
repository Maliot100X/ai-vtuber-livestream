#!/bin/bash
export DISPLAY=:99
exec google-chrome \
  --no-sandbox \
  --window-size=1920,1080 \
  --window-position=0,0 \
  --kiosk \
  --ignore-certificate-errors \
  --start-fullscreen \
  --no-first-run \
  --disable-default-apps \
  --disable-extensions \
  --user-data-dir=/tmp/chrome-vtuber-clean \
  --enable-features=Vulkan \
  --use-vulkan=swiftshader \
  --enable-webgl \
  --ignore-gpu-blocklist \
  --use-angle=swiftshader \
  --use-gl=angle \
  --disable-frame-rate-limit \
  --autoplay-policy=no-user-gesture-required \
  "https://13.48.58.26:12394/" 2>&1
