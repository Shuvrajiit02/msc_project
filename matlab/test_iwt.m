clc; clear;

channel = randi([10, 240], 352, 288, 'uint8');
channel_d = double(channel);

LS = liftwave('haar', 'Int2Int');

[CA1, CH1, CV1, CD1] = lwt2(channel_d, LS);
[CA2, CH2, CV2, CD2] = lwt2(CA1, LS);

orig_val = CH2(10, 10);
CH2(10, 10) = orig_val + 5; % Small integer change

CA1_rec = ilwt2(CA2, CH2, CV2, CD2, LS);
channelR = ilwt2(CA1_rec, CH1, CV1, CD1, LS);

is_clipped = any(channelR(:) < 0) || any(channelR(:) > 255);
disp(['Is clipped: ', num2str(is_clipped)]);

channelR_uint8 = uint8(channelR);

% Reverse
channel_rev = double(channelR_uint8);
[rCA1, rCH1, rCV1, rCD1] = lwt2(channel_rev, LS);
[rCA2, rCH2, rCV2, rCD2] = lwt2(rCA1, LS);

rCH2(10, 10) = orig_val;

rCA1_rec = ilwt2(rCA2, rCH2, rCV2, rCD2, LS);
channel_rev_R = ilwt2(rCA1_rec, rCH1, rCV1, rCD1, LS);

channel_rev_uint8 = uint8(channel_rev_R);

mse_val = immse(channel, channel_rev_uint8);
disp(['MSE: ', num2str(mse_val)]);
