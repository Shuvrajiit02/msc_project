clc; clear;
addpath('utils');

block = [1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 16];
dct = intdct4(block);
disp('DCT:');
disp(dct);
ib = intidct4(dct);
disp('IDCT:');
disp(ib);
disp(['Diff: ', num2str(sum(abs(block(:) - ib(:))))]);
