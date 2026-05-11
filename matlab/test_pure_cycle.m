clc; clear;

channel = double(randi([0 255], 256, 256));
ls = liftwave('haar', 'Int2Int');

[LL1, LH1, HL1, HH1] = lwt2(channel, ls);
[LL2, LH2, HL2, HH2] = lwt2(LL1, ls);

LL1_rec = ilwt2(LL2, LH2, HL2, HH2, ls);
channelR = ilwt2(LL1_rec, LH1, HL1, HH1, ls);

mse = mean((channel(:) - channelR(:)).^2);
fprintf('Cycle MSE: %e\n', mse);

block = randi([-100 100], 4, 4);
ib = intidct4(intdct4(block));
mse_dct = mean((block(:) - ib(:)).^2);
fprintf('DCT MSE: %e\n', mse_dct);
