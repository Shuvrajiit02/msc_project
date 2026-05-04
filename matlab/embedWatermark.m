function [wmVideo, embedLog, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params)

numFrames = length(video);
wmVideo   = video;

R       = params.redundancy;
numBits = length(watermarkBits);

embedLog = struct('iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});
Pinfo    = struct('pFrame', {}, 'iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});

% QIM range: target coefficients in (EMBED_LO, EMBED_HI]
%   bit=0 → divide by embedFactor → value shrinks to ~0 (H.264 snaps to 0)
%   bit=1 → multiply by embedFactor → value grows to ~1.5-3 (survives quantisation)
EMBED_LO = 0.1;
EMBED_HI = 0.2;

fprintf('[Embed] Starting embedding...\n');

for b = 1:numBits

    bit        = watermarkBits(b);
    embedCount = 0;

    for f = 1:numFrames

        % Only I-frames (every gopSize-th frame, 1-indexed)
        if mod(f-1, gopSize) ~= 0
            continue;
        end

        % ---------------- GET CHANNEL ----------------
        if strcmpi(params.channel, 'Cb')
            channel = double(wmVideo(f).Cb);
        else
            channel = double(wmVideo(f).Cr);
        end

        % ---------------- DWT (2 levels) ----------------
        [LL1, LH1, HL1, HH1] = dwt2(channel, params.wavelet);
        [LL2, LH2, HL2, HH2] = dwt2(LL1,     params.wavelet);

        % ---------------- DCT on LH2 sub-band ----------------
        dctBand = dct2(LH2);

        blk = params.blockSize;
        [h, w] = size(dctBand);
        blockID  = 0;
        embedded = false;

        for i = 1:blk:h-blk+1
            if embedded || embedCount >= R, break; end
            for j = 1:blk:w-blk+1
                if embedded || embedCount >= R, break; end

                blockID = blockID + 1;
                block   = dctBand(i:i+blk-1, j:j+blk-1);

                % Mid-frequency zig-zag mask (avoid DC at position (1,1))
                midMask = [0 1 1 0;
                           1 1 1 0;
                           1 1 0 0;
                           0 0 0 0];

                coeff_idx_list = find(midMask == 1);
                midCoeffs      = block(coeff_idx_list);

                % Texture gate: skip blocks that are too flat
                if nnz(midCoeffs) < params.nnzThreshold || ...
                   sum(abs(midCoeffs)) < params.energyThreshold
                    continue;
                end

                % Find first coefficient in QIM-eligible range
                for k = 1:length(coeff_idx_list)
                    val = midCoeffs(k);

                    if abs(val) > EMBED_LO && abs(val) <= EMBED_HI
                        % ---- QIM-INSPIRED EMBEDDING ----
                        if bit == 0
                            newVal = val / params.embedFactor;  % push toward 0
                        else
                            newVal = val * params.embedFactor;  % push away from 0
                        end

                        block(coeff_idx_list(k)) = newVal;
                        dctBand(i:i+blk-1, j:j+blk-1) = block;

                        % Logging
                        embedLog(end+1).iFrame  = f;
                        embedLog(end).block     = blockID;
                        embedLog(end).coeffIdx  = coeff_idx_list(k);
                        embedLog(end).bitIdx    = b;

                        % Pinfo for aux-channel transport (MV histogram)
                        if f + 1 <= numFrames
                            Pinfo(end+1).pFrame  = f + 1;
                            Pinfo(end).iFrame    = f;
                            Pinfo(end).block     = blockID;
                            Pinfo(end).coeffIdx  = coeff_idx_list(k);
                            Pinfo(end).bitIdx    = b;
                        end

                        embedCount = embedCount + 1;
                        embedded   = true;
                        break; % one coefficient per block
                    end
                end
            end
        end

        % ---------------- INVERSE TRANSFORMS ----------------
        LH2_rec  = idct2(dctBand);
        LL1_rec  = idwt2(LL2, LH2_rec, HL2, HH2, params.wavelet);
        channelR = idwt2(LL1_rec, LH1, HL1, HH1, params.wavelet);

        % Crop to original size (DWT padding artefact)
        channelR = channelR(1:size(channel,1), 1:size(channel,2));
        channelR = min(max(channelR, 0), 255);
        channelR = uint8(channelR);

        % ---------------- SAVE BACK ----------------
        if strcmpi(params.channel, 'Cb')
            wmVideo(f).Cb = channelR;
        else
            wmVideo(f).Cr = channelR;
        end

    end % frame loop
end % bit loop

fprintf('[Embed] Embedding complete. %d Pinfo entries generated.\n', length(Pinfo));

end