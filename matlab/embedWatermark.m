function [wmVideo, embedLog, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params)

numFrames = length(video);
wmVideo   = video;

R = params.redundancy;
numBits = length(watermarkBits);

embedLog = struct('iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});
Pinfo    = struct('pFrame', {}, 'iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});

fprintf('[Embed] Starting embedding...\n');

for b = 1:numBits

    bit = watermarkBits(b);
    embedCount = 0;

    for f = 1:numFrames

        % Only I-frames
        if mod(f-1, gopSize) ~= 0
            continue;
        end

        % ---------------- GET CHANNEL ----------------
        if strcmpi(params.channel, 'Cb')
            channel = double(wmVideo(f).Cb);
        else
            channel = double(wmVideo(f).Cr);
        end

        % ---------------- DWT ----------------
        [LL1, LH1, HL1, HH1] = dwt2(channel, params.wavelet);
        [LL2, LH2, HL2, HH2] = dwt2(LL1, params.wavelet);

        % ---------------- DCT ----------------
        dctBand = dct2(LH2);

        blk = params.blockSize;
        [h, w] = size(dctBand);
        blockID = 0;

        for i = 1:blk:h-blk+1
            for j = 1:blk:w-blk+1

                if embedCount >= R
                    break;
                end

                blockID = blockID + 1;
                block = dctBand(i:i+blk-1, j:j+blk-1);

                % Mid-frequency mask
                midMask = [0 1 1 0;
                           1 1 1 0;
                           1 1 0 0;
                           0 0 0 0];

                idx = find(midMask == 1);
                midCoeffs = block(idx);

                % Texture filtering
                if nnz(midCoeffs) < params.nnzThreshold || ...
                   sum(abs(midCoeffs)) < params.energyThreshold
                    continue;
                end

                % ---------------- ORIGINAL EMBEDDING ----------------
                for k = 1:length(idx)

                    val = midCoeffs(k);

                    % ? FIXED THRESHOLDS (REALISTIC DCT RANGE)
                    if bit == 0 && abs(val) > 1 && abs(val) <= 5
                        newVal = val * params.embedFactor;

                    elseif bit == 1 && abs(val) > 5 && abs(val) <= 10
                        newVal = val * params.embedFactor;

                    else
                        continue;
                    end

                    % Apply embedding
                    block(idx(k)) = newVal;
                    dctBand(i:i+blk-1, j:j+blk-1) = block;

                    % Logging
                    embedLog(end+1).iFrame  = f;
                    embedLog(end).block    = blockID;
                    embedLog(end).coeffIdx = idx(k);
                    embedLog(end).bitIdx   = b;

                    if f + 1 <= numFrames
                        Pinfo(end+1).pFrame  = f + 1;
                        Pinfo(end).iFrame    = f;
                        Pinfo(end).block     = blockID;
                        Pinfo(end).coeffIdx  = idx(k);
                        Pinfo(end).bitIdx    = b;
                    end

                    embedCount = embedCount + 1;
                    break;
                end
            end
        end

        % ---------------- INVERSE ----------------
        LH2_rec  = idct2(dctBand);
        LL1_rec  = idwt2(LL2, LH2_rec, HL2, HH2, params.wavelet);
        channelR = idwt2(LL1_rec, LH1, HL1, HH1, params.wavelet);

        % ---------------- ? CRITICAL FIX ----------------
        % Match original size
        channelR = channelR(1:size(channel,1), 1:size(channel,2));

        % Clip values
        channelR = min(max(channelR, 0), 255);

        % Convert to uint8
        channelR = uint8(channelR);

        % ---------------- SAVE BACK ----------------
        if strcmpi(params.channel, 'Cb')
            wmVideo(f).Cb = channelR;
        else
            wmVideo(f).Cr = channelR;
        end

        if embedCount >= R
            break;
        end
    end
end

fprintf('[Embed] Embedding complete.\n');

% ============================================================
% AUXILIARY DATA (UNCHANGED)
% ============================================================

fprintf('[Embed] Embedding auxiliary data...\n');

auxBits = serializePinfo(Pinfo);

for f = 2:numFrames

    if mod(f-1, gopSize) == 0
        continue;
    end

    curr = double(wmVideo(f).Y);
    ref  = double(wmVideo(f-1).Y);

    mv = estimateMotionBlock(curr, ref, [1 1], params.blockSize, params.searchRange);

    mvx = mv(1);
    mvy = mv(2);

    [mvx, mvy] = embedHistogramMV(mvx, mvy, auxBits);

    wmVideo(f).mvx = mvx;
    wmVideo(f).mvy = mvy;
end

end