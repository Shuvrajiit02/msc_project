function [wmVideo, embedLog, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params)

numFrames = length(video);
wmVideo   = video;

R       = params.redundancy;
numBits = length(watermarkBits);

embedLog = struct('iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});
Pinfo    = struct('pFrame', {}, 'iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {}, 'origCoeff', {});

EMBED_LO = 5;
EMBED_HI = 1000;

usedBlocks = false(numFrames, 100000); % Track used blocks
bitEmbedCounts = zeros(numBits, 1);

fprintf('[Embed] Starting embedding...\n');

% Process frame by frame
for f = 1:numFrames
    if mod(f-1, gopSize) ~= 0, continue; end

    if strcmpi(params.channel, 'Cb')
        channel = double(video(f).Cb);
    else
        channel = double(video(f).Cr);
    end

    % Setup Lifting Scheme for IWT
    ls = liftwave(params.wavelet, 'Int2Int');

    [LL1, LH1, HL1, HH1] = lwt2(channel, ls);
    [LL2, LH2, HL2, HH2] = lwt2(LL1,     ls);
    
    LH2_rec = LH2; % We will modify this

    blk = params.blockSize;
    [h, w] = size(LH2);
    blockID = 0;

    % Try to embed bits into this frame
    for i = 1:blk:h-blk+1
        for j = 1:blk:w-blk+1
            blockID = blockID + 1;
            
            % Find a bit that still needs embedding
            targetBitIdx = find(bitEmbedCounts < R, 1);
            if isempty(targetBitIdx), break; end
            
            bit = watermarkBits(targetBitIdx);
            
            % Get block and apply Integer DCT
            orig_block = LH2(i:i+blk-1, j:j+blk-1);
            block = intdct4(orig_block);
            
            midMask = [0 1 1 0; 1 1 1 0; 1 1 0 0; 0 0 0 0];
            coeff_idx_list = find(midMask == 1);
            midCoeffs = block(coeff_idx_list);

            if nnz(midCoeffs) < params.nnzThreshold || sum(abs(midCoeffs)) < params.energyThreshold
                continue;
            end

            for k = 1:length(coeff_idx_list)
                val = midCoeffs(k);
                if abs(val) > EMBED_LO && abs(val) <= EMBED_HI
                    if bit == 0, newVal = sign(val) * 0; % Force to zero for bit 0
                    else, newVal = sign(val) * params.embedFactor; end

                    block(coeff_idx_list(k)) = newVal;
                    
                    % Inverse Integer DCT and update LH2_rec
                    LH2_rec(i:i+blk-1, j:j+blk-1) = intidct4(block);

                    embedLog(end+1).iFrame = f;
                    embedLog(end).block = blockID;
                    embedLog(end).coeffIdx = coeff_idx_list(k);
                    embedLog(end).bitIdx = targetBitIdx;

                    if f + 1 <= numFrames
                        Pinfo(end+1).pFrame = f + 1;
                        Pinfo(end).iFrame = f;
                        Pinfo(end).block = blockID;
                        Pinfo(end).coeffIdx = coeff_idx_list(k);
                        Pinfo(end).bitIdx = targetBitIdx;
                        Pinfo(end).origCoeff = int16(val); % Store as 16-bit integer
                    end

                    bitEmbedCounts(targetBitIdx) = bitEmbedCounts(targetBitIdx) + 1;
                    usedBlocks(f, blockID) = true;
                    break;
                end
            end
        end
        if isempty(find(bitEmbedCounts < R, 1)), break; end
    end

    % Inverse transform ONCE per frame
    LL1_rec = ilwt2(LL2, LH2_rec, HL2, HH2, ls);
    channelR = ilwt2(LL1_rec, LH1, HL1, HH1, ls);
    
    % Ensure uint8 and clipping for safety (though IWT should preserve range if no overflow)
    channelR = uint8(min(max(channelR, 0), 255));
    
    if strcmpi(params.channel, 'Cb')
        wmVideo(f).Cb = channelR;
    else
        wmVideo(f).Cr = channelR;
    end
end

fprintf('[Embed] Embedding complete. %d Pinfo entries generated.\n', length(Pinfo));

end