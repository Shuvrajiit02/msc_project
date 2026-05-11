% test_absolute_reversibility.m
clc; clear;

addpath(genpath(pwd));

% Load a test frame
videoFile = '../videos/input/foreman.mp4';
video = loadMP4(videoFile, 10);
frame = video(1);

params.wavelet = 'haar';
params.blockSize = 4;
params.embedFactor = 150;
params.nnzThreshold = 1;
params.energyThreshold = 0.5;
params.channel = 'Cb';
params.redundancy = 5;

watermarkBits = randi([0 1], 1, 100);

fprintf('--- Embedding ---\n');
[wmVideo, embedLog, Pinfo] = embedWatermark(video(1), watermarkBits, 1, params);

fprintf('--- Reversal ---\n');
recoveredVideo = reverseWatermark(wmVideo, Pinfo, params);

% Calculate MSE
orig = double(video(1).Cb);
recv = double(recoveredVideo(1).Cb);

mse = mean((orig(:) - recv(:)).^2);
psnr = 10 * log10(255^2 / mse);

fprintf('Result MSE: %f\n', mse);
fprintf('Result PSNR: %f dB\n', psnr);

if mse == 0
    fprintf('SUCCESS: Absolute Bit-Perfect Reversibility Achieved!\n');
else
    fprintf('FAIL: MSE is not zero. MSE = %e\n', mse);
end
