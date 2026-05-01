bits = load('data/extracted_aux_bits.txt');
sync = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];
res = strfind(bits(:)', sync);
disp(['Found sync words: ', num2str(length(res))]);
