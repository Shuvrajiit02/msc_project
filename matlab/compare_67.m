clc; clear;

addpath('../matlab/utils');
addpath('../matlab/serialization');

orig = load('../data/aux_bits.txt');
orig = orig(:)';
ext = load('../data/extracted_aux_bits.txt');
ext = ext(:)';

fprintf('First 67 bits orig: %s\n', num2str(orig(1:67)));
fprintf('First 67 bits ext:  %s\n', num2str(ext(1:67)));

disp(['orig sum = ', num2str(sum(orig(1:67)))]);
disp(['ext sum  = ', num2str(sum(ext(1:67)))]);

PinfoRec = deserializePinfo(orig);
disp(['orig recovered: ', num2str(length(PinfoRec))]);

PinfoRecExt = deserializePinfo(ext);
disp(['ext recovered: ', num2str(length(PinfoRecExt))]);
