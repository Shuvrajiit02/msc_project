# ==========================================
# Makefile for ffmpeg_tools
# ==========================================

CXX = g++
CXXFLAGS = -std=c++11 -Wall

# FFmpeg libraries
LIBS = -lavformat -lavcodec -lavutil

# Targets
TARGETS = extract_mvs extract_mv_histogram

# Default rule
all: $(TARGETS)

# Build extract_mvs
extract_mvs: extract_mvs.cpp
	$(CXX) $(CXXFLAGS) extract_mvs.cpp -o extract_mvs $(LIBS)

# Build extract_mv_histogram
extract_mv_histogram: extract_mv_histogram.cpp
	$(CXX) $(CXXFLAGS) extract_mv_histogram.cpp -o extract_mv_histogram

# Clean build files
clean:
	rm -f $(TARGETS)