clc; clear;

orig = load('../data/aux_bits.txt');
ext = load('../data/extracted_aux_bits.txt');

orig = orig(:)';
ext = ext(:)';

for i = 1:length(orig)
    if ext(i) ~= orig(i)
        fprintf('Mismatch at index %d! orig=%d, ext=%d\n', i, orig(i), ext(i));
        fprintf('Context around orig: %s\n', num2str(orig(max(1, i-5):min(length(orig), i+10))));
        fprintf('Context around ext:  %s\n', num2str(ext(max(1, i-5):min(length(ext), i+10))));
        break;
    end
end
