% debug_embed.m
% Tests the DCT watermarking layer in isolation (no H.264).
% If BER == 0 here, the DCT embed/extract pipeline is correct and any
% remaining error is purely from the H.264 auxiliary channel.
%
% Run from the matlab/ folder: >> debug_embed

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

% ---- EMBED ----
fprintf('Embedding...\n');
[wmVideo, ~, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params);
fprintf('Pinfo entries generated: %d\n', length(Pinfo));

if isempty(Pinfo)
    fprintf('\nERROR: Embedding produced 0 Pinfo entries.\n');
    fprintf('Diagnosing coefficient distribution in frame 1 Cb channel...\n\n');

    channel = double(video(1).Cb);
    [LL1,~,~,~] = dwt2(channel, 'haar');
    [~,LH2,~,~] = dwt2(LL1,   'haar');
    dctBand      = dct2(LH2);

    midMask = [0 1 1 0; 1 1 1 0; 1 1 0 0; 0 0 0 0];
    coeff_idx_list = find(midMask == 1);
    blk = 4; [h,w] = size(dctBand);
    all_mid = [];
    for ii = 1:blk:h-blk+1
        for jj = 1:blk:w-blk+1
            blk_data = dctBand(ii:ii+blk-1, jj:jj+blk-1);
            all_mid  = [all_mid; blk_data(coeff_idx_list)]; %#ok<AGROW>
        end
    end

    fprintf('Mid-frequency coefficient stats (frame 1, Cb, LH2 DCT):\n');
    fprintf('  Min |coeff|  : %.5f\n', min(abs(all_mid)));
    fprintf('  Max |coeff|  : %.5f\n', max(abs(all_mid)));
    fprintf('  Median |coeff|: %.5f\n', median(abs(all_mid)));
    fprintf('  Count in (0.1, 0.2]: %d / %d (%.1f%%)\n', ...
        sum(abs(all_mid) > 0.1 & abs(all_mid) <= 0.2), numel(all_mid), ...
        100*sum(abs(all_mid) > 0.1 & abs(all_mid) <= 0.2)/numel(all_mid));

    fprintf('\n→ If count is 0, adjust EMBED_LO/EMBED_HI in embedWatermark.m.\n');
    return;
end

% ---- EXTRACT (no H.264) ----
fprintf('Extracting directly from watermarked video (no H.264)...\n');
extractedBits      = extractWatermark(wmVideo, Pinfo, gopSize, params);
extractedWatermark = bitsToText(extractedBits);

L   = min(length(watermarkBits), length(extractedBits));
ber = sum(watermarkBits(1:L) ~= extractedBits(1:L)) / L;

fprintf('\n=== DIRECT (no H.264) RESULT ===\n');
fprintf('Original  : %s\n', originalWatermark);
fprintf('Extracted : %s\n', extractedWatermark);
fprintf('BER       : %.6f\n', ber);

if ber == 0
    fprintf('SUCCESS: DCT embedding layer is correct. Run main.m for full pipeline.\n');
else
    fprintf('FAIL: DCT layer still has errors. Check thresholds.\n');
end
