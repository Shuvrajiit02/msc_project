clc; clear;

% Generate a random image, but force some pixels to be near the boundaries
channel = randi([1, 254], 352, 288, 'uint8');
channel(10,10) = 255;
channel(20,20) = 0;

channel_d = double(channel);

[LL1, LH1, HL1, HH1] = dwt2(channel_d, 'haar');
[LL2, LH2, HL2, HH2] = dwt2(LL1, 'haar');
dctBand = dct2(LH2);

% Embed a massive change that WILL cause clipping if we don't check
orig_val = dctBand(5, 5);
new_val = orig_val + 500; % Massive delta
dctBand(5, 5) = new_val;

% Reconstruct
LH2_rec = idct2(dctBand);
LL1_rec = idwt2(LL2, LH2_rec, HL2, HH2, 'haar');
channelR = idwt2(LL1_rec, LH1, HL1, HH1, 'haar');

% Check for clipping
is_clipped = any(channelR(:) < 0) || any(channelR(:) > 255);
disp(['Is clipped: ', num2str(is_clipped)]);

channelR_uint8 = uint8(min(max(channelR, 0), 255));

% Now Reverse
channel_rev = double(channelR_uint8);
[rLL1, rLH1, rHL1, rHH1] = dwt2(channel_rev, 'haar');
[rLL2, rLH2, rHL2, rHH2] = dwt2(rLL1, 'haar');
rDctBand = dct2(rLH2);

% Restore exact original
rDctBand(5, 5) = orig_val;

% Reconstruct reverse
rLH2_rec = idct2(rDctBand);
rLL1_rec = idwt2(rLL2, rLH2_rec, rHL2, rHH2, 'haar');
channel_rev_R = idwt2(rLL1_rec, rLH1, rHL1, rHH1, 'haar');

channel_rev_uint8 = uint8(min(max(channel_rev_R, 0), 255));

mse_val = immse(channel, channel_rev_uint8);
disp(['MSE after reversal (with massive change): ', num2str(mse_val)]);


% Now do a small change that does NOT cause clipping
dctBand2 = dct2(LH2);
orig_val2 = dctBand2(10, 10);
dctBand2(10, 10) = orig_val2 + 10; % Small delta

LH2_rec2 = idct2(dctBand2);
LL1_rec2 = idwt2(LL2, LH2_rec2, HL2, HH2, 'haar');
channelR2 = idwt2(LL1_rec2, LH1, HL1, HH1, 'haar');

is_clipped2 = any(channelR2(:) < -0.5) || any(channelR2(:) > 255.5);
disp(['Is clipped 2: ', num2str(is_clipped2)]);

channelR_uint82 = uint8(min(max(channelR2, 0), 255));

% Reverse
channel_rev2 = double(channelR_uint82);
[rLL1_2, rLH1_2, rHL1_2, rHH1_2] = dwt2(channel_rev2, 'haar');
[rLL2_2, rLH2_2, rHL2_2, rHH2_2] = dwt2(rLL1_2, 'haar');
rDctBand2 = dct2(rLH2_2);

rDctBand2(10, 10) = orig_val2;

rLH2_rec2 = idct2(rDctBand2);
rLL1_rec2 = idwt2(rLL2_2, rLH2_rec2, rHL2_2, rHH2_2, 'haar');
channel_rev_R2 = idwt2(rLL1_rec2, rLH1_2, rHL1_2, rHH1_2, 'haar');

channel_rev_uint82 = uint8(min(max(channel_rev_R2, 0), 255));

mse_val2 = immse(channel, channel_rev_uint82);
disp(['MSE after reversal (no clipping): ', num2str(mse_val2)]);
