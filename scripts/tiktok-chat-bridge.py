#!/usr/bin/env python3
"""
TikTok Live Chat → VTuber Bridge
Reads TikTok live chat and sends messages to Open-LLM-VTuber via proxy WebSocket.

Usage:
  python3 tiktok-chat-bridge.py YOUR_TIKTOK_USERNAME

Example:
  python3 tiktok-chat-bridge.py solxhunter

Requirements:
  pip install TikTokLive websocket-client

No API key or paid service needed — uses free open-source TikTokLive library.
GitHub: https://github.com/isaackogan/TikTokLive
"""

import asyncio
import json
import sys
import os

try:
    from TikTokLive import TikTokLiveClient
    from TikTokLive.events import ConnectEvent, CommentEvent, GiftEvent, LikeEvent
except ImportError:
    print("ERROR: TikTokLive not installed. Run:")
    print("  cd ~/Open-LLM-VTuber && .venv/bin/python -m pip install TikTokLive")
    sys.exit(1)

try:
    import websocket
except ImportError:
    print("ERROR: websocket-client not installed. Run:")
    print("  pip install websocket-client")
    sys.exit(1)

# Configuration
PROXY_URL = os.environ.get("VTUBER_WS_URL", "ws://localhost:12393/proxy-ws")

if len(sys.argv) < 2:
    print(f"Usage: {sys.argv[0]} TIKTOK_USERNAME")
    print(f"Example: {sys.argv[0]} solxhunter")
    sys.exit(1)

TIKTOK_USERNAME = sys.argv[1].lstrip("@")
print(f"🎭 TikTok → VTuber Bridge")
print(f"   TikTok: @{TIKTOK_USERNAME}")
print(f"   VTuber: {PROXY_URL}")
print()

# Create TikTok client
client = TikTokLiveClient(unique_id=TIKTOK_USERNAME)

# WebSocket connection to VTuber
ws_conn = None

def connect_vtuber():
    """Connect to VTuber proxy WebSocket."""
    global ws_conn
    try:
        ws_conn = websocket.create_connection(PROXY_URL, timeout=10)
        print(f"✅ Connected to VTuber proxy at {PROXY_URL}")
        return True
    except Exception as e:
        print(f"❌ Failed to connect to VTuber: {e}")
        return False

def send_to_vtuber(text: str):
    """Send a message to the VTuber via WebSocket."""
    global ws_conn
    if ws_conn is None:
        if not connect_vtuber():
            return
    try:
        payload = json.dumps({"type": "text-input", "text": text})
        ws_conn.send(payload)
    except Exception as e:
        print(f"Send error: {e}, reconnecting...")
        ws_conn = None
        connect_vtuber()
        if ws_conn:
            try:
                ws_conn.send(json.dumps({"type": "text-input", "text": text}))
            except:
                pass

@client.on(ConnectEvent)
async def on_connect(event: ConnectEvent):
    print(f"✅ Connected to TikTok LIVE: @{event.unique_id} (Room ID: {client.room_id})")

@client.on(CommentEvent)
async def on_comment(event: CommentEvent):
    author = event.user.nickname
    comment = event.comment
    print(f"💬 {author}: {comment}")
    send_to_vtuber(f"{author}: {comment}")

@client.on(GiftEvent)
async def on_gift(event: GiftEvent):
    author = event.user.nickname
    gift = event.gift.name
    count = event.gift.count if hasattr(event.gift, 'count') else 1
    print(f"🎁 {author} sent {gift} x{count}")
    send_to_vtuber(f"{author} sent a gift: {gift}!")

@client.on(LikeEvent)
async def on_like(event: LikeEvent):
    author = event.user.nickname
    count = event.count if hasattr(event, 'count') else 1
    print(f"❤️ {author} liked x{count}")

if __name__ == "__main__":
    # Connect to VTuber first
    connect_vtuber()

    print(f"🚀 Starting TikTok LIVE reader for @{TIKTOK_USERNAME}...")
    print(f"   Waiting for the stream to be live...")
    print()

    try:
        client.run()
    except KeyboardInterrupt:
        print("\n👋 Stopped by user")
    except Exception as e:
        print(f"Error: {e}")
        print("\nPossible reasons:")
        print("  - User is not currently live")
        print("  - Username is incorrect")
        print("  - TikTok is blocking the connection (try with a proxy)")
