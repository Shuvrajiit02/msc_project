function bits = textToBits(text)

bits = [];

for i = 1:length(text)
    binChar = dec2bin(uint8(text(i)), 8) - '0';
    bits = [bits binChar];
end

end