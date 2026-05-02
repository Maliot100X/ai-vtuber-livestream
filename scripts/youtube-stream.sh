#!/bin/bash
# YouTube RTMP stream from display :99
# Stream key: 8mcv-w2rh-01vr-bum1-8rh5
# DO NOT MODIFY without testing
exec ffmpeg -re \
  -f x11grab -video_size 1920x1080 -framerate 30 -i :99 \
  -f lavfi -i anullsrc=r=44100:cl=stereo \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -b:v 4500k -maxrate 4500k -bufsize 9000k \
  -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 128k \
  -f flv "rtmp://a.rtmp.youtube.com/live2/8mcv-w2rh-01vr-bum1-8rh5" 2>&1
