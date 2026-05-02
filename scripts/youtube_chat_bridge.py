#!/usr/bin/env python3
"""
YouTube Live Chat → VTuber Bridge
Reads YouTube live chat and sends messages to Open-LLM-VTuber via proxy WebSocket.

Usage:
  python3 youtube_chat_bridge.py

Environment Variables:
  YOUTUBE_VIDEO_ID  - YouTube video/live ID (required)
  VTUBER_WS_URL     - VTuber WebSocket URL (default: ws://localhost:12393/proxy-ws)
"""

import os
import sys
import json
import threading
import time

try:
    from chat_downloader import ChatDownloader
except ImportError:
    print("ERROR: chat_downloader not installed. Run: pip install chat-downloader")
    sys.exit(1)

try:
    import websocket
except ImportError:
    print("ERROR: websocket-client not installed. Run: pip install websocket-client")
    sys.exit(1)

# Configuration
VIDEO_ID = os.environ.get("YOUTUBE_VIDEO_ID", "")
PROXY_URL = os.environ.get("VTUBER_WS_URL", "ws://localhost:12393/proxy-ws")

if not VIDEO_ID:
    print("ERROR: YOUTUBE_VIDEO_ID environment variable is required")
    print("Example: export YOUTUBE_VIDEO_ID=dQw4w9WgXcQ")
    sys.exit(1)

ws_conn = None
ws_ready = threading.Event()


def on_open(ws):
    global ws_conn
    ws_conn = ws
    ws_ready.set()
    print(f"✅ Connected to VTuber proxy at {PROXY_URL}")


def on_error(ws, error):
    print(f"❌ WebSocket error: {error}")


def on_close(ws, code, msg):
    print(f"🔌 WebSocket closed (code={code})")


def connect_ws():
    """Connect to VTuber proxy WebSocket in background thread."""
    while True:
        try:
            ws = websocket.WebSocketApp(
                PROXY_URL,
                on_open=on_open,
                on_message=lambda w, m: None,
                on_error=on_error,
                on_close=on_close,
            )
            ws.run_forever()
        except Exception as e:
            print(f"WebSocket connection error: {e}")
        print("Reconnecting in 5 seconds...")
        time.sleep(5)


# Start WebSocket connection in background
t = threading.Thread(target=connect_ws, daemon=True)
t.start()

print(f"⏳ Waiting for VTuber proxy connection...")
if not ws_ready.wait(timeout=30):
    print("❌ Failed to connect to VTuber proxy after 30 seconds")
    sys.exit(1)

print(f"📺 Starting YouTube chat reader for: {VIDEO_ID}")
url = f"https://www.youtube.com/watch?v={VIDEO_ID}"

try:
    chat = ChatDownloader().get_chat(url)
    message_count = 0
    for msg in chat:
        author = msg.get("author", {}).get("name", "Unknown")
        text = msg.get("message", "")
        msg_type = msg.get("message_type", "")

        if msg_type == "text_message" and text and ws_conn:
            try:
                payload = json.dumps({
                    "type": "text-input",
                    "text": f"{author}: {text}"
                })
                ws_conn.send(payload)
                message_count += 1
                print(f"[{message_count}] {author}: {text}")
            except Exception as e:
                print(f"Send error: {e}")
                break

except KeyboardInterrupt:
    print("\n👋 Stopped by user")
except Exception as e:
    print(f"Chat error: {e}")
