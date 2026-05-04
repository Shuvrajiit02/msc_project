clc; clear;

if exist('../data/extracted_aux_bits.txt', 'file') == 2
    bits = load('../data/extracted_aux_bits.txt');
    bits = bits(:)';
    fprintf('Loaded %d bits from extracted_aux_bits.txt\n', length(bits));
    
    PinfoRecovered = deserializePinfo(bits);
    fprintf('deserializePinfo returned %d entries.\n', length(PinfoRecovered));
    
    if ~isempty(PinfoRecovered)
        for i = 1:min(5, length(PinfoRecovered))
            fprintf('Rec %d: frame=%d, block=%d, coeff=%d, bitIdx=%d\n', ...
                i, PinfoRecovered(i).iFrame, PinfoRecovered(i).block, ...
                PinfoRecovered(i).coeffIdx, PinfoRecovered(i).bitIdx);
        end
    end
end
