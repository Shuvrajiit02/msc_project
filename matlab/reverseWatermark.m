function recoveredVideo = reverseWatermark(wmVideo, gopSize, params)

fprintf('[Reverse] Starting reversal...\n');

recoveredVideo = wmVideo;
numFrames = length(wmVideo);

% ---------------- Extract auxiliary bits ----------------
auxBits = [];

for f = 2:numFrames

    if mod(f-1, gopSize) == 0
        continue;
    end

    if isfield(wmVideo(f), 'mvx')

        mvx = wmVideo(f).mvx;
        mvy = wmVideo(f).mvy;

        bits = extractHistogramMV(mvx, mvy);
        auxBits = [auxBits bits];
    end
end

% ---------------- Recover Pinfo ----------------
Pinfo = deserializePinfo(auxBits);

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

    % Channel
    if strcmpi(params.channel, 'Cb')
        channel = recoveredVideo(iFrame).Cb;
    else
        channel = recoveredVideo(iFrame).Cr;
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

    if coeffIdx > numel(block)
        continue;
    end

    val = block(coeffIdx);

    % =====================================================
    % ? REVERSE ORIGINAL MULTIPLICATIVE EMBEDDING
    % =====================================================
    block(coeffIdx) = val / params.embedFactor;

    dctBand(bi:bi+blk-1, bj:bj+blk-1) = block;

    % Inverse transforms
    LH2_rec  = idct2(dctBand);
    LL1_rec  = idwt2(LL2, LH2_rec, HL2, HH2, params.wavelet);
    channelR = idwt2(LL1_rec, LH1, HL1, HH1, params.wavelet);

    % Clamp
    channelR = max(min(channelR, 1), 0);

    if strcmpi(params.channel, 'Cb')
        recoveredVideo(iFrame).Cb = channelR;
    else
        recoveredVideo(iFrame).Cr = channelR;
    end

end

fprintf('[Reverse] Reversal complete.\n');

end