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

    [LL1, LH1, HL1, HH1] = dwt2(channel, params.wavelet);
    [LL2, LH2, HL2, HH2] = dwt2(LL1, params.wavelet);
    dctBand = dct2(LH2);

    blk = params.blockSize;
    [h, w] = size(dctBand);
    blocksPerRow = floor(w / blk);
    if blocksPerRow == 0, continue; end

    % Apply all restorations for this frame in one DCT pass
    for p = 1:length(framePackets)
        blockID  = round(framePackets(p).block);
        coeffIdx = round(framePackets(p).coeffIdx);
        
        bi = floor((blockID - 1) / blocksPerRow) * blk + 1;
        bj = mod((blockID - 1), blocksPerRow) * blk + 1;

        if bi+blk-1 > h || bj+blk-1 > w || coeffIdx > blk*blk, continue; end

        block = dctBand(bi:bi+blk-1, bj:bj+blk-1);
        
        if isfield(framePackets(p), 'origCoeff')
            block(coeffIdx) = double(framePackets(p).origCoeff);
        else
            val = block(coeffIdx);
            threshold = params.embedFactor / 2;
            block(coeffIdx) = sign(val) * 0.15;
        end
        
        dctBand(bi:bi+blk-1, bj:bj+blk-1) = block;
    end

    % Inverse transform ONCE per frame
    LH2_rec = idct2(dctBand);
    LL1_rec = idwt2(LL2, LH2_rec, HL2, HH2, params.wavelet);
    channelR = idwt2(LL1_rec, LH1, HL1, HH1, params.wavelet);
    
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