function Pinfo = deserializePinfo(bits)

BITS_IFRAME   = 12;
BITS_BLOCK    = 12;
BITS_COEFF    = 6;
BITS_BITIDX   = 12;

entrySize = BITS_IFRAME + BITS_BLOCK + BITS_COEFF + BITS_BITIDX;
numEntries = floor(length(bits) / entrySize);

Pinfo = struct('pFrame', {}, 'iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {});

idx = 1;

for i = 1:numEntries

    try
        iFrameBits = reshape(bits(idx:idx+BITS_IFRAME-1), 1, []);
        idx = idx + BITS_IFRAME;

        blockBits = reshape(bits(idx:idx+BITS_BLOCK-1), 1, []);
        idx = idx + BITS_BLOCK;

        coeffBits = reshape(bits(idx:idx+BITS_COEFF-1), 1, []);
        idx = idx + BITS_COEFF;

        bitIdxBits = reshape(bits(idx:idx+BITS_BITIDX-1), 1, []);
        idx = idx + BITS_BITIDX;

        iFrame   = bin2dec(char(iFrameBits + '0'));
        block    = bin2dec(char(blockBits + '0'));
        coeffIdx = bin2dec(char(coeffBits + '0'));
        bitIdx   = bin2dec(char(bitIdxBits + '0'));

        Pinfo(end+1).iFrame   = iFrame;
        Pinfo(end).block      = block;
        Pinfo(end).coeffIdx   = coeffIdx;
        Pinfo(end).bitIdx     = bitIdx;
        Pinfo(end).pFrame     = iFrame + 1;

    catch
        continue;
    end
end

end