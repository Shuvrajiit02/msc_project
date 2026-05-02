% debug_embed.m - Run this BEFORE main.m to verify embedding works end-to-end
% without the H.264 channel. If BER == 0 here, the DCT layer is correct.

clc; clear;
addpath(genpath(pwd));

originalWatermark = 'Watermark_2025';
watermarkBits     = textToBits(originalWatermark);

params.wavelet         = 'haar';
params.dwtLevel        = 2;
params.blockSize       = 4;
params.embedFactor     = 15;
params.nnzThreshold    = 1;
params.energyThreshold = 0.5;
params.channel         = 'Cb';
params.verbose         = false;
params.searchRange     = 8;
params.redundancy      = 5;

gopSize = 10;

fprintf('Loading video...\n');
video = loadMP4('../videos/input/foreman.mp4', 50);
fprintf('Loaded %d frames.\n', length(video));

fprintf('Embedding...\n');
[wmVideo, ~, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params);

fprintf('Pinfo entries: %d\n', length(Pinfo));

if isempty(Pinfo)
    fprintf('ERROR: No Pinfo generated! Embedding failed.\n');
    fprintf('Check that Cb coefficients exist in range (0.1, 0.2].\n');
    
    % Diagnostic: show coefficient distribution
    channel = double(video(1).Cb);
    [LL1,~,~,~] = dwt2(channel,'haar');
    [~,LH2,~,~] = dwt2(LL1,'haar');
    dctBand = dct2(LH2);
    midMask = [0 1 1 0; 1 1 1 0; 1 1 0 0; 0 0 0 0];
    idx = find(midMask == 1);
    all_mid_coeffs = [];
    blk = 4;
    [h,w] = size(dctBand);
    for ii = 1:blk:h-blk+1
        for jj = 1:blk:w-blk+1
            blk_data = dctBand(ii:ii+blk-1, jj:jj+blk-1);
            all_mid_coeffs = [all_mid_coeffs; blk_data(idx)];
        end
    end
    fprintf('Mid-freq coeff stats for frame 1 Cb LH2 DCT:\n');
    fprintf('  Min abs: %.4f\n', min(abs(all_mid_coeffs)));
    fprintf('  Max abs: %.4f\n', max(abs(all_mid_coeffs)));
    fprintf('  Median abs: %.4f\n', median(abs(all_mid_coeffs)));
    fprintf('  Count in (0.1, 0.2]: %d / %d\n', ...
        sum(abs(all_mid_coeffs) > 0.1 & abs(all_mid_coeffs) <= 0.2), ...
        length(all_mid_coeffs));
    return;
end

fprintf('Extracting (no H.264)...\n');
extractedBits = extractWatermark(wmVideo, Pinfo, gopSize, params);
extractedWatermark = bitsToText(extractedBits);

L   = min(length(watermarkBits), length(extractedBits));
ber = sum(watermarkBits(1:L) ~= extractedBits(1:L)) / L;

fprintf('\n=== DIRECT (no H.264) RESULT ===\n');
fprintf('Original  : %s\n', originalWatermark);
fprintf('Extracted : %s\n', extractedWatermark);
fprintf('BER       : %.6f\n', ber);
if ber == 0
    fprintf('SUCCESS: DCT embedding is working correctly!\n');
else
    fprintf('FAIL: Still getting errors in the DCT layer.\n');
end
