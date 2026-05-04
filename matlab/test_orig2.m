clc; clear;

orig = load('../data/aux_bits.txt');
orig = orig(:)';
fprintf('Bits 1 to 100: %s\n', num2str(orig(1:100)));
