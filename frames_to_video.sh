#!/bin/bash

echo "[INFO] Converting recovered frames to video..."

ffmpeg -y -framerate 25 \
-i frames/recovered/frame_%04d.png \
-pix_fmt yuv420p \
videos/encoded/recovered.mp4

echo "[INFO] Done → videos/encoded/recovered.mp4"