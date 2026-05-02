#!/usr/bin/env python3
"""YouTube Live Chat → VTuber bridge"""
from chat_downloader import ChatDownloader
import websocket
import json
import threading
import time
import sys

PROXY_URL = "ws://localhost:12393/proxy-ws"
VIDEO_ID = "7V90Jx7Eygo"

ws_conn = None
ws_ready = threading.Event()

def on_open(ws):
    global ws_conn
    ws_conn = ws
    ws_ready.set()
    print("Connected to VTuber proxy")

def on_error(ws, error):
    print(f"WS error: {error}")

def on_close(ws, code, msg):
    print("WS closed")

def connect_ws():
    ws = websocket.WebSocketApp(
        PROXY_URL,
        on_open=on_open,
        on_message=lambda w, m: None,
        on_error=on_error,
        on_close=on_close,
    )
    ws.run_forever()

# Start WebSocket in background
t = threading.Thread(target=connect_ws, daemon=True)
t.start()

print("Waiting for VTuber proxy connection...")
if not ws_ready.wait(timeout=10):
    print("ERROR: Failed to connect to VTuber proxy")
    sys.exit(1)

print(f"Starting YouTube chat reader for: {VIDEO_ID}")
url = f"https://www.youtube.com/watch?v={VIDEO_ID}"

try:
    chat = ChatDownloader().get_chat(url)
    for msg in chat:
        author = msg.get("author", {}).get("name", "Unknown")
        text = msg.get("message", "")
        msg_type = msg.get("message_type", "")
        if msg_type == "text_message" and text and ws_conn:
            try:
                payload = json.dumps({"type": "text-input", "text": f"{author}: {text}"})
                ws_conn.send(payload)
                print(f"[YouTube] {author}: {text}")
            except Exception as e:
                print(f"Send error: {e}")
                break
except Exception as e:
    print(f"Chat error: {e}")
