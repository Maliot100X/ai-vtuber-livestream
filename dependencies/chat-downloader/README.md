# chat-downloader — YouTube Live Chat Scraper

**GitHub:** https://github.com/xenova/chat-downloader
**What it does:** Downloads live chat messages from YouTube, Twitch, and other platforms

## What We Use It For
- Reading YouTube live chat messages in real-time
- Forwarding chat messages to the VTuber via WebSocket
- Primary method for YouTube chat integration

## Installation
```bash
pip install chat-downloader
```

## Usage
```python
from chat_downloader import ChatDownloader

chat = ChatDownloader().get_chat("https://www.youtube.com/watch?v=VIDEO_ID")
for message in chat:
    author = message.get("author", {}).get("name", "Unknown")
    text = message.get("message", "")
    print(f"{author}: {text}")
```

## Our Scripts Using This
- `scripts/yt-chat-reader.py` — Simple chat reader
- `scripts/youtube_chat_bridge.py` — Threaded bridge with reconnection
- `scripts/youtube_live_bridge.py` — Full bridge (chat + Chrome + FFmpeg)

## Alternative Methods
If chat-downloader doesn't work, we also have:
- `scripts/yt-chat-reader2.py` — Uses YouTube's innertube API directly (no dependency)
