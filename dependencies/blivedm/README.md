# blivedm — Bilibili Live Chat

**GitHub:** https://github.com/Open-LLM-VTuber/blivedm
**What it does:** Reads Bilibili live stream chat messages in real-time

## What We Use It For
- Bilibili live chat integration (alternative to YouTube)
- Reads danmaku (bullet comments) from Bilibili live rooms
- Sends messages to VTuber via proxy WebSocket

## Installation
```bash
# Usually comes as a submodule of Open-LLM-VTuber
cd ~/Open-LLM-VTuber
git submodule update --init --recursive

# Or clone standalone
git clone https://github.com/Open-LLM-VTuber/blivedm.git
cd blivedm
pip install -r requirements.txt
```

## Key Files
- `blivedm/` — Core library
- `sample.py` — Example usage
- `open_live_sample.py` — Open live example

## Configuration
In `conf.yaml`:
```yaml
live_config:
  bilibili_live:
    room_ids: [1991478060]  # Your Bilibili room ID
    sessdata: ""            # Optional: Bilibili cookie
```

## Usage
```bash
cd ~/Open-LLM-VTuber
source .venv/bin/activate
python scripts/run_bilibili_live.py
```
