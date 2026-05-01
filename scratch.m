addpath('matlab');
addpath('matlab/serialization');
bits = load('data/extracted_aux_bits.txt');
disp(size(bits));
disp(['First 20 bits: ', num2str(bits(1:20)')]);
p = deserializePinfo(bits);
disp(['Recovered packets: ', num2str(length(p))]);
