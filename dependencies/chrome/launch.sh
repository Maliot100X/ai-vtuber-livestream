#!/bin/bash
# Launch Chrome with virtual audio for VTuber streaming
# Prerequisites: Xvfb running on :99, PulseAudio with virtual_output sink
export DISPLAY=:99
PULSE_SINK=virtual_output exec google-chrome \
  --no-sandbox \
  --window-size=1920,1080 \
  --window-position=0,0 \
  --kiosk \
  --ignore-certificate-errors \
  --start-fullscreen \
  --no-first-run \
  --disable-default-apps \
  --disable-extensions \
  --user-data-dir=/tmp/chrome-vtuber \
  --enable-features=Vulkan,PulseaudioAudioSink \
  --use-vulkan=swiftshader \
  --enable-webgl \
  --ignore-gpu-blocklist \
  --use-angle=swiftshader \
  --use-gl=angle \
  --disable-frame-rate-limit \
  --autoplay-policy=no-user-gesture-required \
  --disk-cache-size=0 \
  "https://YOUR_IP:12394/" 2>&1
