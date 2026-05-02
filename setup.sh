#!/bin/bash
# ============================================
# AI VTuber Live Stream - One-Command Setup
# ============================================
# Run: curl -sSL https://raw.githubusercontent.com/Maliot100X/ai-vtuber-livestream/main/setup.sh | bash
set -euo pipefail

echo "🎭 AI VTuber Live Stream Setup"
echo "================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  error "Don't run as root. Run as a regular user with sudo access."
fi

# ---- Step 1: System Dependencies ----
log "Installing system dependencies..."
sudo apt update -qq
sudo apt install -y -qq \
  python3 python3-pip python3-venv \
  git curl wget unzip \
  xvfb pulseaudio ffmpeg \
  libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 \
  libgbm1 libasound2 libxshmfence1 2>/dev/null

# ---- Step 2: Install Google Chrome ----
if ! command -v google-chrome &>/dev/null; then
  log "Installing Google Chrome..."
  wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/google-chrome.deb 2>/dev/null || sudo apt-get install -f -y -qq
  rm -f /tmp/google-chrome.deb
fi
log "Chrome installed: $(google-chrome --version)"

# ---- Step 3: Clone Open-LLM-VTuber ----
VTUBER_DIR="$HOME/Open-LLM-VTuber"
if [ ! -d "$VTUBER_DIR" ]; then
  log "Cloning Open-LLM-VTuber..."
  git clone https://github.com/Open-LLM-VTuber/Open-LLM-VTuber.git "$VTUBER_DIR"
fi

cd "$VTUBER_DIR"

# ---- Step 4: Python Environment ----
log "Setting up Python environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install chat-downloader websocket-client edge-tts -q

# ---- Step 5: Clone this repo (config & scripts) ----
REPO_DIR="$HOME/ai-vtuber-livestream"
if [ ! -d "$REPO_DIR" ]; then
  log "Cloning AI VTuber Livestream config..."
  git clone https://github.com/Maliot100X/ai-vtuber-livestream.git "$REPO_DIR"
fi

# ---- Step 6: Copy config ----
if [ ! -f "$VTUBER_DIR/conf.yaml" ] || [ "${FORCE_CONFIG:-0}" = "1" ]; then
  log "Copying configuration..."
  cp "$REPO_DIR/config/conf.yaml.example" "$VTUBER_DIR/conf.yaml"
fi

if [ ! -f "$VTUBER_DIR/.env" ]; then
  cp "$REPO_DIR/.env.example" "$VTUBER_DIR/.env"
  warn "Edit $VTUBER_DIR/.env with your API keys!"
fi

# ---- Step 7: Create startup scripts ----
log "Creating startup scripts..."

cat > "$REPO_DIR/scripts/start_vtuber.sh" << 'STARTEOF'
#!/bin/bash
# Start all VTuber services
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VTUBER_DIR="$HOME/Open-LLM-VTuber"

echo "🎭 Starting AI VTuber Live Stream..."

# Source environment
if [ -f "$VTUBER_DIR/.env" ]; then
  export $(grep -v '^#' "$VTUBER_DIR/.env" | xargs)
fi

# Start Xvfb
if ! pgrep -x Xvfb > /dev/null; then
  echo "Starting virtual display..."
  Xvfb :99 -screen 0 1920x1080x24 &
  sleep 1
fi
export DISPLAY=:99

# Start PulseAudio
if ! pgrep -x pulseaudio > /dev/null; then
  echo "Starting PulseAudio..."
  pulseaudio --start --exit-idle-time=-1
  sleep 1
fi

# Create virtual audio sink
pactl load-module module-null-sink sink_name=virtual_output sink_properties=device.description="Virtual_Output" 2>/dev/null || true
pactl set-default-sink virtual_output

# Start VTuber server
echo "Starting VTuber server..."
cd "$VTUBER_DIR"
source .venv/bin/activate
nohup python main.py > /tmp/vtuber-server.log 2>&1 &
echo $! > /tmp/vtuber-server.pid
sleep 3

# Start Chrome
echo "Starting Chrome..."
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

# Start YouTube Chat Bridge
echo "Starting YouTube Chat Bridge..."
cd "$REPO_DIR"
source "$VTUBER_DIR/.venv/bin/activate"
nohup python3 scripts/youtube_chat_bridge.py > /tmp/yt-bridge.log 2>&1 &
echo $! > /tmp/yt-bridge.pid
sleep 1

# Start FFmpeg stream
echo "Starting FFmpeg stream..."
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
echo "   VTuber Server:  https://${VTUBER_PUBLIC_IP:-localhost}:12393"
echo "   Proxy:          https://${VTUBER_PUBLIC_IP:-localhost}:12394"
echo "   YouTube Stream: https://youtube.com/watch?v=${YOUTUBE_VIDEO_ID}"
echo ""
echo "Logs:"
echo "   tail -f /tmp/vtuber-server.log"
echo "   tail -f /tmp/yt-bridge.log"
echo "   tail -f /tmp/ffmpeg-stream.log"
STARTEOF

cat > "$REPO_DIR/scripts/stop_vtuber.sh" << 'STOPEOF'
#!/bin/bash
# Stop all VTuber services
echo "Stopping AI VTuber Live Stream..."

for pidfile in /tmp/vtuber-server.pid /tmp/chrome-vtuber.pid /tmp/yt-bridge.pid /tmp/ffmpeg-stream.pid; do
  if [ -f "$pidfile" ]; then
    pid=$(cat "$pidfile")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid"
      echo "Stopped PID $pid"
    fi
    rm -f "$pidfile"
  fi
done

# Kill any remaining processes
pkill -f "python main.py" 2>/dev/null || true
pkill -f "youtube_chat_bridge" 2>/dev/null || true
pkill -f "ffmpeg.*youtube" 2>/dev/null || true
pkill -f "chrome.*vtuber" 2>/dev/null || true

echo "✅ All services stopped."
STOPEOF

cat > "$REPO_DIR/scripts/health_check.sh" << 'HEALTHEOF'
#!/bin/bash
# Health check for VTuber services
echo "🔍 AI VTuber Health Check"
echo "========================="

check() {
  if pgrep -f "$1" > /dev/null; then
    echo "✅ $2: Running"
  else
    echo "❌ $2: NOT running"
  fi
}

check "Xvfb" "Virtual Display"
check "pulseaudio" "PulseAudio"
check "python main.py" "VTuber Server"
check "chrome.*vtuber" "Chrome"
check "youtube_chat_bridge" "YouTube Chat Bridge"
check "ffmpeg.*youtube" "FFmpeg Stream"

echo ""
echo "Ports:"
ss -tlnp | grep -E '12393|12394' || echo "  (no ports listening)"
HEALTHEOF

chmod +x "$REPO_DIR/scripts/"*.sh

# ---- Done ----
echo ""
echo "================================"
echo "🎉 Setup Complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "  1. Edit your config:"
echo "     nano $VTUBER_DIR/.env"
echo "     nano $VTUBER_DIR/conf.yaml"
echo ""
echo "  2. Start everything:"
echo "     $REPO_DIR/scripts/start_vtuber.sh"
echo ""
echo "  3. Check status:"
echo "     $REPO_DIR/scripts/health_check.sh"
echo ""
echo "📖 Read the full guide: $REPO_DIR/README.md"
