#!/bin/bash
# Stop all AI VTuber services
echo "🛑 Stopping AI VTuber Live Stream..."

for service in vtuber-server chrome-vtuber yt-bridge ffmpeg-stream; do
  pidfile="/tmp/${service}.pid"
  if [ -f "$pidfile" ]; then
    pid=$(cat "$pidfile")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
      echo "  Stopped: $service (PID $pid)"
    fi
    rm -f "$pidfile"
  fi
done

# Kill any remaining
pkill -f "python main.py" 2>/dev/null || true
pkill -f "youtube_chat_bridge" 2>/dev/null || true
pkill -f "ffmpeg.*youtube" 2>/dev/null || true
pkill -f "chrome.*vtuber" 2>/dev/null || true

echo "✅ All services stopped."
