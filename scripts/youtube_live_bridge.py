#!/usr/bin/env python3
"""
YouTube Live Bridge for Open-LLM-VTuber
- Reads YouTube live chat comments
- Sends them to VTuber via proxy WebSocket
- Captures avatar via Xvfb + Chrome and streams to YouTube via FFmpeg

Usage:
    python3 scripts/youtube_live_bridge.py --stream-key YOUR_STREAM_KEY --video-id YOUR_VIDEO_ID

Get stream key from: YouTube Studio -> Go Live -> Stream -> Stream Key
Get video id from the live stream URL
"""

import argparse
import asyncio
import json
import subprocess
import sys
import time
import threading
import os
from loguru import logger

# WebSocket client
import websocket

PROXY_URL = "ws://localhost:12393/proxy-ws"
VTUBER_URL = "https://localhost:12394"
# For Xvfb, use HTTP since Chrome in headless mode has cert issues
VTUBER_HTTP_URL = "http://localhost:12393"


class YouTubeLiveBridge:
    def __init__(self, stream_key: str, video_id: str, rtmp_url: str = "rtmp://a.rtmp.youtube.com/live2"):
        self.stream_key = stream_key
        self.video_id = video_id
        self.rtmp_url = rtmp_url
        self.ws = None
        self.running = False
        self.chrome_process = None
        self.ffmpeg_process = None

    def on_ws_message(self, ws, message):
        """Handle messages from VTuber proxy"""
        try:
            data = json.loads(message)
            logger.debug(f"Received from VTuber: {data.get('type', 'unknown')}")
        except json.JSONDecodeError:
            pass

    def on_ws_error(self, ws, error):
        logger.error(f"WebSocket error: {error}")

    def on_ws_close(self, ws, close_status_code, close_msg):
        logger.info("WebSocket connection closed")

    def on_ws_open(self, ws):
        logger.info("Connected to VTuber proxy WebSocket")

    def connect_to_vtuber(self):
        """Connect to VTuber proxy WebSocket"""
        try:
            self.ws = websocket.WebSocketApp(
                PROXY_URL,
                on_message=self.on_ws_message,
                on_error=self.on_ws_error,
                on_close=self.on_ws_close,
                on_open=self.on_ws_open
            )
            ws_thread = threading.Thread(target=self.ws.run_forever, daemon=True)
            ws_thread.start()
            time.sleep(2)  # Wait for connection
            return self.ws.sock and self.ws.sock.connected
        except Exception as e:
            logger.error(f"Failed to connect to VTuber proxy: {e}")
            return False

    def send_comment_to_vtuber(self, username: str, message: str):
        """Send a YouTube chat comment to the VTuber"""
        if not self.ws or not self.ws.sock or not self.ws.sock.connected:
            logger.warning("Not connected to VTuber proxy")
            return

        # Format as user input text
        text = f"{username}: {message}"
        payload = json.dumps({
            "type": "text-input",
            "text": text
        })
        try:
            self.ws.send(payload)
            logger.info(f"Sent to VTuber: {text}")
        except Exception as e:
            logger.error(f"Failed to send message: {e}")

    def start_chrome(self):
        """Launch Chrome in Xvfb to render the Live2D avatar"""
        logger.info("Starting Chrome on virtual display...")
        self.chrome_process = subprocess.Popen([
            "xvfb-run", "-a", "-s", "-screen 0 1920x1080x24",
            "google-chrome",
            "--no-sandbox",
            "--disable-gpu",
            "--disable-software-rasterizer",
            "--window-size=1920,1080",
            "--window-position=0,0",
            "--kiosk",
            "--autoplay-policy=no-user-gesture-required",
            "--ignore-certificate-errors",
            VTUBER_HTTP_URL
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        logger.info(f"Chrome started (PID: {self.chrome_process.pid})")
        time.sleep(5)  # Wait for Chrome to load

    def start_ffmpeg_stream(self):
        """Capture Xvfb display and stream to YouTube via RTMP"""
        rtmp_full = f"{self.rtmp_url}/{self.stream_key}"
        logger.info(f"Starting FFmpeg stream to YouTube...")

        self.ffmpeg_process = subprocess.Popen([
            "ffmpeg",
            "-f", "x11grab",
            "-video_size", "1920x1080",
            "-framerate", "30",
            "-i", ":99",  # Default Xvfb display
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-tune", "zerolatency",
            "-b:v", "4500k",
            "-maxrate", "4500k",
            "-bufsize", "9000k",
            "-pix_fmt", "yuv420p",
            "-g", "60",
            "-f", "flv",
            rtmp_full
        ], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        logger.info(f"FFmpeg streaming started (PID: {self.ffmpeg_process.pid})")

    def run_chat_reader(self):
        """Read YouTube live chat and forward to VTuber"""
        logger.info(f"Starting YouTube chat reader for video: {self.video_id}")
        try:
            from chat_downloader import ChatDownloader
            url = f"https://www.youtube.com/watch?v={self.video_id}"
            chat = ChatDownloader().get_chat(url)

            for message in chat:
                if not self.running:
                    break

                author = message.get("author", {}).get("name", "Unknown")
                text = message.get("message", "")
                msg_type = message.get("message_type", "")

                if msg_type == "text_message" and text:
                    logger.info(f"[YouTube] {author}: {text}")
                    self.send_comment_to_vtuber(author, text)

        except KeyboardInterrupt:
            logger.info("Chat reader stopped")
        except Exception as e:
            logger.error(f"Chat reader error: {e}")

    def run(self):
        """Main run loop"""
        self.running = True

        # 1. Connect to VTuber proxy
        logger.info("Step 1: Connecting to VTuber proxy...")
        if not self.connect_to_vtuber():
            logger.error("Cannot connect to VTuber proxy. Is the server running?")
            return

        # 2. Start Chrome with Xvfb
        logger.info("Step 2: Starting Chrome + Xvfb...")
        self.start_chrome()

        # 3. Start FFmpeg stream to YouTube
        logger.info("Step 3: Starting FFmpeg stream to YouTube...")
        self.start_ffmpeg_stream()

        # 4. Run chat reader (blocking)
        logger.info("Step 4: Reading YouTube live chat...")
        try:
            self.run_chat_reader()
        except KeyboardInterrupt:
            pass
        finally:
            self.cleanup()

    def cleanup(self):
        """Clean up processes"""
        self.running = False
        logger.info("Cleaning up...")
        if self.chrome_process:
            self.chrome_process.terminate()
        if self.ffmpeg_process:
            self.ffmpeg_process.terminate()
        if self.ws:
            self.ws.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="YouTube Live Bridge for Open-LLM-VTuber")
    parser.add_argument("--stream-key", required=True, help="YouTube RTMP stream key")
    parser.add_argument("--video-id", required=True, help="YouTube live video ID")
    parser.add_argument("--rtmp-url", default="rtmp://a.rtmp.youtube.com/live2", help="RTMP server URL")

    args = parser.parse_args()

    bridge = YouTubeLiveBridge(
        stream_key=args.stream_key,
        video_id=args.video_id,
        rtmp_url=args.rtmp_url
    )
    bridge.run()
