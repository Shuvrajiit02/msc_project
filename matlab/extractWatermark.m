function finalBits = extractWatermark(wmVideo, Pinfo, gopSize, params)

fprintf('[Extract] Starting extraction...\n');

if isempty(Pinfo)
    finalBits = [];
    fprintf('[Extract] No valid bits extracted.\n');
    return;
end

numBits = max([Pinfo.bitIdx]);
rawBits = [];
rawBitIdx = [];

uFrames = unique([Pinfo.iFrame]);

for fIdx = 1:length(uFrames)
    f = uFrames(fIdx);
    
    if strcmpi(params.channel, 'Cb')
        channel = double(wmVideo(f).Cb);
    else
        channel = double(wmVideo(f).Cr);
    end
    
    LS = liftwave(params.wavelet, 'Int2Int');
    [CA1, CH1, CV1, CD1] = lwt2(channel, LS);
    [CA2, CH2, CV2, CD2] = lwt2(CA1, LS);
    dctBand = CH2;
    
    framePackets = Pinfo([Pinfo.iFrame] == f);
    
    for p = 1:length(framePackets)
        blockID = framePackets(p).block;
        coeffIdx = framePackets(p).coeffIdx;
        bitIdx = framePackets(p).bitIdx;
        
        blk = params.blockSize;
        [h, w] = size(dctBand);
        
        r = floor((blockID - 1) / floor(w/blk)) * blk + 1;
        c = mod(blockID - 1, floor(w/blk)) * blk + 1;
        
        block = dctBand(r:r+blk-1, c:c+blk-1);
        
        val = block(coeffIdx);
        
        if abs(val) > params.embedFactor / 2
            bit = 1;
        else
            bit = 0;
        end
        
        rawBits(end+1) = bit;
        rawBitIdx(end+1) = bitIdx;
    end
end

if isempty(rawBitIdx)
    finalBits = [];
    fprintf('[Extract] No valid bits extracted.\n');
    return;
end

maxBitIdx = max(rawBitIdx);
finalBits = zeros(1, maxBitIdx);

for b = 1:maxBitIdx
    votes = rawBits(rawBitIdx == b);
    if ~isempty(votes)
        finalBits(b) = mean(votes) > 0.5;
    end
end

fprintf('[Extract] Extraction complete.\n');

end