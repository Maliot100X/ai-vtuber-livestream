# 🎭 AI VTuber Live Stream

> **Fully automated AI VTuber that livestreams on YouTube, reads chat in real-time, and responds with voice — powered by Open-LLM-VTuber.**

## 🔴 Live Demo

**Watch it live:** [https://youtube.com/watch?v=7V90Jx7Eygo](https://youtube.com/watch?v=7V90Jx7Eygo)

The AI VTuber reads YouTube chat and responds in real-time with voice and animated Live2D character.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS EC2 (Ubuntu 26.04)                      │
│                        t3.large (2 vCPU, 8GB)                       │
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
YouTube Chat → Chat Bridge → WebSocket → VTuber Server → LLM API
                                                      ↓
                                               Response Text
                                              ↙           ↘
                                     Edge TTS         Live2D Model
                                     (Audio)          (Animation)
                                         ↘               ↙
                                     PulseAudio    Chrome (:99)
                                         ↘           ↙
                                          FFmpeg (x11grab + pulse)
                                               ↓
                                          YouTube RTMP
```

---

## 📦 All GitHub Repos & Dependencies Used

| # | Project | What We Use It For | Link |
|---|---------|-------------------|------|
| 1 | **Open-LLM-VTuber** | Core VTuber framework (server, frontend, Live2D, proxy) | [GitHub](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber) |
| 2 | **blivedm** | Bilibili live chat integration (submodule of Open-LLM-VTuber) | [GitHub](https://github.com/Open-LLM-VTuber/blivedm) |
| 3 | **edge-tts** | Free Microsoft Edge text-to-speech engine | [GitHub](https://github.com/rany2/edge-tts) |
| 4 | **chat-downloader** | YouTube live chat scraper (Method 1) | [GitHub](https://github.com/xenova/chat-downloader) |
| 5 | **websocket-client** | Python WebSocket client for VTuber proxy | [GitHub](https://github.com/websocket-client/websocket-client) |
| 6 | **Google Chrome** | Headless browser for Live2D rendering + audio | [Download](https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb) |
| 7 | **FFmpeg** | Video/audio capture and RTMP streaming | [ffmpeg.org](https://ffmpeg.org) |
| 8 | **PulseAudio** | Virtual audio sink for routing Chrome audio to FFmpeg | [freedesktop.org](https://www.freedesktop.org/wiki/Software/PulseAudio/) |
| 9 | **Xvfb** | Virtual X11 display for headless Chrome rendering | [X.Org](https://www.x.org/) |
| 10 | **sherpa-onnx** | Local speech recognition (ASR) engine | [GitHub](https://github.com/k2-fsa/sherpa-onnx) |

### Python Packages (installed via pip)
```
chat-downloader    # YouTube chat scraping
websocket-client   # WebSocket connections
edge-tts           # Free TTS
loguru             # Logging
requests           # HTTP requests
sherpa-onnx        # Local ASR
openai             # LLM API client
anthropic          # Claude API client
```

---

## 🚀 One-Command Setup

```bash
curl -sSL https://raw.githubusercontent.com/Maliot100X/ai-vtuber-livestream/main/setup.sh | bash
```

Then configure:
```bash
nano ~/Open-LLM-VTuber/.env       # Your API keys
nano ~/Open-LLM-VTuber/conf.yaml  # Full VTuber config
```

Then start:
```bash
~/ai-vtuber-livestream/scripts/start_vtuber.sh
```

---

## 📋 Prerequisites

- **AWS EC2** — Ubuntu 24.04+, t3.large (2 vCPU, 8GB RAM) or better
- **Security Group** — Open ports `12393` (HTTPS), `12394` (WSS proxy), `22` (SSH)
- **YouTube Channel** — Live streaming enabled, get stream key from YouTube Studio → Go Live → Stream
- **LLM API Key** — Any OpenAI-compatible provider

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
pip install chat-downloader websocket-client edge-tts loguru requests
```

### Step 4: Clone This Repo
```bash
cd ~
git clone https://github.com/Maliot100X/ai-vtuber-livestream.git
```

### Step 5: Configure
```bash
# Copy config
cp ~/ai-vtuber-livestream/config/conf.yaml.full ~/Open-LLM-VTuber/conf.yaml

# Copy env
cp ~/ai-vtuber-livestream/.env.example ~/Open-LLM-VTuber/.env
nano ~/Open-LLM-VTuber/.env
```

Your `.env`:
```env
LLM_BASE_URL=https://api.openai.com/v1
LLM_API_KEY=sk-your-actual-key
LLM_MODEL=gpt-4o-mini
YOUTUBE_STREAM_KEY=xxxx-xxxx-xxxx-xxxx
YOUTUBE_VIDEO_ID=your-video-id
VTUBER_PUBLIC_IP=your-ec2-ip
```

Then edit `conf.yaml` and update the LLM section:
```yaml
openai_compatible_llm:
  base_url: 'YOUR_LLM_BASE_URL'
  llm_api_key: 'YOUR_LLM_API_KEY'
  model: 'YOUR_MODEL'
```

### Step 6: Set Up Virtual Display & Audio
```bash
# Virtual display
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99

# PulseAudio with virtual sink
pulseaudio --start --exit-idle-time=-1
pactl load-module module-null-sink sink_name=virtual_output
pactl set-default-sink virtual_output
```

### Step 7: Patch Frontend for Proxy WebSocket
The default frontend connects to `/client-ws` but we need `/proxy-ws`:
```bash
cd ~/Open-LLM-VTuber
FRONTEND_JS=$(ls frontend/assets/main-*.js)

# Replace client-ws with proxy-ws
sed -i 's|/client-ws|/proxy-ws|g' "$FRONTEND_JS"

# Update URLs to your server
sed -i 's|wss://localhost:12394|wss://YOUR_IP:12394|g' "$FRONTEND_JS"
sed -i 's|https://localhost:12394|https://YOUR_IP:12394|g' "$FRONTEND_JS"
```

### Step 8: Start Everything
```bash
~/ai-vtuber-livestream/scripts/start_vtuber.sh
```

Or manually (4 terminals):
```bash
# Terminal 1: VTuber Server
cd ~/Open-LLM-VTuber && source .venv/bin/activate && python main.py

# Terminal 2: Chrome
~/ai-vtuber-livestream/scripts/vtuber-chrome.sh

# Terminal 3: YouTube Chat Bridge
export YOUTUBE_VIDEO_ID=your-id
~/ai-vtuber-livestream/scripts/yt-chat-reader.py YOUR_VIDEO_ID

# Terminal 4: FFmpeg Stream
~/ai-vtuber-livestream/scripts/youtube-stream.sh
```

---

## 📁 Project Structure

```
ai-vtuber-livestream/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── .env.example                       # Environment variables template
├── .gitignore
├── setup.sh                           # One-command full setup
│
├── config/
│   ├── conf.yaml.example              # Minimal config template
│   └── conf.yaml.full                 # Complete working config (all options)
│
├── scripts/
│   ├── start_vtuber.sh                # Start all 6 services
│   ├── stop_vtuber.sh                 # Stop all services
│   ├── health_check.sh                # Check service status
│   ├── vtuber-chrome.sh               # Launch Chrome with virtual audio
│   ├── youtube-stream.sh              # FFmpeg RTMP stream to YouTube
│   ├── yt-chat-reader.py              # YouTube chat bridge (chat-downloader)
│   ├── yt-chat-reader2.py             # YouTube chat bridge (innertube API)
│   ├── youtube_chat_bridge.py         # YouTube chat bridge (threaded)
│   ├── youtube_chat_bridge_v2.py      # YouTube chat bridge v2
│   ├── youtube_live_bridge.py         # Full bridge (chat + Chrome + FFmpeg)
│   └── run_bilibili_live.py           # Bilibili live chat integration
│
└── docs/
    ├── ARCHITECTURE.md                # Deep dive architecture
    ├── TROUBLESHOOTING.md             # Fix common issues
    └── LLM_PROVIDERS.md               # 8+ LLM provider configs
```

---

## 🎮 Management Commands

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

# Manual Chrome launch (with virtual audio)
DISPLAY=:99 PULSE_SINK=virtual_output ~/ai-vtuber-livestream/scripts/vtuber-chrome.sh

# Manual FFmpeg stream
~/ai-vtuber-livestream/scripts/youtube-stream.sh

# Manual YouTube chat reader
python3 ~/ai-vtuber-livestream/scripts/yt-chat-reader.py YOUR_VIDEO_ID
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

See [docs/LLM_PROVIDERS.md](docs/LLM_PROVIDERS.md) for exact config.

---

## 🎤 Supported TTS Engines

| Engine | Quality | Latency | Cost | Config Key |
|--------|---------|---------|------|------------|
| **Edge TTS** | ★★★★ | Fast | Free | `edge_tts` |
| **OpenAI TTS** | ★★★★★ | Medium | Paid | `openai_tts` |
| **ElevenLabs** | ★★★★★ | Medium | Paid | `elevenlabs_tts` |
| **Fish Audio** | ★★★★ | Medium | Paid | `fish_api_tts` |
| **Piper** | ★★★ | Fast | Free | `piper_tts` |
| **Bark** | ★★★★ | Slow | Free | `bark_tts` |
| **CosyVoice** | ★★★★ | Medium | Free | `cosyvoice_tts` |
| **Coqui** | ★★★★ | Medium | Free | `coqui_tts` |
| **Sherpa ONNX** | ★★★ | Fast | Free | `sherpa_onnx_tts` |

---

## 🐛 Common Issues

**Chrome blank screen?** → `ps aux | grep Xvfb` and `echo $DISPLAY`
**No audio?** → `pactl list sinks short | grep virtual_output`
**Chat not working?** → `tail -f /tmp/yt-bridge.log`
**AI not responding?** → `tail -50 ~/Open-LLM-VTuber/logs/debug_*.log`
**Frontend not receiving responses?** → Patch frontend JS (Step 7)

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for full guide.

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

**Built with ❤️ for the VTuber community**
