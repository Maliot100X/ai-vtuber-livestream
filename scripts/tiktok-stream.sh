#!/bin/bash
# Stream to TikTok via RTMP
# Prerequisites: Xvfb on :99, PulseAudio virtual_output sink
# You need a TikTok stream key from TikTok LIVE Studio / Go Live
#
# Usage:
#   export TIKTOK_RTMP_URL="rtmp://..."
#   export TIKTOK_STREAM_KEY="xxxx"
#   ./tiktok-stream.sh
#
# Or edit the values below directly:

RTMP_URL="${TIKTOK_RTMP_URL:-rtmp://rtmp-push.tiktok.com}"
STREAM_KEY="${TIKTOK_STREAM_KEY:-YOUR_TIKTOK_STREAM_KEY}"

echo "🔴 Streaming to TikTok..."
echo "   RTMP: $RTMP_URL"
echo "   Key: ${STREAM_KEY:0:8}..."

ffmpeg -re \
  -f x11grab -video_size 1920x1080 -framerate 30 -i :99 \
  -f pulse -i virtual_output.monitor \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -b:v 4500k -maxrate 4500k -bufsize 9000k \
  -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 128k \
  -f flv "${RTMP_URL}/${STREAM_KEY}" 2>&1
