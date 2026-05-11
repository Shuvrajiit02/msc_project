function bits = serializePinfo(Pinfo)

% Fixed bit widths (adjust if needed)
BITS_IFRAME   = 12;
BITS_BLOCK    = 13;
BITS_COEFF    = 6;
BITS_BITIDX   = 12;

bits = [];

for i = 1:length(Pinfo)

    sync_word = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0]; % 16-bit sync word

    % Convert int16 to 16 bits
    origBits = dec2bin(typecast(int16(Pinfo(i).origCoeff), 'uint16'), 16) - '0';

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