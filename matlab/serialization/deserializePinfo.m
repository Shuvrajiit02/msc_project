function Pinfo = deserializePinfo(bits)

bits = bits(:)'; % Ensure row vector for isequal matching

BITS_IFRAME   = 12;
BITS_BLOCK    = 13;
BITS_COEFF    = 6;
BITS_BITIDX   = 12;

entrySize = BITS_IFRAME + BITS_BLOCK + BITS_COEFF + BITS_BITIDX + 32;

Pinfo = struct('pFrame', {}, 'iFrame', {}, 'block', {}, 'coeffIdx', {}, 'bitIdx', {}, 'origCoeff', {});

sync_word = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];
sync_len = length(sync_word);

idx = 1;
while idx <= length(bits) - (sync_len + entrySize) + 1
    % Check for sync word
    if isequal(bits(idx:idx+sync_len-1), sync_word)
        idx = idx + sync_len; % Move past sync word
        
        try
            iFrameBits = reshape(bits(idx:idx+BITS_IFRAME-1), 1, []);
            idx = idx + BITS_IFRAME;

            blockBits = reshape(bits(idx:idx+BITS_BLOCK-1), 1, []);
            idx = idx + BITS_BLOCK;

            coeffBits = reshape(bits(idx:idx+BITS_COEFF-1), 1, []);
            idx = idx + BITS_COEFF;

            bitIdxBits = reshape(bits(idx:idx+BITS_BITIDX-1), 1, []);
            idx = idx + BITS_BITIDX;
            
            origBits = reshape(bits(idx:idx+31), 1, []);
            idx = idx + 32;

            chkBits = reshape(bits(idx:idx+7), 1, []);
            idx = idx + 8;

            % CHECKSUM VALIDATION
            payload = [iFrameBits, blockBits, coeffBits, bitIdxBits, origBits];
            chk_calc = mod(sum(payload), 256);
            chk_read = sum(chkBits .* (2.^(7:-1:0)));

            if chk_calc == chk_read
                iFrame   = bin2dec(char(iFrameBits + '0'));
                block    = bin2dec(char(blockBits + '0'));
                coeffIdx = bin2dec(char(coeffBits + '0'));
                bitIdx   = bin2dec(char(bitIdxBits + '0'));
                
                origFloat = typecast(uint32(bin2dec(char(origBits + '0'))), 'single');

                Pinfo(end+1).iFrame   = iFrame;
                Pinfo(end).block      = block;
                Pinfo(end).coeffIdx   = coeffIdx;
                Pinfo(end).bitIdx     = bitIdx;
                Pinfo(end).origCoeff  = origFloat;
                Pinfo(end).pFrame     = iFrame + 1;
            end
        catch
            % Failed to parse, just move forward by 1 bit to search for next sync word
            idx = idx - entrySize + 1 - 8;
            continue;
        end
    else
        % No sync word found, move forward by 1 bit
        idx = idx + 1;
    end
end

end