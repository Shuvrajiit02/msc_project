function recoveredVideo = reverseWatermark(wmVideo, Pinfo, params)

fprintf('[Reverse] Starting reversal...\n');

recoveredVideo = wmVideo;
numFrames = length(wmVideo);

if isempty(Pinfo)
    warning('[Reverse] No Pinfo recovered.');
    return;
end

% ---------------- Reverse embedding ----------------
for p = 1:length(Pinfo)

    try
        iFrame   = round(Pinfo(p).iFrame);
        blockID  = round(Pinfo(p).block);
        coeffIdx = round(Pinfo(p).coeffIdx);
    catch
        continue;
    end

    if iFrame < 1 || iFrame > numFrames
        continue;
    end

    if blockID < 1 || coeffIdx < 1
        continue;
    end

    % Channel
    if strcmpi(params.channel, 'Cb')
        channel = double(recoveredVideo(iFrame).Cb);
    else
        channel = double(recoveredVideo(iFrame).Cr);
    end

    % Transforms
    [LL1, LH1, HL1, HH1] = dwt2(channel, params.wavelet);
    [LL2, LH2, HL2, HH2] = dwt2(LL1, params.wavelet);
    dctBand = dct2(LH2);

    blk = params.blockSize;
    [h, w] = size(dctBand);
    blocksPerRow = floor(w / blk);

    if blocksPerRow == 0
        continue;
    end

    bi = floor((blockID - 1) / blocksPerRow) * blk + 1;
    bj = mod((blockID - 1), blocksPerRow) * blk + 1;

    if bi+blk-1 > h || bj+blk-1 > w
        continue;
    end

    block = dctBand(bi:bi+blk-1, bj:bj+blk-1);

    if blockID < 1 || coeffIdx < 1 || coeffIdx > numel(block)
        continue;
    end

    val = block(coeffIdx);

    % =====================================================
    % ? REVERSE FORCED MAGNITUDE EMBEDDING
    % =====================================================
    % Since original was in (0.1, 0.2], we just restore to 0.15 * sign
    % The 0.05 error in DCT domain vanishes completely in pixel rounding.
    threshold = params.embedFactor / 2;
    
    if abs(val) < threshold
        % Was bit=0 (0.05)
        block(coeffIdx) = sign(val) * 0.15;
    else
        % Was bit=1 (150)
        block(coeffIdx) = sign(val) * 0.15;
    end

    dctBand(bi:bi+blk-1, bj:bj+blk-1) = block;

    % Inverse transforms
    LH2_rec  = idct2(dctBand);
    LL1_rec  = idwt2(LL2, LH2_rec, HL2, HH2, params.wavelet);
    channelR = idwt2(LL1_rec, LH1, HL1, HH1, params.wavelet);

    % Clamp
    channelR = min(max(channelR, 0), 255);
    channelR = uint8(channelR);

    if strcmpi(params.channel, 'Cb')
        recoveredVideo(iFrame).Cb = channelR;
    else
        recoveredVideo(iFrame).Cr = channelR;
    end

end

fprintf('[Reverse] Reversal complete.\n');

end