function test_full_reversibility()
    clc; clear;
    addpath('utils');
    addpath('serialization');
    
    videoFile = '../videos/input/foreman.mp4';
    video = loadMP4(videoFile, 5); % Just 5 frames
    
    params.wavelet = 'haar';
    params.dwtLevel = 2;
    params.blockSize = 4;
    params.embedFactor = 150;
    params.nnzThreshold = 1;
    params.energyThreshold = 0.5;
    params.channel = 'Cb';
    params.searchRange = 8;
    params.redundancy = 4;
    
    watermarkBits = [1 0 1 0 1 1 1 1];
    
    [wmVideo, embedLog, Pinfo] = embedWatermark(video, watermarkBits, 1, params);
    
    % Simulate perfect metadata transport
    recoveredVideo = reverseWatermark(wmVideo, Pinfo, params);
    
    mse = computeVideoPSNR_Cb(video, recoveredVideo);
    
    if isinf(mse)
        disp('Perfect Reversibility Achieved!');
    else
        disp(['PSNR: ', num2str(mse)]);
    end
end
