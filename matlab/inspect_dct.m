clc; clear;
addpath(genpath(pwd));

originalWatermark = 'Watermark_2025';
watermarkBits     = textToBits(originalWatermark);

params.wavelet         = 'haar';
params.dwtLevel        = 2;
params.blockSize       = 4;
params.embedFactor     = 150;
params.nnzThreshold    = 1;
params.energyThreshold = 0.5;
params.channel         = 'Cb';
params.verbose         = false;
params.searchRange     = 8;
params.redundancy      = 5;

gopSize = 10;
video = loadMP4('../videos/input/foreman.mp4', 50);

[wmVideo, ~, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params);

for p = 1:10
    fprintf('Entry %d (bitIdx=%d): Frame=%d, Block=%d, Coeff=%d\n', ...
        p, Pinfo(p).bitIdx, Pinfo(p).iFrame, Pinfo(p).block, Pinfo(p).coeffIdx);
end
