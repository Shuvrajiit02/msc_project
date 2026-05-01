function finalBits = extractWatermark(wmVideo, Pinfo, gopSize, params)

fprintf('[Extract] Starting extraction...\n');

numEntries = length(Pinfo);

rawBits   = [];
rawBitIdx = [];

for p = 1:numEntries

    % --- Safe read ---
    try
        iFrame   = round(Pinfo(p).iFrame);
        blockID  = round(Pinfo(p).block);
        coeffIdx = round(Pinfo(p).coeffIdx);
        bitIdx   = round(Pinfo(p).bitIdx);
    catch
        continue;
    end

    % --- Validation ---
    if isempty(iFrame) || numel(iFrame) ~= 1
        continue;
    end

    if iFrame < 1 || iFrame > length(wmVideo)
        continue;
    end

    if blockID < 1 || coeffIdx < 1
        continue;
    end

    % --- Channel ---
    if strcmpi(params.channel, 'Cb')
        channel = double(wmVideo(iFrame).Cb);
    else
        channel = double(wmVideo(iFrame).Cr);
    end

    % --- Transform ---
    [LL1, ~, ~, ~] = dwt2(channel, params.wavelet);
    [~, LH2, ~, ~] = dwt2(LL1, params.wavelet);
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
    val_abs = abs(val);

    % =====================================================
    % ? MATCH ORIGINAL RANGE-BASED EMBEDDING
    % =====================================================
    if val_abs >= (0.5 * params.embedFactor) && val_abs <= (5.5 * params.embedFactor)
        bit = 0;

    elseif val_abs > (5.5 * params.embedFactor) && ...
           val_abs <= (12 * params.embedFactor)
        bit = 1;

    else
        continue;
    end

    rawBits(end+1)   = bit;
    rawBitIdx(end+1) = bitIdx;

end

% ---------------- Majority Voting ----------------
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