function saveFrames(video, outputFolder)

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

numFrames = length(video);

for i = 1:numFrames

    Y  = double(video(i).Y);
    Cb = double(video(i).Cb);
    Cr = double(video(i).Cr);

    % Clip
    Y  = min(max(Y, 0), 255);
    Cb = min(max(Cb, 0), 255);
    Cr = min(max(Cr, 0), 255);

    % Combine
    ycbcrFrame = uint8(cat(3, Y, Cb, Cr));

    % Convert
    rgb = ycbcr2rgb(ycbcrFrame);

    imwrite(rgb, fullfile(outputFolder, sprintf('frame_%04d.png', i)));

end

fprintf('[SaveFrames] Done\n');

end