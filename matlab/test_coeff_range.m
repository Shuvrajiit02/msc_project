% test_absolute_reversibility_debug_v2.m
clc; clear;

addpath(genpath(pwd));

% Load a test frame
videoFile = '../videos/input/foreman.mp4';
video = loadMP4(videoFile, 1);
frame = video(1);

params.wavelet = 'haar';
params.blockSize = 4;
params.embedFactor = 150;
params.nnzThreshold = 0;
params.energyThreshold = 0;
params.channel = 'Cb';
params.redundancy = 1;

fprintf('--- Coefficient Range Check ---\n');
channel = double(frame.Cb);
ls = liftwave(params.wavelet, 'Int2Int');
[LL1, LH1, HL1, HH1] = lwt2(channel, ls);
[LL2, LH2, HL2, HH2] = lwt2(LL1, ls);

blk = params.blockSize;
[h, w] = size(LH2);
max_val = 0;
for i = 1:blk:h-blk+1
    for j = 1:blk:w-blk+1
        block = intdct4(LH2(i:i+blk-1, j:j+blk-1));
        midMask = [0 1 1 0; 1 1 1 0; 1 1 0 0; 0 0 0 0];
        midCoeffs = block(midMask == 1);
        max_val = max(max_val, max(abs(midCoeffs)));
    end
end
fprintf('Max abs mid-coeff in LH2: %f\n', max_val);

% Force thresholds to 0 to ensure we embed
% But I must update embedWatermark.m to use them
% For now I'll just see why it's 0.
