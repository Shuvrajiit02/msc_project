function psnrVal = computeVideoPSNR_Cb(video1, video2)

numFrames = min(length(video1), length(video2));
mse = 0;
count = 0;

for i = 1:numFrames

    A = double(video1(i).Cb);
    B = double(video2(i).Cb);

    diff = A - B;

    mse = mse + mean(diff(:).^2);
    count = count + 1;
end

mse = mse / count;

if mse == 0
    psnrVal = Inf;
else
    psnrVal = 10 * log10(255^2 / mse);
end

end