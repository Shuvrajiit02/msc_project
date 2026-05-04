clc; clear;

addpath('../matlab/serialization');

orig = load('../data/aux_bits.txt');
orig = orig(:)';
first_packet = orig(1:67);

PinfoRec = deserializePinfo(first_packet);

disp(['Recovered: ', num2str(length(PinfoRec))]);

if isempty(PinfoRec)
    sync_len = 16;
    idx = 1 + sync_len;
    
    BITS_IFRAME = 8;
    BITS_BLOCK = 14;
    BITS_COEFF = 7;
    BITS_BITIDX = 14;
    
    iFrameBits = reshape(first_packet(idx:idx+BITS_IFRAME-1), 1, []); idx = idx + BITS_IFRAME;
    blockBits = reshape(first_packet(idx:idx+BITS_BLOCK-1), 1, []); idx = idx + BITS_BLOCK;
    coeffBits = reshape(first_packet(idx:idx+BITS_COEFF-1), 1, []); idx = idx + BITS_COEFF;
    bitIdxBits = reshape(first_packet(idx:idx+BITS_BITIDX-1), 1, []); idx = idx + BITS_BITIDX;
    chkBits = reshape(first_packet(idx:idx+7), 1, []); idx = idx + 8;
    
    payload = [iFrameBits, blockBits, coeffBits, bitIdxBits];
    chk_calc = mod(sum(payload), 256);
    chk_read = sum(chkBits .* (2.^(7:-1:0)));
    
    fprintf('chk_calc = %d, chk_read = %d\n', chk_calc, chk_read);
end
