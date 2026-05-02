#!/usr/bin/env python3
"""
YouTube Chat → VTuber WebSocket forwarder
Reads YouTube live chat and sends messages to Open-LLM-VTuber via proxy WebSocket.
Chrome + FFmpeg are already running separately.
"""
import json
import time
import threading
import sys
from loguru import logger

import websocket

PROXY_URL = "ws://localhost:12393/proxy-ws"

def main(video_id: str):
    url = f"https://www.youtube.com/watch?v={video_id}"
    logger.info(f"Connecting to VTuber proxy at {PROXY_URL}...")
    
    ws = websocket.create_connection(PROXY_URL, timeout=10)
    logger.info("Connected to VTuber proxy WebSocket")
    
    logger.info(f"Starting YouTube chat reader for: {url}")
    from chat_downloader import ChatDownloader
    
    chat = ChatDownloader().get_chat(url)
    logger.info("Chat stream connected! Reading messages...")
    
    for message in chat:
        author = message.get("author", {}).get("name", "Unknown")
        text = message.get("message", "")
        msg_type = message.get("message_type", "")
        
        if msg_type == "text_message" and text:
            payload = json.dumps({
                "type": "text-input",
                "text": f"{author}: {text}"
            })
            try:
                ws.send(payload)
                logger.info(f"[YouTube] {author}: {text}")
            except Exception as e:
                logger.error(f"Failed to send: {e}")
                # Reconnect
                try:
                    ws = websocket.create_connection(PROXY_URL, timeout=10)
                    ws.send(payload)
                except:
                    logger.error("Reconnect failed")
    
    ws.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} VIDEO_ID")
        sys.exit(1)
    main(sys.argv[1])
