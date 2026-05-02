#!/bin/bash
# Health check for all AI VTuber services
echo "🔍 AI VTuber Health Check"
echo "========================="

check() {
  if pgrep -f "$1" > /dev/null 2>&1; then
    echo "  ✅ $2"
  else
    echo "  ❌ $2 (NOT running)"
  fi
}

check "Xvfb" "Virtual Display (Xvfb)"
check "pulseaudio" "PulseAudio"
check "python main.py" "VTuber Server"
check "chrome.*vtuber" "Chrome Browser"
check "youtube_chat_bridge" "YouTube Chat Bridge"
check "ffmpeg.*youtube" "FFmpeg Stream"

echo ""
echo "🌐 Ports:"
ss -tlnp 2>/dev/null | grep -E '12393|12394' || echo "  (no VTuber ports listening)"

echo ""
echo "📊 Resource Usage:"
echo "  CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
echo "  RAM: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
echo "  Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
