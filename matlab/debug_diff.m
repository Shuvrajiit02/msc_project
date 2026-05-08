clc; clear;

load('../data/test_dump.mat', 'video', 'recoveredVideo'); % Wait, I don't have a dump. I'll just run main logic briefly

% Actually, I'll just load the first frame and process it
fprintf('Debugging exact pixel differences...\n');
