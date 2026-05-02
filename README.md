# 🎭 AI VTuber Live Stream

> **Fully automated AI VTuber that livestreams on YouTube, reads chat in real-time, and responds with voice — powered by Open-LLM-VTuber.**

## 🔴 Live Demo

**Watch it live:** [https://youtube.com/watch?v=7V90Jx7Eygo](https://youtube.com/watch?v=7V90Jx7Eygo)

The AI VTuber reads YouTube chat and responds in real-time with voice and animated Live2D character.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS EC2 (Ubuntu 24.04)                      │
│                                                                     │
│   ┌────────────┐     ┌─────────────────────┐     ┌──────────────┐  │
│   │  YouTube   │────▶│  Open-LLM-VTuber    │────▶│  LLM API     │  │
│   │  Chat      │     │  (Python Server)    │     │  (OpenAI     │  │
│   │  Bridge    │     │  :12393 / :12394    │     │  Compatible) │  │
│   └────────────┘     └──────────┬──────────┘     └──────────────┘  │
│                                 │                                   │
│                    ┌────────────┼────────────┐                      │
│                    ▼            │            ▼                      │
│            ┌────────────┐      │    ┌──────────────┐               │
│            │  Edge TTS  │      │    │  Live2D Model │               │
│            │  (Voice)   │      │    │  (Animation)  │               │
│            └─────┬──────┘      │    └──────┬───────┘               │
│                  │             │           │                        │
│                  ▼             │           ▼                        │
│          ┌────────────┐       │    ┌──────────────┐                │
│          │ PulseAudio │       │    │   Chrome      │                │
│          │ (Virtual   │       │    │   (Display    │                │
│          │  Sink)     │       │    │    :99)       │                │
│          └─────┬──────┘       │    └──────┬───────┘                │
│                │              │           │                         │
│                └──────────────┼───────────┘                         │
│                               ▼                                     │
│                       ┌──────────────┐                              │
│                       │   FFmpeg     │                              │
│                       │ (x11grab +   │                              │
│                       │  pulse)      │                              │
│                       └──────┬───────┘                              │
│                              │                                      │
└──────────────────────────────┼──────────────────────────────────────┘
                               │ RTMP
                               ▼
                    ┌─────────────────────┐
                    │   YouTube Live      │
                    │   (RTMP Ingest)     │
                    └─────────────────────┘
```

### Data Flow

```
1. YouTube Chat → Chat Bridge (Python) → WebSocket → VTuber Server
2. VTuber Server → LLM API → Response Text
3. Response Text → Edge TTS → Audio Bytes
4. Audio + Live2D Animation → Chrome (Display :99)
5. Chrome → PulseAudio Virtual Sink → FFmpeg audio capture
6. Chrome → Xvfb Display :99 → FFmpeg video capture
7. FFmpeg → H.264 + AAC → RTMP → YouTube Live
```

---

## 🚀 One-Command Setup

```bash
# On a fresh AWS EC2 Ubuntu 24.04 instance:
curl -sSL https://raw.githubusercontent.com/Maliot100X/ai-vtuber-livestream/main/setup.sh | bash
```

Then edit your config:
```bash
nano ~/Open-LLM-VTuber/.env
nano ~/Open-LLM-VTuber/conf.yaml
```

Then start:
```bash
~/ai-vtuber-livestream/scripts/start_vtuber.sh
```

---

## 📋 Prerequisites

- **AWS EC2** — Ubuntu 24.04, t3.large (2 vCPU, 8GB RAM) or better
- **Security Group** — Open ports `12393`, `12394`, `22`
- **YouTube Channel** — Live streaming enabled, get your stream key from YouTube Studio
- **LLM API Key** — Any OpenAI-compatible provider (OpenAI, Groq, OpenRouter, Together, DeepSeek, etc.)

---

## 🔧 Manual Setup (Step by Step)

### Step 1: System Dependencies

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  python3 python3-pip python3-venv \
  git curl wget unzip \
  xvfb pulseaudio ffmpeg \
  libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 \
  libgbm1 libasound2 libxshmfence1
```

### Step 2: Install Google Chrome

```bash
wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i /tmp/chrome.deb || sudo apt-get install -f -y
rm /tmp/chrome.deb
```

### Step 3: Clone & Install Open-LLM-VTuber

```bash
cd ~
git clone https://github.com/Open-LLM-VTuber/Open-LLM-VTuber.git
cd Open-LLM-VTuber

python3 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
pip install chat-downloader websocket-client edge-tts
```

### Step 4: Clone This Repo (Config & Scripts)

```bash
cd ~
git clone https://github.com/Maliot100X/ai-vtuber-livestream.git
```

### Step 5: Configure

```bash
# Copy config template
cp ~/ai-vtuber-livestream/config/conf.yaml.example ~/Open-LLM-VTuber/conf.yaml

# Copy env template
cp ~/ai-vtuber-livestream/.env.example ~/Open-LLM-VTuber/.env

# Edit with your values
nano ~/Open-LLM-VTuber/.env
```

Your `.env` should look like:
```env
LLM_BASE_URL=https://api.openai.com/v1
LLM_API_KEY=sk-your-actual-key
LLM_MODEL=gpt-4o-mini
YOUTUBE_STREAM_KEY=xxxx-xxxx-xxxx-xxxx
YOUTUBE_VIDEO_ID=7V90Jx7Eygo
VTUBER_PUBLIC_IP=your-ec2-ip
```

Then edit `conf.yaml`:
```bash
nano ~/Open-LLM-VTuber/conf.yaml
```

Update the LLM section:
```yaml
openai_compatible_llm:
  base_url: 'YOUR_LLM_BASE_URL'
  llm_api_key: 'YOUR_LLM_API_KEY'
  model: 'YOUR_MODEL'
```

### Step 6: Set Up Virtual Display & Audio

```bash
# Start virtual display
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99

# Start PulseAudio with virtual sink
pulseaudio --start --exit-idle-time=-1
pactl load-module module-null-sink sink_name=virtual_output
pactl set-default-sink virtual_output
```

### Step 7: Patch Frontend for Proxy WebSocket

```bash
cd ~/Open-LLM-VTuber
FRONTEND_JS=$(ls frontend/assets/main-*.js)

# The default connects to /client-ws, we need /proxy-ws
sed -i 's|/client-ws|/proxy-ws|g' "$FRONTEND_JS"

# Update the URL to your server IP
sed -i 's|wss://localhost:12394|wss://YOUR_IP:12394|g' "$FRONTEND_JS"
sed -i 's|https://localhost:12394|https://YOUR_IP:12394|g' "$FRONTEND_JS"
```

### Step 8: Start Everything

Open 4 terminals (or use `tmux`/`screen`):

```bash
# Terminal 1: VTuber Server
cd ~/Open-LLM-VTuber && source .venv/bin/activate && python main.py

# Terminal 2: Chrome
export DISPLAY=:99
PULSE_SINK=virtual_output google-chrome \
  --no-sandbox --kiosk --window-size=1920,1080 \
  --ignore-certificate-errors --start-fullscreen \
  --no-first-run --disable-default-apps --disable-extensions \
  --user-data-dir=/tmp/chrome-vtuber \
  --enable-features=Vulkan,PulseaudioAudioSink \
  --use-vulkan=swiftshader --enable-webgl --ignore-gpu-blocklist \
  --use-angle=swiftshader --use-gl=angle \
  --disable-frame-rate-limit --autoplay-policy=no-user-gesture-required \
  "https://YOUR_IP:12394/"

# Terminal 3: YouTube Chat Bridge
export YOUTUBE_VIDEO_ID=7V90Jx7Eygo
cd ~/ai-vtuber-livestream && source ~/Open-LLM-VTuber/.venv/bin/activate
python3 scripts/youtube_chat_bridge.py

# Terminal 4: FFmpeg to YouTube
export YOUTUBE_STREAM_KEY=your-key
ffmpeg -re \
  -f x11grab -video_size 1920x1080 -framerate 30 -i :99 \
  -f pulse -i virtual_output.monitor \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -b:v 4500k -maxrate 4500k -bufsize 9000k \
  -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 128k \
  -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_STREAM_KEY"
```

Or just use the script:
```bash
~/ai-vtuber-livestream/scripts/start_vtuber.sh
```

---

## 📁 Project Structure

```
ai-vtuber-livestream/
├── README.md                        # This file
├── LICENSE                          # MIT License
├── .env.example                     # Environment variables template
├── .gitignore
├── setup.sh                         # One-command full setup
├── config/
│   └── conf.yaml.example            # Open-LLM-VTuber config template
├── scripts/
│   ├── youtube_chat_bridge.py       # YouTube chat → VTuber WebSocket
│   ├── start_vtuber.sh              # Start all services
│   ├── stop_vtuber.sh               # Stop all services
│   └── health_check.sh              # Check service status
└── docs/
    ├── ARCHITECTURE.md              # Deep dive on how it works
    ├── TROUBLESHOOTING.md           # Fix common issues
    └── LLM_PROVIDERS.md             # Configure any LLM provider
```

---

## 🛠️ Management Commands

```bash
# Start everything
~/ai-vtuber-livestream/scripts/start_vtuber.sh

# Stop everything
~/ai-vtuber-livestream/scripts/stop_vtuber.sh

# Check status
~/ai-vtuber-livestream/scripts/health_check.sh

# View logs
tail -f /tmp/vtuber-server.log
tail -f /tmp/yt-bridge.log
tail -f /tmp/ffmpeg-stream.log

# Restart just the chat bridge
pkill -f youtube_chat_bridge
cd ~/ai-vtuber-livestream && python3 scripts/youtube_chat_bridge.py

# Restart just FFmpeg
pkill -f "ffmpeg.*youtube"
# Re-run the ffmpeg command from start_vtuber.sh
```

---

## 🤖 Supported LLM Providers

| Provider | Config Key | Example Model | Speed |
|----------|-----------|---------------|-------|
| **Groq** | `groq_llm` | `llama-3.3-70b-versatile` | ⚡⚡⚡ |
| **DeepSeek** | `deepseek_llm` | `deepseek-chat` | ⚡⚡ |
| **OpenAI** | `openai_llm` | `gpt-4o-mini` | ⚡⚡ |
| **OpenRouter** | `openai_compatible_llm` | `anthropic/claude-3.5-sonnet` | ⚡⚡ |
| **Together** | `openai_compatible_llm` | `Meta-Llama-3.1-70B` | ⚡⚡ |
| **Gemini** | `gemini_llm` | `gemini-2.0-flash-exp` | ⚡⚡⚡ |
| **Claude** | `claude_llm` | `claude-3-haiku` | ⚡⚡ |
| **Ollama** | `ollama_llm` | `llama3.2` | ⚡ |

See [docs/LLM_PROVIDERS.md](docs/LLM_PROVIDERS.md) for exact config for each provider.

---

## 🎤 Supported TTS Engines

| Engine | Quality | Latency | Cost | Config |
|--------|---------|---------|------|--------|
| **Edge TTS** | ★★★★ | Fast | Free | `edge_tts` |
| **OpenAI TTS** | ★★★★★ | Medium | Paid | `openai_tts` |
| **ElevenLabs** | ★★★★★ | Medium | Paid | `elevenlabs_tts` |
| **Fish Audio** | ★★★★ | Medium | Paid | `fish_api_tts` |
| **Piper** | ★★★ | Fast | Free | `piper_tts` |
| **Bark** | ★★★★ | Slow | Free | `bark_tts` |

---

## 🐛 Common Issues

**Chrome shows blank screen?**
→ Check Xvfb: `ps aux | grep Xvfb` and `echo $DISPLAY`

**No audio in stream?**
→ Check PulseAudio: `pactl list sinks short | grep virtual_output`

**VTuber not reading chat?**
→ Check bridge: `tail -f /tmp/yt-bridge.log`

**AI not responding?**
→ Check logs: `tail -50 ~/Open-LLM-VTuber/logs/debug_*.log`

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for full guide.

---

## 📚 Dependencies & Credits

| Project | What We Use It For | Link |
|---------|-------------------|------|
| **Open-LLM-VTuber** | Core VTuber framework | [GitHub](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber) |
| **Edge TTS** | Free text-to-speech | [GitHub](https://github.com/rany2/edge-tts) |
| **chat-downloader** | YouTube chat scraper | [GitHub](https://github.com/xenova/chat-downloader) |
| **websocket-client** | WebSocket connections | [GitHub](https://github.com/websocket-client/websocket-client) |
| **FFmpeg** | Video/audio encoding | [ffmpeg.org](https://ffmpeg.org) |
| **Google Chrome** | Live2D rendering | [chrome.google.com](https://chrome.google.com) |
| **PulseAudio** | Virtual audio routing | [freedesktop.org](https://www.freedesktop.org/wiki/Software/PulseAudio/) |
| **Xvfb** | Virtual display | [X.Org](https://www.x.org/) |

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

**Built with ❤️ for the VTuber community**
