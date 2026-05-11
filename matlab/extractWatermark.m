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

    % --- Setup Lifting Scheme for IWT ---
    ls = liftwave(params.wavelet, 'Int2Int');

    % --- Transform ---
    [LL1, ~, ~, ~] = lwt2(channel, ls);
    [~, LH2, ~, ~] = lwt2(LL1, ls);

    blk = params.blockSize;
    [h, w] = size(LH2);
    blocksPerRow = floor(w / blk);

    if blocksPerRow == 0
        continue;
    end

    bi = floor((blockID - 1) / blocksPerRow) * blk + 1;
    bj = mod((blockID - 1), blocksPerRow) * blk + 1;

    if bi+blk-1 > h || bj+blk-1 > w
        continue;
    end

    % Get block and apply Integer DCT to extract
    curr_block = LH2(bi:bi+blk-1, bj:bj+blk-1);
    block_dct = intdct4(curr_block);

    if coeffIdx > numel(block_dct)
        continue;
    end

    val = block_dct(coeffIdx);
    val_abs = abs(val);

    % =====================================================
    % ? ROBUST EXTRACTION FOR FORCED MAGNITUDE
    % =====================================================
    % Bit 0 was forced to 0.05.
    % Bit 1 was forced to params.embedFactor (e.g. 150).
    threshold = params.embedFactor / 2; % Safe midpoint
    
    if val_abs < threshold
        bit = 0;
    else
        bit = 1;
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