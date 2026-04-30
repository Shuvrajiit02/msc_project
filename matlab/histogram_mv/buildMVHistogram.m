function [hist2D, xVals, yVals] = buildMVHistogram(mvx, mvy)

% Flatten motion vectors
mvx = mvx(:);
mvy = mvy(:);

% Define range (important for consistency)
xMin = min(mvx); xMax = max(mvx);
yMin = min(mvy); yMax = max(mvy);

xVals = xMin:xMax;
yVals = yMin:yMax;

hist2D = zeros(length(xVals), length(yVals));

% Build histogram
for i = 1:length(mvx)
    xi = mvx(i) - xMin + 1;
    yi = mvy(i) - yMin + 1;
    hist2D(xi, yi) = hist2D(xi, yi) + 1;
end

end