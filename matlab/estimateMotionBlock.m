function mv = estimateMotionBlock(currFrame, refFrame, blockPos, blockSize, searchRange)

x = blockPos(1);
y = blockPos(2);

[h, w] = size(refFrame);

currBlock = currFrame(x:x+blockSize-1, y:y+blockSize-1);

bestSAD = Inf;
bestMV  = [0 0];

for dx = -searchRange:searchRange
    for dy = -searchRange:searchRange

        rx = x + dx;
        ry = y + dy;

        if rx < 1 || ry < 1 || ...
           rx+blockSize-1 > h || ry+blockSize-1 > w
            continue;
        end

        refBlock = refFrame(rx:rx+blockSize-1, ry:ry+blockSize-1);

        sad = sum(abs(currBlock(:) - refBlock(:)));

        if sad < bestSAD
            bestSAD = sad;
            bestMV  = [dx dy];
        end
    end
end

mv = bestMV;

end