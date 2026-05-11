clc; clear;

h = 144; w = 176;
channel = double(randi([0 255], h, w));
ls = liftwave('haar', 'Int2Int');

[LL1, LH1, HL1, HH1] = lwt2(channel, ls);
[LL2, LH2, HL2, HH2] = lwt2(LL1, ls);

LL1_rec = ilwt2(LL2, LH2, HL2, HH2, ls);
channelR = ilwt2(LL1_rec, LH1, HL1, HH1, ls);

mse = mean((channel(:) - channelR(:)).^2);
fprintf('Cycle MSE (176x144): %e\n', mse);
if mse > 0
    fprintf('Size check: orig [%d %d], recv [%d %d]\n', size(channel), size(channelR));
end
