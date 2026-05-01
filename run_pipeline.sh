#!/bin/bash

echo "============================================"
echo " Hybrid Watermarking Pipeline"
echo "============================================"

# Stop on error
set -e

# -----------------------------
# Step 1: Frames → YUV
# -----------------------------
echo "[1/4] Converting frames to YUV..."

ffmpeg -y -framerate 25 \
-i frames/watermarked/frame_%04d.png \
-pix_fmt yuv420p \
videos/input/input.yuv

echo "[✓] YUV created"

# -----------------------------
# Step 2: x264 Encoding
# -----------------------------
echo "[2/4] Running x264 (embedding MVs)..."

cd x264_modified
./x264 \
--input-res 352x288 \
--fps 25 \
--ref 1 \
--partitions none \
--bframes 0 \
--weightp 0 \
--me dia \
--subme 0 \
--no-cabac \
--no-fast-pskip \
--trellis 0 \
-o ../videos/encoded/watermarked.264 \
../videos/input/input.yuv
cd ..

echo "[✓] x264 encoding done"

# -----------------------------
# Step 3: Convert to MP4
# -----------------------------
echo "[3/4] Converting .264 → .mp4..."

ffmpeg -y \
-i videos/encoded/watermarked.264 \
-c copy \
videos/encoded/watermarked.mp4

echo "[✓] MP4 created"

# -----------------------------
# Step 4: Extract Motion Vectors
# -----------------------------
echo "[4/4] Extracting motion vectors..."

./ffmpeg_tools/extract_mvs videos/encoded/watermarked.mp4
./ffmpeg_tools/extract_mv_histogram

echo "[✓] Extraction complete"

echo "============================================"
echo " Pipeline Finished Successfully"
echo "============================================"
