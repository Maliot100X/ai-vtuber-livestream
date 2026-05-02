# Open-LLM-VTuber

**GitHub:** https://github.com/Open-LLM-VTuber/Open-LLM-VTuber
**Stars:** 7,300+
**What it does:** Core VTuber framework — Python server, Live2D rendering, TTS/ASR/LLM integration, WebSocket proxy

## What We Use It For
- Python backend server (port 12393)
- Proxy WebSocket (port 12394) for broadcasting AI responses
- Live2D anime avatar rendering
- Edge TTS voice synthesis
- Sherpa ONNX speech recognition
- MCP (Model Context Protocol) tool integration

## Installation
```bash
cd ~
git clone https://github.com/Open-LLM-VTuber/Open-LLM-VTuber.git
cd Open-LLM-VTuber

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install additional packages we need
pip install chat-downloader websocket-client edge-tts loguru requests sherpa-onnx
```

## Key Files
- `conf.yaml` — Main configuration (see our `config/conf.yaml.full`)
- `main.py` — Server entry point
- `frontend/assets/main-*.js` — Frontend JS (needs proxy-ws patch)
- `scripts/` — YouTube bridge scripts
- `characters/` — Character persona configs

## Ports
- `12393` — HTTP server (HTTPS with self-signed cert)
- `12394` — Proxy WebSocket (for live streaming clients)

## Patches Applied
We patched the frontend JS to connect to `/proxy-ws` instead of `/client-ws`:
```bash
cd ~/Open-LLM-VTuber
FRONTEND_JS=$(ls frontend/assets/main-*.js)
sed -i 's|/client-ws|/proxy-ws|g' "$FRONTEND_JS"
```

## Our Config
See `../../config/conf.yaml.full` for our complete working configuration.

## Submodules
- blivedm (Bilibili live chat) — see `../blivedm/`
