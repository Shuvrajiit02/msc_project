function recoveredVideo = reverseWatermark(wmVideo, Pinfo, params)

fprintf('[Reverse] Starting reversal...\n');

recoveredVideo = wmVideo;
numFrames = length(wmVideo);

if isempty(Pinfo)
    warning('[Reverse] No Pinfo recovered.');
    return;
end

% Group Pinfo by frame for efficient/lossless processing
uFrames = unique([Pinfo.iFrame]);

for fIdx = 1:length(uFrames)
    f = uFrames(fIdx);
    
    if f < 1 || f > numFrames, continue; end
    
    % Find all packets for this frame
    framePackets = Pinfo([Pinfo.iFrame] == f);
    
    if strcmpi(params.channel, 'Cb')
        channel = double(wmVideo(f).Cb);
    else
        channel = double(wmVideo(f).Cr);
    end

    % Setup Lifting Scheme for IWT
    ls = liftwave(params.wavelet, 'Int2Int');

    [LL1, LH1, HL1, HH1] = lwt2(channel, ls);
    [LL2, LH2, HL2, HH2] = lwt2(LL1, ls);
    
    LH2_rec = LH2; % We will modify this

    blk = params.blockSize;
    [h, w] = size(LH2);
    blocksPerRow = floor(w / blk);
    if blocksPerRow == 0, continue; end

    % Apply all restorations for this frame
    for p = 1:length(framePackets)
        blockID  = round(framePackets(p).block);
        coeffIdx = round(framePackets(p).coeffIdx);
        
        bi = floor((blockID - 1) / blocksPerRow) * blk + 1;
        bj = mod((blockID - 1), blocksPerRow) * blk + 1;

        if bi+blk-1 > h || bj+blk-1 > w || coeffIdx > blk*blk, continue; end

        % Get block and apply Integer DCT to restore
        curr_block = LH2_rec(bi:bi+blk-1, bj:bj+blk-1);
        block_dct = intdct4(curr_block);
        
        if isfield(framePackets(p), 'origCoeff')
            block_dct(coeffIdx) = double(framePackets(p).origCoeff);
        else
            % Fallback for legacy data
            val = block_dct(coeffIdx);
            block_dct(coeffIdx) = sign(val) * 0; 
        end
        
        % Inverse Integer DCT and update LH2_rec
        LH2_rec(bi:bi+blk-1, bj:bj+blk-1) = intidct4(block_dct);
    end

    % Inverse transform ONCE per frame
    LL1_rec = ilwt2(LL2, LH2_rec, HL2, HH2, ls);
    channelR = ilwt2(LL1_rec, LH1, HL1, HH1, ls);
    
    channelR = uint8(min(max(channelR, 0), 255));
    
    if strcmpi(params.channel, 'Cb')
        recoveredVideo(f).Cb = channelR;
    else
        recoveredVideo(f).Cr = channelR;
    end
end

fprintf('[Reverse] Reversal complete.\n');

end