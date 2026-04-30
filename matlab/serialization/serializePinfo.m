function bits = serializePinfo(Pinfo)

% Fixed bit widths (adjust if needed)
BITS_IFRAME   = 12;
BITS_BLOCK    = 12;
BITS_COEFF    = 6;
BITS_BITIDX   = 12;

bits = [];

for i = 1:length(Pinfo)

    bits = [bits ...
        dec2bin(Pinfo(i).iFrame,  BITS_IFRAME) - '0', ...
        dec2bin(Pinfo(i).block,   BITS_BLOCK)  - '0', ...
        dec2bin(Pinfo(i).coeffIdx,BITS_COEFF)  - '0', ...
        dec2bin(Pinfo(i).bitIdx,  BITS_BITIDX) - '0' ...
    ];
end

bits = bits(:)'; % ensure row vector

end