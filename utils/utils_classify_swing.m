function target_frames = utils_classify_swing(x,net,sliding_window)
%function [swing_onsets, swing_offsets] = utils_classify_swing(x,net,sliding_window)
% UTILS_CLASSIFY_SWING.m uses an LSTM network to identify patterns in time series data x
% 
% Functions/toolboxes required:
%   Deep Learning Toolbox

% Author: Chris J. Dallmann
% Affiliation: University of Wuerzburg
% Last revision: 07-October-2024

% ------------- BEGIN CODE ------------- 

%sliding_window = 20; % Same length as window used for training the network
target_score_threshold = 0.96; 

% Load LSTM network
load(net);

% Add padding to avoid edge artifacts
x_padded = [x, zeros(1,sliding_window)];

% Slide over x to generate test data  
x_test = {};
for iWin = 1:size(x_padded,2)-sliding_window 
    x_win = x_padded(:, iWin:iWin+sliding_window-1);
    x_test{iWin,1} = x_win; 
end

% Classify data
[~,scores] = classify(net,x_test);
target_scores = scores(:,2);

% Find frames whith best scores  
target_frames = islocalmax(target_scores,'MinProminence',0.5); 
target_frames = double(target_frames);
target_frames = find(target_frames>0);

% Threshold target frames
target_frames(target_scores(target_frames)<target_score_threshold) = [];

% Shift classifications by half the sliding window
target_frames = target_frames+round(sliding_window/2);

% Remove target frames in padded region
target_frames(target_frames>numel(x)) = [];


% % When using a single network for onset and offset classification
% target_scores = scores(:,2:3);
% 
% % Find frames whith best scores  
% target_frames = islocalmax(target_scores,'MinProminence',0.5); 
% target_frames = double(target_frames);
% 
% swing_onsets = find(target_frames(:,2)>0);
% swing_offsets = find(target_frames(:,1)>0);
% 
% % Threshold target frames
% swing_onsets(target_scores(swing_onsets,2)<target_score_threshold) = [];
% swing_offsets(target_scores(swing_offsets,1)<target_score_threshold) = [];
% 
% % Shift classifications by half the sliding window
% swing_onsets = swing_onsets+round(sliding_window/2);
% swing_offsets = swing_offsets+round(sliding_window/2);
% 
% % Remove target frames in padded region
% swing_onsets(swing_onsets>numel(x)) = [];
% swing_offsets(swing_offsets>numel(x)) = [];

end