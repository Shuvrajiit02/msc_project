function [mvx, mvy] = embedHistogramMV(mvx, mvy, bits)

persistent bitIdx;
if isempty(bitIdx)
    bitIdx = 1;
end

if bitIdx > length(bits)
    return;
end

% Assume peak at (0,0)
if mvx == 0 && mvy == 0

    if bits(bitIdx) == 1
        mvx = mvx + 1;
    end

    bitIdx = bitIdx + 1;

elseif mvx > 0
    mvx = mvx + 1;
elseif mvx < 0
    mvx = mvx - 1;
end

end