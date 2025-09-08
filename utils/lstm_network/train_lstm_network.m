% TRAIN_LSTM_NETWORK.m prepares data to train an LSTM network
% 
% Files required:
%   training_data_*.mat
% 
% Functions/toolboxes required:
%   training_partitions.m
%   Deep Learning Toolbox
% 
% See also prepare_training_data.m

% Author: Chris J. Dallmann
% Affiliation: University of Wuerzburg
% Last revision: 08-September-2025

% ------------- BEGIN CODE ------------- 

clear, clc

network_name = 'I3_swing_offset';

% Set save path
save_path = ['C:\Users\Chris\Documents\GitHub\fly-on-the-ball-analysis-app\' ...
    'utils\lstm_network\',network_name,'_net.mat'];

% Load data
load(['training_data_',network_name,'.mat']);

% Partition data into training and test
n_observations = numel(data);
[idx_train,idx_test] = training_partitions(n_observations,[0.9 0.1]);
x_train = data(idx_train);
t_train = labels(idx_train);
x_test = data(idx_test);
t_test = labels(idx_test);

% Prepare data for padding (optional)
%
% Note: Relevant if training sequences have different lengths. During
% training, the software splits the training data into mini-batches and
% pads the sequences so that they have the same length. Too much padding
% can have a negative impact on network performance. To prevent the
% training process from adding too much padding, sort the training data by
% sequence length, and choose a mini-batch size so that sequences in a
% mini-batch have a similar length.

% % Get sequence lengths
% n_observations = numel(x_train);
% for i=1:n_observations
%     sequence = x_train{i};
%     sequence_lengths(i) = size(sequence,2);
% end

% % Sort by sequence length
% [sequence_lengths,idx] = sort(sequence_lengths);
% x_train = x_train(idx);
% t_train = t_train(idx);

% figure
% bar(sequence_lengths)
% xlabel("Sequence")
% ylabel("Length")

% Define LSTM network architecture
n_channels = size(data{1},1); % Feature dimension
n_hidden_units = 60;
n_classes = numel(unique(labels)); 

layers = [
    sequenceInputLayer(n_channels)
    bilstmLayer(n_hidden_units, OutputMode="last")
    fullyConnectedLayer(n_classes)
    softmaxLayer
    classificationLayer];

% Specify training options
options = trainingOptions("adam", ... % Use Adam solver
    MaxEpochs = 200, ... % Train for 200 epochs
    InitialLearnRate = 0.001,... % Set learning rate; default for Adam is 0.001
    GradientThreshold = 1, ... % Clip the gradients with a threshold of 1
    Shuffle = "once", ... "never", % Disable shuffling to keep sequences sorted by length; set "never" when sorted  
    Plots = "training-progress", ... % Display training progress      
    Verbose = false, ... % Disable the verbose output
    Plots = 'training-progress'); 

% Train LSTM network
net = trainNetwork(x_train,t_train,layers,options);

% Classify the test data
y_test = classify(net,x_test);
accuracy = mean(y_test == t_test);

% Plot confusion matrix
figure
confusionchart(t_test,y_test)

% Save network
save(save_path,'net')

