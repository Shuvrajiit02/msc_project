function video = loadMP4(filename, maxFrames)

v = VideoReader(filename);

video = struct('Y', {}, 'Cb', {}, 'Cr', {});

frameCount = 0;

while hasFrame(v)

    if frameCount >= maxFrames
        break;
    end

    frameRGB = readFrame(v);
    frameYCbCr = rgb2ycbcr(frameRGB);

    video(frameCount+1).Y  = double(frameYCbCr(:,:,1));
    video(frameCount+1).Cb = double(frameYCbCr(:,:,2));
    video(frameCount+1).Cr = double(frameYCbCr(:,:,3));

    frameCount = frameCount + 1;
end

end