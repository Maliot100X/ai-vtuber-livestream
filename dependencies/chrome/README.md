# Google Chrome — Live2D Rendering

**Download:** https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
**What it does:** Headless browser for rendering Live2D anime avatar

## What We Use It For
- Renders the Open-LLM-VTuber frontend (Live2D model)
- Plays TTS audio through PulseAudio virtual sink
- Runs in kiosk mode at 1920x1080 on virtual display :99
- Captured by FFmpeg via x11grab

## Installation
```bash
# Download and install
wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i /tmp/chrome.deb || sudo apt-get install -f -y
rm /tmp/chrome.deb

# Verify
google-chrome --version
```

## Launch Command
```bash
export DISPLAY=:99
PULSE_SINK=virtual_output google-chrome \
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
  "https://YOUR_IP:12394/"
```

## Key Flags
- `--no-sandbox` — Required for running as root/non-root on headless server
- `--kiosk --start-fullscreen` — Full screen mode for streaming
- `--ignore-certificate-errors` — Accept self-signed SSL certs
- `--enable-features=PulseaudioAudioSink` — Route audio to PulseAudio
- `--user-data-dir=/tmp/chrome-vtuber` — Clean profile (no saved settings)
- `--use-vulkan=swiftshader --use-gl=angle` — Software GPU rendering

## Audio Routing
Chrome audio goes to PulseAudio `virtual_output` sink, which FFmpeg captures via `virtual_output.monitor`.

## Our Script
See `../../scripts/vtuber-chrome.sh` for our launch script.
