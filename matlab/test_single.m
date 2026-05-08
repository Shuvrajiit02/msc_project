clc; clear;

channel = randi([0, 255], 352, 288, 'uint8');
channel = double(channel);

[LL1, LH1, HL1, HH1] = dwt2(channel, 'haar');
[LL2, LH2, HL2, HH2] = dwt2(LL1, 'haar');
dctBand = dct2(LH2);

orig_val = dctBand(5, 5);

orig_val_single = double(single(orig_val));

dctBand(5, 5) = orig_val_single;

LH2_rec  = idct2(dctBand);
LL1_rec  = idwt2(LL2, LH2_rec, HL2, HH2, 'haar');
channelR = idwt2(LL1_rec, LH1, HL1, HH1, 'haar');

channelR = min(max(channelR, 0), 255);
channelR = uint8(channelR);
channel_orig = uint8(channel);

mse_val = immse(channel_orig, channelR);
disp(['MSE with single precision: ', num2str(mse_val)]);
