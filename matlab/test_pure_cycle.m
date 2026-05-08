clc; clear;

channel = randi([0, 255], 352, 288, 'uint8');
channel_d = double(channel);

[LL1, LH1, HL1, HH1] = dwt2(channel_d, 'haar');
[LL2, LH2, HL2, HH2] = dwt2(LL1, 'haar');
dctBand = dct2(LH2);

LH2_rec  = idct2(dctBand);
LL1_rec  = idwt2(LL2, LH2_rec, HL2, HH2, 'haar');
channelR = idwt2(LL1_rec, LH1, HL1, HH1, 'haar');

channelR_uint8 = uint8(min(max(channelR, 0), 255));

mse_val = immse(channel, channelR_uint8);
disp(['MSE of pure transform cycle: ', num2str(mse_val)]);
