addpath('matlab');
addpath('matlab/serialization');
load('data/extracted_aux_bits.txt'); % just for Pinfo testing
originalWatermark = 'Watermark_2025';
watermarkBits = textToBits(originalWatermark);
params.wavelet = 'haar'; params.dwtLevel = 2; params.blockSize = 4;
params.embedFactor = 5; params.nnzThreshold = 5; params.energyThreshold = 15.0;
params.channel = 'Cb'; params.verbose = false; params.searchRange = 8; params.redundancy = 5;
gopSize = 10;
video = loadMP4('videos/input/foreman.mp4', 30);
[wmVideo, embedLog, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params);
extractedBits = extractWatermark(wmVideo, Pinfo, gopSize, params);
L = min(length(watermarkBits), length(extractedBits));
disp(['BER: ', num2str(sum(watermarkBits(1:L) ~= extractedBits(1:L)) / L)]);
disp(['Extracted: ', bitsToText(extractedBits)]);
