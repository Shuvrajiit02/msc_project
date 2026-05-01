function bits = serializePinfo(Pinfo)

% Fixed bit widths (adjust if needed)
BITS_IFRAME   = 12;
BITS_BLOCK    = 13;
BITS_COEFF    = 6;
BITS_BITIDX   = 12;

bits = [];

for i = 1:length(Pinfo)

    sync_word = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0]; % 16-bit sync word

    payload = [ ...
        dec2bin(Pinfo(i).iFrame,  BITS_IFRAME) - '0', ...
        dec2bin(Pinfo(i).block,   BITS_BLOCK)  - '0', ...
        dec2bin(Pinfo(i).coeffIdx,BITS_COEFF)  - '0', ...
        dec2bin(Pinfo(i).bitIdx,  BITS_BITIDX) - '0' ...
    ];
    
    chk = mod(sum(payload), 256);
    chk_bin = dec2bin(chk, 8) - '0';

    bits = [bits sync_word payload chk_bin];
end

bits = bits(:)'; % ensure row vector

end