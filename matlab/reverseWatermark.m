function recoveredVideo = reverseWatermark(wmVideo, Pinfo, params)

fprintf('[Reverse] Starting reversal...\n');

recoveredVideo = wmVideo;
numFrames = length(wmVideo);

if isempty(Pinfo)
    warning('[Reverse] No Pinfo recovered.');
    return;
end

% Group Pinfo by frame for efficient/lossless processing
uFrames = unique([Pinfo.iFrame]);

for fIdx = 1:length(uFrames)
    f = uFrames(fIdx);
    
    if f < 1 || f > numFrames, continue; end
    
    % Find all packets for this frame
    framePackets = Pinfo([Pinfo.iFrame] == f);
    
    if strcmpi(params.channel, 'Cb')
        channel = double(wmVideo(f).Cb);
    else
        channel = double(wmVideo(f).Cr);
    end

    LS = liftwave(params.wavelet, 'Int2Int');
    [CA1, CH1, CV1, CD1] = lwt2(channel, LS);
    [CA2, CH2, CV2, CD2] = lwt2(CA1, LS);
    dctBand = CH2; % Treat CH2 directly as the embedding band

    % Get all packets for this frame
    framePackets = Pinfo([Pinfo.iFrame] == f);
    if isempty(framePackets)
        % No packets -> no changes to reverse
        recoveredVideo(f).Cb = wmVideo(f).Cb;
        continue;
    end

    % 2. Process all Pinfo for this frame
    extractedBits = [];
    for p = 1:length(framePackets)
        blockID = framePackets(p).block;
        coeffIdx = framePackets(p).coeffIdx;
        
        blk = params.blockSize;
        [h, w] = size(dctBand);
        
        % Calculate block coordinates
        r = floor((blockID - 1) / floor(w/blk)) * blk + 1;
        c = mod(blockID - 1, floor(w/blk)) * blk + 1;
        
        block = dctBand(r:r+blk-1, c:c+blk-1);
        
        % Extract Bit (for PSNR validation if needed, though not doing actual BER here)
        val = block(coeffIdx);
        if abs(val) > params.embedFactor / 2
            extractedBits(end+1) = 1;
        else
            extractedBits(end+1) = 0;
        end
        
        % RESTORE EXACT ORIGINAL COEFFICIENT
        if isfield(framePackets(p), 'origCoeff')
            block(coeffIdx) = double(framePackets(p).origCoeff);
        end
        
        dctBand(r:r+blk-1, c:c+blk-1) = block;
    end

    % 3. Inverse transform ONCE per frame
    CH2_rec = dctBand;
    CA1_rec = ilwt2(CA2, CH2_rec, CV2, CD2, LS);
    channelR = ilwt2(CA1_rec, CH1, CV1, CD1, LS);
    
    channelR = channelR(1:size(wmVideo(f).Cb, 1), 1:size(wmVideo(f).Cb, 2));
    channelR = uint8(min(max(channelR, 0), 255));
    
    if strcmpi(params.channel, 'Cb')
        recoveredVideo(f).Cb = channelR;
    else
        recoveredVideo(f).Cr = channelR;
    end
end

fprintf('[Reverse] Reversal complete.\n');

end