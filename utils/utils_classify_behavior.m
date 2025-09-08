function target_frames = utils_classify_behavior(x,net,sliding_window)
% UTILS_CLASSIFY_BEHAVIOR.m uses an LSTM network to identify patterns in time series data x
% 
% Functions/toolboxes required:
%   Deep Learning Toolbox

% Author: Chris J. Dallmann
% Affiliation: University of Wuerzburg
% Last revision: 08-September-2025

% ------------- BEGIN CODE ------------- 

%sliding_window = 40; % Same length as window used for training the network
target_score_threshold = 0.9;

% Load LSTM network
load(net);

% Add padding to avoid edge artifacts
x_padded = [repmat(x(:,1),1,sliding_window/2), x, repmat(x(:,end),1,sliding_window/2)];

% Slide over x to generate test data  
x_test = {};
for iWin = 1:size(x_padded,2)-sliding_window 
    x_win = x_padded(:, iWin:iWin+sliding_window-1);
    x_test{iWin,1} = x_win; 
end

% Classify data
[~,scores] = classify(net,x_test);

target_frames = scores;

% Threshold target frames
target_frames = double(target_frames>target_score_threshold);

% Assign unclassified frames (gaps) to previous classification
% To do: Implement exception for beginning of trial and consider hysteresis
% filter instead or in addition
for iFrame = 2:size(target_frames,1)
    if sum(target_frames(iFrame,:)) == 0
        target_frames(iFrame,:) = target_frames(iFrame-1,:); 
    end
end

end