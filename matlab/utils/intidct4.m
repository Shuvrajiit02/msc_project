function y = intidct4(x)
    % 2D Integer Inverse DCT on a 4x4 block using lifting (Int2Int)
    x = double(x);
    for j = 1:4
        x(:,j) = intidct1d(x(:,j)')';
    end
    for i = 1:4
        x(i,:) = intidct1d(x(i,:));
    end
    y = x;
end

function y = intidct1d(x)
    y0 = x(1);
    d1 = x(2);
    y2 = x(3);
    d0 = x(4);
    
    % Inverse Stage 2: Rotation
    d1 = d1 - floor(0.5 * d0);
    d0 = d0 + floor(1.0 * d1);
    d1 = d1 - floor(0.5 * d0);
    
    % Inverse Stage 2: Haar
    s1 = y0 - floor(y2 / 2);
    s0 = y2 + s1;
    
    % Inverse Stage 1: Butterflies
    x3 = s1 - floor(d1 / 2);
    x2 = d1 + x3;
    
    x4 = s0 - floor(d0 / 2);
    x1 = d0 + x4;
    
    y = [x1, x2, x3, x4];
end
