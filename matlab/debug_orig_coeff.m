clc; clear;
addpath('utils');
addpath('serialization');

bits = load('../data/extracted_aux_bits.txt');
Pinfo = deserializePinfo(bits);

if ~isempty(Pinfo)
    fprintf('Recovered %d Pinfo entries.\n', length(Pinfo));
    if isfield(Pinfo, 'origCoeff')
        fprintf('First origCoeff: %f\n', Pinfo(1).origCoeff);
    else
        fprintf('Error: origCoeff field missing!\n');
    end
else
    fprintf('Error: No Pinfo recovered!\n');
end
