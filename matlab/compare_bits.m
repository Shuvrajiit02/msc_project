clc; clear;

orig = load('../data/aux_bits.txt');
ext = load('../data/extracted_aux_bits.txt');

orig = orig(:)';
ext = ext(:)';

% Look for the first 100 bits of orig inside ext
pattern = orig(1:100);
idx = strfind(num2str(ext, '%d'), num2str(pattern, '%d'));
if ~isempty(idx)
    fprintf('Found 100-bit perfect match at string index %d!\n', idx(1));
else
    fprintf('No perfect match for the first 100 bits.\n');
    % Try first 30 bits
    pattern = orig(1:30);
    idx = strfind(num2str(ext, '%d'), num2str(pattern, '%d'));
    if ~isempty(idx)
        fprintf('Found 30-bit perfect match at string index %d!\n', idx(1));
    else
        fprintf('No perfect match for the first 30 bits.\n');
    end
end
