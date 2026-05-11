% test_absolute_reversibility_debug.m
clc; clear;

addpath(genpath(pwd));

% Load a test frame
videoFile = '../videos/input/foreman.mp4';
video = loadMP4(videoFile, 2);
frame = video(1:2);

params.wavelet = 'haar';
params.blockSize = 4;
params.embedFactor = 150;
params.nnzThreshold = 0; % Lowered to force embedding
params.energyThreshold = 0; % Lowered to force embedding
params.channel = 'Cb';
params.redundancy = 1;

watermarkBits = [1]; % Just one bit

fprintf('--- Original Info ---\n');
orig_cb = double(frame(1).Cb);
fprintf('Orig range: [%f, %f]\n', min(orig_cb(:)), max(orig_cb(:)));

fprintf('--- Embedding ---\n');
% Force thresholds to very low to ensure we find a coefficient
EMBED_LO = 0;
EMBED_HI = 10000;
% I'll manually call embedWatermark or just check it
[wmVideo, embedLog, Pinfo] = embedWatermark(frame, watermarkBits, 1, params);

fprintf('Embedded %d bits\n', length(Pinfo));

fprintf('--- Reversal ---\n');
recoveredVideo = reverseWatermark(wmVideo, Pinfo, params);

% Calculate MSE
orig = double(frame(1).Cb);
wm = double(wmVideo(1).Cb);
recv = double(recoveredVideo(1).Cb);

mse_wm = mean((orig(:) - wm(:)).^2);
mse_recv = mean((orig(:) - recv(:)).^2);

fprintf('Embedding MSE: %f\n', mse_wm);
fprintf('Reversal MSE: %f\n', mse_recv);

if mse_recv == 0
    fprintf('SUCCESS: Absolute Bit-Perfect Reversibility Achieved!\n');
else
    fprintf('FAIL: MSE is not zero.\n');
    diffs = find(orig(:) ~= recv(:));
    fprintf('Number of differing pixels: %d\n', length(diffs));
    if ~isempty(diffs)
        fprintf('First diff: Orig=%f, Recv=%f\n', orig(diffs(1)), recv(diffs(1)));
    end
end
