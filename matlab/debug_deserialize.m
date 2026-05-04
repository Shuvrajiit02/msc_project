clc; clear;

if exist('../data/extracted_aux_bits.txt', 'file') == 2
    bits = load('../data/extracted_aux_bits.txt');
    bits = bits(:)';
    fprintf('Loaded %d bits from extracted_aux_bits.txt\n', length(bits));
    
    % Let's manually scan for the sync word
    sync_word = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];
    sync_len = length(sync_word);
    
    sync_count = 0;
    valid_count = 0;
    
    for i = 1:length(bits) - sync_len - 51
        if isequal(bits(i:i+sync_len-1), sync_word)
            sync_count = sync_count + 1;
            
            idx = i + sync_len;
            payload = bits(idx : idx+42);
            chkBits = bits(idx+43 : idx+50);
            
            chk_calc = mod(sum(payload), 256);
            chk_read = sum(chkBits .* (2.^(7:-1:0)));
            
            if chk_calc == chk_read
                valid_count = valid_count + 1;
            end
        end
    end
    
    fprintf('Found %d sync words.\n', sync_count);
    fprintf('Found %d valid checksums.\n', valid_count);
    
    if valid_count == 0 && sync_count > 0
        % Let's print the first payload and checksum to see what's wrong
        idx = find(strfind(num2str(bits, '%d'), num2str(sync_word, '%d')), 1);
        if ~isempty(idx)
            % strfind returns index ignoring spaces?
            % Easier:
            for i = 1:length(bits) - sync_len - 51
                if isequal(bits(i:i+sync_len-1), sync_word)
                    idx = i + sync_len;
                    payload = bits(idx : idx+42);
                    chkBits = bits(idx+43 : idx+50);
                    chk_calc = mod(sum(payload), 256);
                    chk_read = sum(chkBits .* (2.^(7:-1:0)));
                    fprintf('First sync at %d. calc=%d, read=%d\n', i, chk_calc, chk_read);
                    fprintf('Payload sum = %d\n', sum(payload));
                    fprintf('Checksum bits = %s\n', num2str(chkBits, '%d'));
                    break;
                end
            end
        end
    end
else
    fprintf('No extracted bits file.\n');
end
