function [wmVideo, embedLog, Pinfo] = embedWatermark(video, watermarkBits, gopSize, params)

numFrames = length(video);
wmVideo   = video;

R       = params.redundancy;
numBits = length(watermarkBits);

embedLog = struct('iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});
Pinfo    = struct('pFrame', {}, 'iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {}, 'origCoeff', {});

EMBED_LO = 0;
EMBED_HI = 50;

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

    LS = liftwave(params.wavelet, 'Int2Int');
    [CA1, CH1, CV1, CD1] = lwt2(channel, LS);
    [CA2, CH2, CV2, CD2] = lwt2(CA1, LS);
    dctBand = CH2; % Keep variable name for minimal code changes

    blk = params.blockSize;
    [h, w] = size(dctBand);
    blockID = 0;

    % Try to embed bits into this frame
    for i = 1:blk:h-blk+1
        for j = 1:blk:w-blk+1
            blockID = blockID + 1;
            
            % Find a bit that still needs embedding
            targetBitIdx = find(bitEmbedCounts < R, 1);
            if isempty(targetBitIdx), break; end
            
            bit = watermarkBits(targetBitIdx);
            
            block = dctBand(i:i+blk-1, j:j+blk-1);
            midMask = [0 1 1 0; 1 1 1 0; 1 1 0 0; 0 0 0 0];
            coeff_idx_list = find(midMask == 1);
            midCoeffs = block(coeff_idx_list);

            if nnz(midCoeffs) < params.nnzThreshold || sum(abs(midCoeffs)) < params.energyThreshold
                continue;
            end

            for k = 1:length(coeff_idx_list)
                val = midCoeffs(k);
                if abs(val) > EMBED_LO && abs(val) <= EMBED_HI
                    % Integer embedding
                    if bit == 0, newVal = sign(val) * 5;
                    else, newVal = sign(val) * params.embedFactor; end
                    
                    % Let's do it safely:
                    block_test = block;
                    block_test(coeff_idx_list(k)) = round(newVal);
                    dctBand(i:i+blk-1, j:j+blk-1) = block_test;
                    
                    % Check for clipping
                    CH2_test = dctBand;
                    CA1_test = ilwt2(CA2, CH2_test, CV2, CD2, LS);
                    channelR_test = ilwt2(CA1_test, CH1, CV1, CD1, LS);
                    channelR_test = channelR_test(1:size(video(f).Cb, 1), 1:size(video(f).Cb, 2));
                    
                    if any(channelR_test(:) < 0) || any(channelR_test(:) > 255)
                        % Revert
                        dctBand(i:i+blk-1, j:j+blk-1) = block;
                        continue; 
                    end

                    % If safe, commit
                    block = block_test;
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
                        Pinfo(end).origCoeff = double(val); % Still use double for safety, though it's int
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
    CH2_rec = dctBand;
    CA1_rec = ilwt2(CA2, CH2_rec, CV2, CD2, LS);
    channelR = ilwt2(CA1_rec, CH1, CV1, CD1, LS);
    
    channelR = channelR(1:size(video(f).Cb, 1), 1:size(video(f).Cb, 2));
    channelR = uint8(min(max(channelR, 0), 255));
    
    if strcmpi(params.channel, 'Cb')
        wmVideo(f).Cb = channelR;
    else
        wmVideo(f).Cr = channelR;
    end
end

fprintf('[Embed] Embedding complete. %d Pinfo entries generated.\n', length(Pinfo));

end