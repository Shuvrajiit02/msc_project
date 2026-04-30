#!/bin/bash

echo "[Quick Test Pipeline]"

set -e

ffmpeg -y -framerate 25 \
-i frames/watermarked/frame_%04d.png \
-pix_fmt yuv420p \
videos/input/input.yuv

./x264_modified/x264 \
--input-res 352x288 \
--fps 25 \
-o videos/encoded/watermarked.264 \
videos/input/input.yuv

ffmpeg -y -i videos/encoded/watermarked.264 -c copy videos/encoded/watermarked.mp4

./ffmpeg_tools/extract_mvs videos/encoded/watermarked.mp4
./ffmpeg_tools/extract_mv_histogram

echo "[Done]"
