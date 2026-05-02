#!/bin/bash
# ============================================
# AI VTuber Live Stream - One-Command Setup
# ============================================
# Run: curl -sSL https://raw.githubusercontent.com/Maliot100X/ai-vtuber-livestream/main/setup.sh | bash
set -euo pipefail

echo "🎭 AI VTuber Live Stream Setup"
echo "================================"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

if [ "$EUID" -eq 0 ]; then
  error "Don't run as root. Run as a regular user with sudo access."
fi

# ============================================
# 1. SYSTEM DEPENDENCIES
# ============================================
log "[1/8] Installing system dependencies..."
sudo apt update -qq
sudo apt install -y -qq \
  python3 python3-pip python3-venv python3-dev \
  git curl wget unzip build-essential \
  xvfb pulseaudio ffmpeg \
  libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 \
  libgbm1 libasound2 libxshmfence1 \
  libgtk-3-0 libx11-xcb1 libxcb-dri3-0 libxcomposite1 \
  libxdamage1 libxrandr2 libxss1 libxtst6 2>/dev/null

# ============================================
# 2. INSTALL GOOGLE CHROME
# ============================================
if ! command -v google-chrome &>/dev/null; then
  log "[2/8] Installing Google Chrome..."
  wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/chrome.deb 2>/dev/null || sudo apt-get install -f -y -qq
  rm -f /tmp/chrome.deb
fi
log "Chrome: $(google-chrome --version)"

# ============================================
# 3. CLONE OPEN-LLM-VTUBER
# ============================================
VTUBER_DIR="$HOME/Open-LLM-VTuber"
if [ ! -d "$VTUBER_DIR" ]; then
  log "[3/8] Cloning Open-LLM-VTuber..."
  git clone https://github.com/Open-LLM-VTuber/Open-LLM-VTuber.git "$VTUBER_DIR"
  # Also clone blivedm (Bilibili live chat)
  cd "$VTUBER_DIR"
  git submodule update --init --recursive 2>/dev/null || true
else
  log "[3/8] Open-LLM-VTuber already cloned"
fi

# ============================================
# 4. PYTHON ENVIRONMENT
# ============================================
log "[4/8] Setting up Python environment..."
cd "$VTUBER_DIR"
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip -q

# Install Open-LLM-VTuber dependencies
pip install -r requirements.txt -q

# Install additional packages we need
pip install -q \
  chat-downloader \
  websocket-client \
  edge-tts \
  loguru \
  requests \
  sherpa-onnx

log "Python packages installed"

# ============================================
# 5. CLONE THIS REPO (CONFIG & SCRIPTS)
# ============================================
REPO_DIR="$HOME/ai-vtuber-livestream"
if [ ! -d "$REPO_DIR" ]; then
  log "[5/8] Cloning AI VTuber Livestream config..."
  git clone https://github.com/Maliot100X/ai-vtuber-livestream.git "$REPO_DIR"
else
  log "[5/8] Config repo already cloned"
fi

# ============================================
# 6. COPY CONFIGURATION
# ============================================
log "[6/8] Setting up configuration..."

# Copy full config
if [ ! -f "$VTUBER_DIR/conf.yaml" ] || [ "${FORCE_CONFIG:-0}" = "1" ]; then
  cp "$REPO_DIR/config/conf.yaml.full" "$VTUBER_DIR/conf.yaml"
  log "Copied conf.yaml"
fi

# Copy env
if [ ! -f "$VTUBER_DIR/.env" ]; then
  cp "$REPO_DIR/.env.example" "$VTUBER_DIR/.env"
  warn "Edit $VTUBER_DIR/.env with your API keys!"
fi

# ============================================
# 7. PATCH FRONTEND (proxy-ws fix)
# ============================================
log "[7/8] Patching frontend for proxy WebSocket..."
cd "$VTUBER_DIR"
FRONTEND_JS=$(ls frontend/assets/main-*.js 2>/dev/null | head -1)
if [ -n "$FRONTEND_JS" ]; then
  # Replace client-ws with proxy-ws
  sed -i 's|/client-ws|/proxy-ws|g' "$FRONTEND_JS"
  log "Patched $FRONTEND_JS (client-ws → proxy-ws)"
fi

# ============================================
# 8. MAKE SCRIPTS EXECUTABLE
# ============================================
log "[8/8] Setting up scripts..."
chmod +x "$REPO_DIR/scripts/"*.sh
chmod +x "$REPO_DIR/scripts/"*.py 2>/dev/null || true

# ============================================
# DONE
# ============================================
echo ""
echo "================================"
echo "🎉 Setup Complete!"
echo "================================"
echo ""
echo "📂 Repositories installed:"
echo "   - Open-LLM-VTuber:  $VTUBER_DIR"
echo "   - Config & Scripts:  $REPO_DIR"
echo ""
echo "🔧 Next steps:"
echo ""
echo "  1. Edit your API keys:"
echo "     nano $VTUBER_DIR/.env"
echo ""
echo "  2. Edit VTuber config (optional):"
echo "     nano $VTUBER_DIR/conf.yaml"
echo ""
echo "  3. Start everything:"
echo "     $REPO_DIR/scripts/start_vtuber.sh"
echo ""
echo "  4. Check status:"
echo "     $REPO_DIR/scripts/health_check.sh"
echo ""
echo "📖 Full guide: $REPO_DIR/README.md"
echo ""
echo "🔗 GitHub: https://github.com/Maliot100X/ai-vtuber-livestream"
