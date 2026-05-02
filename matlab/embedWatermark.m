function [wmVideo, embedLog, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params)

numFrames = length(video);
wmVideo   = video;

R       = params.redundancy;
numBits = length(watermarkBits);

embedLog = struct('iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});
Pinfo    = struct('pFrame', {}, 'iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});

% QIM parameters
% Coefficients in (EMBED_LO, EMBED_HI] are eligible for embedding
EMBED_LO = 0.1;
EMBED_HI = 0.2;
% embedFactor = 15 (set in main.m)
% bit=0: val / embedFactor  -> ~0.007-0.013  (snapped to 0 by H.264)
% bit=1: val * embedFactor  -> ~1.5-3.0      (survives quantization)

fprintf('[Embed] Starting embedding...\n');

for b = 1:numBits

    bit        = watermarkBits(b);
    embedCount = 0;

    for f = 1:numFrames

        % Only I-frames (every gopSize-th frame)
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
        blockID = 0;
        embedded = false;

        for i = 1:blk:h-blk+1
            if embedded, break; end
            for j = 1:blk:w-blk+1
                if embedded, break; end

                blockID = blockID + 1;
                block = dctBand(i:i+blk-1, j:j+blk-1);

                % Mid-frequency zig-zag mask (avoid DC at (1,1))
                midMask = [0 1 1 0;
                           1 1 1 0;
                           1 1 0 0;
                           0 0 0 0];

                coeff_idx_list = find(midMask == 1);
                midCoeffs      = block(coeff_idx_list);

                % Find a coefficient in the eligible QIM range
                for k = 1:length(coeff_idx_list)
                    val = midCoeffs(k);

                    if abs(val) > EMBED_LO && abs(val) <= EMBED_HI
                        % --- QIM-INSPIRED EMBEDDING ---
                        if bit == 0
                            newVal = val / params.embedFactor;
                        else
                            newVal = val * params.embedFactor;
                        end

                        block(coeff_idx_list(k)) = newVal;
                        dctBand(i:i+blk-1, j:j+blk-1) = block;

                        % Log embedding
                        embedLog(end+1).iFrame  = f;
                        embedLog(end).block     = blockID;
                        embedLog(end).coeffIdx  = coeff_idx_list(k);
                        embedLog(end).bitIdx    = b;

                        % Record Pinfo for aux-channel transport
                        if f + 1 <= numFrames
                            Pinfo(end+1).pFrame  = f + 1;
                            Pinfo(end).iFrame    = f;
                            Pinfo(end).block     = blockID;
                            Pinfo(end).coeffIdx  = coeff_idx_list(k);
                            Pinfo(end).bitIdx    = b;
                        end

                        embedCount = embedCount + 1;
                        embedded   = true;
                        break; % one coeff per block
                    end
                end
            end
        end

        % ---------------- INVERSE TRANSFORMS ----------------
        LH2_rec  = idct2(dctBand);
        LL1_rec  = idwt2(LL2, LH2_rec, HL2, HH2, params.wavelet);
        channelR = idwt2(LL1_rec, LH1, HL1, HH1, params.wavelet);

        channelR = channelR(1:size(channel,1), 1:size(channel,2));
        channelR = min(max(channelR, 0), 255);
        channelR = uint8(channelR);

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

fprintf('[Embed] Embedding complete. %d Pinfo entries generated.\n', length(Pinfo));

end