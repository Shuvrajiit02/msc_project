function text = bitsToText(bits)

bits = bits(:)'; % ensure row vector

numChars = floor(length(bits) / 8);
text = '';

for i = 1:numChars
    byte = bits((i-1)*8+1:i*8);
    charVal = bin2dec(num2str(byte));
    text = [text char(charVal)];
end

end