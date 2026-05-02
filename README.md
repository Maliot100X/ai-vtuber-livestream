# 🎭 AI VTuber Live Stream

> **Fully automated AI VTuber that livestreams on YouTube, reads chat in real-time, and responds with voice — powered by Open-LLM-VTuber.**

## 🔴 Live Demo

**Watch it live:** [https://youtube.com/watch?v=7V90Jx7Eygo](https://youtube.com/watch?v=7V90Jx7Eygo)

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

---

## 📦 All Dependencies (with full setup for each)

Each dependency has its own folder with README, install script, and config files:

| # | Dependency | Folder | GitHub | What We Use It For |
|---|-----------|--------|--------|-------------------|
| 1 | **Open-LLM-VTuber** | [`dependencies/open-llm-vtuber/`](dependencies/open-llm-vtuber/) | [GitHub](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber) | Core VTuber framework (server, frontend, Live2D, proxy) |
| 2 | **blivedm** | [`dependencies/blivedm/`](dependencies/blivedm/) | [GitHub](https://github.com/Open-LLM-VTuber/blivedm) | Bilibili live chat integration |
| 3 | **edge-tts** | [`dependencies/edge-tts/`](dependencies/edge-tts/) | [GitHub](https://github.com/rany2/edge-tts) | Free Microsoft Edge text-to-speech |
| 4 | **chat-downloader** | [`dependencies/chat-downloader/`](dependencies/chat-downloader/) | [GitHub](https://github.com/xenova/chat-downloader) | YouTube live chat scraper |
| 5 | **websocket-client** | [`dependencies/websocket-client/`](dependencies/websocket-client/) | [GitHub](https://github.com/websocket-client/websocket-client) | Python WebSocket client |
| 6 | **Google Chrome** | [`dependencies/chrome/`](dependencies/chrome/) | [Download](https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb) | Live2D rendering + audio playback |
| 7 | **FFmpeg** | [`dependencies/ffmpeg/`](dependencies/ffmpeg/) | [ffmpeg.org](https://ffmpeg.org) | Screen + audio capture → RTMP stream |
| 8 | **PulseAudio** | [`dependencies/pulseaudio/`](dependencies/pulseaudio/) | [freedesktop.org](https://www.freedesktop.org/wiki/Software/PulseAudio/) | Virtual audio sink for routing |
| 9 | **Xvfb** | [`dependencies/xvfb/`](dependencies/xvfb/) | [X.Org](https://www.x.org/) | Virtual X11 display for headless Chrome |
| 10 | **sherpa-onnx** | [`dependencies/sherpa-onnx/`](dependencies/sherpa-onnx/) | [GitHub](https://github.com/k2-fsa/sherpa-onnx) | Local speech recognition (ASR) |

### Python Packages
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

Or install each dependency manually from its folder above.

---

## 📋 Prerequisites

- **AWS EC2** — Ubuntu 24.04+, t3.large (2 vCPU, 8GB RAM)
- **Security Group** — Open ports `12393`, `12394`, `22`
- **YouTube Channel** — Live streaming enabled
- **LLM API Key** — Any OpenAI-compatible provider

---

## 🔧 Manual Setup (Step by Step)

### Step 1: System Dependencies
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv python3-dev \
  git curl wget unzip build-essential \
  xvfb pulseaudio ffmpeg \
  libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 \
  libgbm1 libasound2 libxshmfence1 libgtk-3-0
```

### Step 2: Install Chrome
```bash
# See: dependencies/chrome/
wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i /tmp/chrome.deb || sudo apt-get install -f -y
```

### Step 3: Install Open-LLM-VTuber
```bash
# See: dependencies/open-llm-vtuber/
cd ~
git clone https://github.com/Open-LLM-VTuber/Open-LLM-VTuber.git
cd Open-LLM-VTuber
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pip install chat-downloader websocket-client edge-tts loguru requests sherpa-onnx
```

### Step 4: Configure
```bash
cp ~/ai-vtuber-livestream/config/conf.yaml.full ~/Open-LLM-VTuber/conf.yaml
cp ~/ai-vtuber-livestream/.env.example ~/Open-LLM-VTuber/.env
nano ~/Open-LLM-VTuber/.env  # Add your API keys
```

### Step 5: Patch Frontend
```bash
# See: patches/frontend-proxy-ws-fix.md
cd ~/Open-LLM-VTuber
FRONTEND_JS=$(ls frontend/assets/main-*.js)
sed -i 's|/client-ws|/proxy-ws|g' "$FRONTEND_JS"
```

### Step 6: Start Everything
```bash
~/ai-vtuber-livestream/scripts/start_vtuber.sh
```

---

## 📁 Project Structure

```
ai-vtuber-livestream/
├── README.md
├── LICENSE
├── .env.example
├── .gitignore
├── setup.sh
│
├── config/
│   ├── conf.yaml.example              # Minimal config template
│   └── conf.yaml.full                 # Complete 504-line config
│
├── scripts/
│   ├── start_vtuber.sh                # Start all services
│   ├── stop_vtuber.sh                 # Stop all services
│   ├── health_check.sh                # Status check
│   ├── vtuber-chrome.sh               # Chrome launch
│   ├── youtube-stream.sh              # FFmpeg RTMP stream
│   ├── yt-chat-reader.py              # Chat bridge (Method 1)
│   ├── yt-chat-reader2.py             # Chat bridge (Method 2)
│   ├── youtube_chat_bridge.py         # Threaded bridge
│   ├── youtube_chat_bridge_v2.py      # Bridge v2
│   ├── youtube_live_bridge.py         # Full bridge
│   └── run_bilibili_live.py           # Bilibili integration
│
├── dependencies/                      # ← FULL SETUP FOR EACH DEPENDENCY
│   ├── open-llm-vtuber/               # Core framework
│   │   ├── README.md
│   │   ├── install.sh
│   │   └── conf.yaml.working          # Our actual working config
│   ├── blivedm/                       # Bilibili live chat
│   │   └── README.md
│   ├── edge-tts/                      # Free TTS
│   │   ├── README.md
│   │   └── install.sh
│   ├── chat-downloader/               # YouTube chat scraper
│   │   ├── README.md
│   │   ├── install.sh
│   │   ├── yt-chat-reader.py          # Our working script
│   │   └── yt-chat-reader2.py         # Alternative method
│   ├── websocket-client/              # WebSocket client
│   │   ├── README.md
│   │   └── install.sh
│   ├── chrome/                        # Browser rendering
│   │   ├── README.md
│   │   ├── install.sh
│   │   └── launch.sh                  # Our Chrome launch script
│   ├── ffmpeg/                        # RTMP streaming
│   │   ├── README.md
│   │   ├── install.sh
│   │   └── stream.sh                  # Our FFmpeg stream script
│   ├── pulseaudio/                    # Virtual audio
│   │   ├── README.md
│   │   └── install.sh
│   ├── xvfb/                          # Virtual display
│   │   ├── README.md
│   │   └── install.sh
│   └── sherpa-onnx/                   # Local ASR
│       ├── README.md
│       └── install.sh
│
├── patches/
│   └── frontend-proxy-ws-fix.md       # Frontend patch instructions
│
└── docs/
    ├── ARCHITECTURE.md                # Deep dive
    ├── TROUBLESHOOTING.md             # Common fixes
    └── LLM_PROVIDERS.md               # 8+ providers
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
```

---

## 🤖 Supported LLM Providers

| Provider | Config Key | Example Model |
|----------|-----------|---------------|
| Groq | `groq_llm` | `llama-3.3-70b-versatile` |
| DeepSeek | `deepseek_llm` | `deepseek-chat` |
| OpenAI | `openai_llm` | `gpt-4o-mini` |
| OpenRouter | `openai_compatible_llm` | `anthropic/claude-3.5-sonnet` |
| Gemini | `gemini_llm` | `gemini-2.0-flash-exp` |
| Claude | `claude_llm` | `claude-3-haiku` |
| Ollama | `ollama_llm` | `llama3.2` |

See [docs/LLM_PROVIDERS.md](docs/LLM_PROVIDERS.md)

---

## 📄 License

MIT — see [LICENSE](LICENSE)

---

**Built with ❤️ for the VTuber community**
