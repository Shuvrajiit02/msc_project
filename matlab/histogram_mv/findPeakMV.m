function [peakX, peakY, peakCount] = findPeakMV(hist2D, xVals, yVals)

% Find max value in histogram
[peakCount, idx] = max(hist2D(:));

% Convert to indices
[row, col] = ind2sub(size(hist2D), idx);

% Map back to motion vector values
peakX = xVals(row);
peakY = yVals(col);

end