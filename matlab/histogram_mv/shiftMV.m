function [mvx_new, mvy_new] = shiftMV(mvx, mvy, peakX, peakY)

mvx_new = mvx;
mvy_new = mvy;

for i = 1:numel(mvx)

    x = mvx(i);
    y = mvy(i);

    % Shift rule (horizontal shifting around peak)
    if x > peakX
        mvx_new(i) = x + 1;
    elseif x < peakX
        mvx_new(i) = x - 1;
    end

    % Optional vertical shifting (can enable if needed)
    % if y > peakY
    %     mvy_new(i) = y + 1;
    % elseif y < peakY
    %     mvy_new(i) = y - 1;
    % end

end

end