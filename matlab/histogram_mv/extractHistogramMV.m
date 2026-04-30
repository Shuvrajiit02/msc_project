function bits = extractHistogramMV(mvx, mvy)

bits = [];

if mvx == 1 && mvy == 0
    bits = 1;
elseif mvx == 0 && mvy == 0
    bits = 0;
end

% Reverse shift
if mvx > 1
    mvx = mvx - 1;
elseif mvx < -1
    mvx = mvx + 1;
end

end