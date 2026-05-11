function y = intdct4(x)
    % 2D Integer DCT on a 4x4 block using lifting (Int2Int)
    x = double(x);
    for i = 1:4
        x(i,:) = intdct1d(x(i,:));
    end
    for j = 1:4
        x(:,j) = intdct1d(x(:,j)')';
    end
    y = x;
end

function y = intdct1d(x)
    % Stage 1: Butterflies
    d0 = x(1) - x(4);
    s0 = x(4) + floor(d0/2);
    
    d1 = x(2) - x(3);
    s1 = x(3) + floor(d1/2);
    
    % Stage 2:
    % y0, y2 from s0, s1
    y2 = s0 - s1;
    y0 = s1 + floor(y2/2);
    
    % y1, y3 from d0, d1 (Rotation approx)
    % Use a reversible rotation lifting
    d1 = d1 + floor(0.5 * d0);
    d0 = d0 - floor(1.0 * d1);
    d1 = d1 + floor(0.5 * d0);
    
    y = [y0, d1, y2, d0];
end
