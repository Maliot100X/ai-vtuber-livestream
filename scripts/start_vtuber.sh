#!/bin/bash
# Start all AI VTuber services
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VTUBER_DIR="$HOME/Open-LLM-VTuber"

echo "🎭 Starting AI VTuber Live Stream..."
echo "======================================"

# Source environment
if [ -f "$VTUBER_DIR/.env" ]; then
  set -a
  source "$VTUBER_DIR/.env"
  set +a
fi

# 1. Virtual Display
if ! pgrep -x Xvfb > /dev/null; then
  echo "[1/6] Starting virtual display (Xvfb :99)..."
  Xvfb :99 -screen 0 1920x1080x24 &
  sleep 1
else
  echo "[1/6] Virtual display already running"
fi
export DISPLAY=:99

# 2. PulseAudio
if ! pgrep -x pulseaudio > /dev/null; then
  echo "[2/6] Starting PulseAudio..."
  pulseaudio --start --exit-idle-time=-1
  sleep 1
else
  echo "[2/6] PulseAudio already running"
fi

# Create virtual audio sink
pactl load-module module-null-sink sink_name=virtual_output sink_properties=device.description="Virtual_Output" 2>/dev/null || true
pactl set-default-sink virtual_output

# 3. VTuber Server
echo "[3/6] Starting VTuber server..."
cd "$VTUBER_DIR"
source .venv/bin/activate
nohup python main.py > /tmp/vtuber-server.log 2>&1 &
echo $! > /tmp/vtuber-server.pid
sleep 3

# 4. Chrome
echo "[4/6] Starting Chrome..."
PULSE_SINK=virtual_output nohup google-chrome \
  --no-sandbox \
  --window-size=1920,1080 \
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
  "https://${VTUBER_PUBLIC_IP:-localhost}:12394/" > /tmp/chrome-vtuber.log 2>&1 &
echo $! > /tmp/chrome-vtuber.pid
sleep 2

# 5. YouTube Chat Bridge
echo "[5/6] Starting YouTube Chat Bridge..."
cd "$REPO_DIR"
source "$VTUBER_DIR/.venv/bin/activate"
nohup python3 scripts/youtube_chat_bridge.py > /tmp/yt-bridge.log 2>&1 &
echo $! > /tmp/yt-bridge.pid
sleep 1

# 6. FFmpeg Stream
echo "[6/6] Starting FFmpeg stream to YouTube..."
nohup ffmpeg -re \
  -f x11grab -video_size 1920x1080 -framerate 30 -i :99 \
  -f pulse -i virtual_output.monitor \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -b:v 4500k -maxrate 4500k -bufsize 9000k \
  -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 128k \
  -f flv "rtmp://a.rtmp.youtube.com/live2/${YOUTUBE_STREAM_KEY}" > /tmp/ffmpeg-stream.log 2>&1 &
echo $! > /tmp/ffmpeg-stream.pid

echo ""
echo "✅ All services started!"
echo "========================"
echo "  VTuber Server:  https://${VTUBER_PUBLIC_IP:-localhost}:12393"
echo "  Proxy:          https://${VTUBER_PUBLIC_IP:-localhost}:12394"
echo "  YouTube Live:   https://youtube.com/watch?v=${YOUTUBE_VIDEO_ID}"
echo ""
echo "📋 Logs:"
echo "  tail -f /tmp/vtuber-server.log"
echo "  tail -f /tmp/yt-bridge.log"
echo "  tail -f /tmp/ffmpeg-stream.log"
