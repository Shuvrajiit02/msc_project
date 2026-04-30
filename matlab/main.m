% ============================================================
%  MAIN DRIVER (UPDATED FOR FULL PIPELINE)
% ============================================================

clc; clear; close all;

addpath(genpath(pwd));

fprintf('============================================\n');
fprintf(' Hybrid Reversible Video Watermarking \n');
fprintf('============================================\n');

%% ---------------- WATERMARK ----------------
originalWatermark = 'Watermark_2025';
watermarkBits = textToBits(originalWatermark);

%% ---------------- PARAMETERS ----------------
params.wavelet         = 'haar';
params.dwtLevel        = 2;
params.blockSize       = 4;
params.embedFactor     = 5;
params.nnzThreshold    = 5;
params.energyThreshold = 15.0;
params.channel         = 'Cb';
params.verbose         = true;

params.searchRange = 8;
params.redundancy  = 5;

gopSize   = 10;
numFrames = Inf;

%% ---------------- LOAD VIDEO ----------------
videoFile = '../videos/input/foreman.mp4';

fprintf('[INFO] Loading video...\n');
video = loadMP4(videoFile, numFrames);
fprintf('[INFO] Loaded %d frames\n', length(video));

fprintf('[INFO] Watermark: %s\n', originalWatermark);

%% ---------------- EMBEDDING ----------------
fprintf('\n=== EMBEDDING PHASE ===\n');

[wmVideo, embedLog, Pinfo] = embedWatermark( ...
    video, watermarkBits, gopSize, params);

psnrEmbed = computeVideoPSNR_Cb(video, wmVideo);

%% ---------------- SAVE AUX BITS ----------------
fprintf('\n[INFO] Saving auxiliary bits for encoder...\n');

auxBits = serializePinfo(Pinfo);

fid = fopen('../data/aux_bits.txt','w');
fprintf(fid,'%d\n', auxBits);
fclose(fid);

fprintf('[INFO] Saved %d auxiliary bits\n', length(auxBits));

%% ---------------- SAVE FRAMES ----------------
fprintf('[INFO] Saving watermarked frames...\n');

saveFrames(wmVideo, '../frames/watermarked');

fprintf('[INFO] Frames saved successfully\n');

%% ============================================================
%  STOP HERE ? RUN FFmpeg + x264 + extraction externally
% ============================================================

fprintf('\n============================================\n');
fprintf(' Run external pipeline now:\n');
fprintf(' 1. FFmpeg -> frames -> input.yuv\n');
fprintf(' 2. x264 -> embed motion vectors\n');
fprintf(' 3. Extract motion vectors (C++)\n');
fprintf('============================================\n');

pause;   % Wait for user to continue after external steps

%% ---------------- LOAD EXTRACTED BITS ----------------
fprintf('\n=== EXTRACTION PHASE ===\n');

if exist('../data/extracted_aux_bits.txt', 'file') ~= 2
    error('Extracted bits file not found! Run extraction step first.');
end

auxBitsExtracted = load('../data/extracted_aux_bits.txt');

fprintf('[INFO] Loaded %d extracted bits\n', length(auxBitsExtracted));

%% ---------------- RECONSTRUCT PINFO ----------------
PinfoRecovered = deserializePinfo(auxBitsExtracted);

%% ---------------- EXTRACT WATERMARK ----------------
extractedBits = extractWatermark(wmVideo, PinfoRecovered, gopSize, params);
extractedWatermark = bitsToText(extractedBits);

%% ---------------- BER ----------------
L = min(length(watermarkBits), length(extractedBits));
ber = sum(watermarkBits(1:L) ~= extractedBits(1:L)) / L;

%% ---------------- REVERSAL ----------------
fprintf('\n=== REVERSAL PHASE ===\n');

recoveredVideo = reverseWatermark( ...
    wmVideo, gopSize, params);
fprintf('[INFO] Saving recovered frames...\n');
saveFrames(recoveredVideo, '../frames/recovered');

psnrReverse = computeVideoPSNR_Cb(video, recoveredVideo);

%% ---------------- REPORT ----------------
fprintf('\n=== FINAL REPORT ===\n');
fprintf('Original Watermark  : %s\n', originalWatermark);
fprintf('Extracted Watermark : %s\n', extractedWatermark);
fprintf('BER                 : %.6f\n', ber);

fprintf('Embedding PSNR      : %.2f dB\n', psnrEmbed);

if isinf(psnrReverse)
    fprintf('Reversal PSNR       : Infinite (Lossless)\n');
else
    fprintf('Reversal PSNR       : %.2f dB\n', psnrReverse);
end

fprintf('============================================\n');