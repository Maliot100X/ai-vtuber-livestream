#!/usr/bin/env python3
"""
YouTube Live Chat → VTuber WebSocket forwarder
Uses YouTube's innertube API directly.
"""
import json
import time
import re
import sys
import requests
import websocket

PROXY_URL = "ws://localhost:12393/proxy-ws"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Content-Type": "application/json",
    "Origin": "https://www.youtube.com",
}

def log(msg):
    print(msg, flush=True)

def get_continuation_token(video_id):
    url = f"https://www.youtube.com/watch?v={video_id}"
    resp = requests.get(url, headers={"User-Agent": HEADERS["User-Agent"]}, timeout=10)
    matches = re.findall(r'"continuation":"([^"]{20,})"', resp.text)
    if not matches:
        raise RuntimeError("No continuation token found - is the stream live?")
    return matches[0]

def fetch_chat(token):
    payload = {
        "context": {
            "client": {
                "clientName": "WEB",
                "clientVersion": "2.20240101.00.00",
                "hl": "en",
                "gl": "US",
            }
        },
        "continuation": token,
    }
    resp = requests.post(
        "https://www.youtube.com/youtubei/v1/live_chat/get_live_chat?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8",
        headers=HEADERS, json=payload, timeout=10,
    )
    return resp.json()

def extract_messages(data):
    messages = []
    try:
        actions = data.get("continuationContents", {}).get("liveChatContinuation", {}).get("actions", [])
        for action in actions:
            item = action.get("addChatItemAction", {}).get("item", {})
            renderer = item.get("liveChatTextMessageRenderer", {})
            if renderer:
                author = renderer.get("authorName", {}).get("simpleText", "Unknown")
                runs = renderer.get("message", {}).get("runs", [])
                text = "".join(run.get("text", "") for run in runs)
                if text:
                    messages.append({"author": author, "text": text})
    except Exception as e:
        log(f"Parse error: {e}")
    return messages

def get_next_continuation(data):
    try:
        cont = data.get("continuationContents", {}).get("liveChatContinuation", {})
        for c in cont.get("continuations", []):
            if "timedContinuationData" in c:
                return c["timedContinuationData"].get("continuation")
            if "invalidationContinuationData" in c:
                return c["invalidationContinuationData"].get("continuation")
    except:
        pass
    return None

def main(video_id):
    log(f"Starting chat reader for: {video_id}")
    
    ws = websocket.create_connection(PROXY_URL, timeout=10)
    log(f"Connected to VTuber proxy at {PROXY_URL}")
    
    token = get_continuation_token(video_id)
    log("Got continuation token, polling chat...")
    
    seen = set()
    
    while True:
        try:
            data = fetch_chat(token)
            messages = extract_messages(data)
            
            for msg in messages:
                msg_id = f"{msg['author']}:{msg['text']}"
                if msg_id not in seen:
                    seen.add(msg_id)
                    text = f"{msg['author']}: {msg['text']}"
                    payload = json.dumps({"type": "text-input", "text": text})
                    try:
                        ws.send(payload)
                        log(f"[YT] {text}")
                    except Exception as e:
                        log(f"WS error: {e}, reconnecting...")
                        try:
                            ws = websocket.create_connection(PROXY_URL, timeout=10)
                            ws.send(payload)
                        except:
                            log("Reconnect failed")
            
            if len(seen) > 5000:
                seen = set(list(seen)[-2000:])
            
            next_token = get_next_continuation(data)
            if next_token:
                token = next_token
            
            time.sleep(3)
            
        except KeyboardInterrupt:
            log("Stopping...")
            break
        except Exception as e:
            log(f"Error: {e}")
            time.sleep(5)
    
    ws.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} VIDEO_ID")
        sys.exit(1)
    main(sys.argv[1])
