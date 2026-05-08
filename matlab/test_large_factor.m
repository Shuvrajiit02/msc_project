clc; clear;

channel = randi([1, 254], 352, 288, 'uint8');
channel_d = double(channel);

[LL1, LH1, HL1, HH1] = dwt2(channel_d, 'haar');
[LL2, LH2, HL2, HH2] = dwt2(LL1, 'haar');
dctBand = dct2(LH2);

orig_val = dctBand(10, 10);
dctBand(10, 10) = orig_val + 150;

LH2_rec = idct2(dctBand);
LL1_rec = idwt2(LL2, LH2_rec, HL2, HH2, 'haar');
channelR = idwt2(LL1_rec, LH1, HL1, HH1, 'haar');

channelR_uint8 = uint8(min(max(channelR, 0), 255));

% Reverse
channel_rev = double(channelR_uint8);
[rLL1, rLH1, rHL1, rHH1] = dwt2(channel_rev, 'haar');
[rLL2, rLH2, rHL2, rHH2] = dwt2(rLL1, 'haar');
rDctBand = dct2(rLH2);

rDctBand(10, 10) = orig_val;

rLH2_rec = idct2(rDctBand);
rLL1_rec = idwt2(rLL2, rLH2_rec, rHL2, rHH2, 'haar');
channel_rev_R = idwt2(rLL1_rec, rLH1, rHL1, rHH1, 'haar');

channel_rev_uint8 = uint8(min(max(channel_rev_R, 0), 255));

mse_val = immse(channel, channel_rev_uint8);
disp(['MSE: ', num2str(mse_val)]);
