clc; clear;

addpath('../matlab/serialization');

Pinfo(1).iFrame = 1;
Pinfo(1).block = 100;
Pinfo(1).coeffIdx = 5;
Pinfo(1).bitIdx = 10;
Pinfo(1).pFrame = 2;

bits = serializePinfo(Pinfo);
disp(['Serialized bits: ', num2str(bits)]);

PinfoRec = deserializePinfo(bits);
disp(['Recovered entries: ', num2str(length(PinfoRec))]);
