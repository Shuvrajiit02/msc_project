function bits = serializePinfo(Pinfo)

% Fixed bit widths (optimized to fit double precision)
BITS_IFRAME   = 9;
BITS_BLOCK    = 9;
BITS_COEFF    = 6;
BITS_BITIDX   = 10;

bits = [];

for i = 1:length(Pinfo)

    sync_word = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0]; % 16-bit sync word

    % Convert exact double float to 64-bit uint64, then to 64 bits
    u64 = typecast(double(Pinfo(i).origCoeff), 'uint64');
    % dec2bin limits to 52 bits for accurate integer representation
    % We need a custom dec2bin for 64-bit integers.
    % Wait, MATLAB's dec2bin does NOT support uint64 larger than 2^52 accurately.
    % To convert uint64 to 64 bits reliably:
    % We can convert to two uint32s, then dec2bin each to 32 bits!
    u32s = typecast(double(Pinfo(i).origCoeff), 'uint32');
    origBits1 = dec2bin(u32s(1), 32) - '0';
    origBits2 = dec2bin(u32s(2), 32) - '0';
    origBits = [origBits1, origBits2];

    payload = [ ...
        dec2bin(Pinfo(i).iFrame,  BITS_IFRAME) - '0', ...
        dec2bin(Pinfo(i).block,   BITS_BLOCK)  - '0', ...
        dec2bin(Pinfo(i).coeffIdx,BITS_COEFF)  - '0', ...
        dec2bin(Pinfo(i).bitIdx,  BITS_BITIDX) - '0', ...
        origBits ...
    ];
    
    chk = mod(sum(payload), 256);
    chk_bin = dec2bin(chk, 8) - '0';

    % Make sure chk_bin is exactly 8 bits
    if length(chk_bin) < 8
        chk_bin = [zeros(1, 8 - length(chk_bin)), chk_bin];
    end

    bits = [bits sync_word payload chk_bin];
end

bits = bits(:)'; % ensure row vector

end