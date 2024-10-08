% PREPARE_TRAINING_DATA.m prepares data to train an LSTM network
% 
% Files required:
%   training_frames.csv
%   config.toml
% 
% Functions/toolboxes required:
%   utils_process_daq_data.m
%   utils_process_deeplabcut_data.m
%   toml Toolbox
% 
% See also train_lstm_network.m

% Author: Chris J. Dallmann
% Affiliation: University of Wuerzburg
% Last revision: 07-October-2024

% ------------- BEGIN CODE ------------- 

clear, clc

disp('Preparing training data...')

% Load csv file with metadata and training frames  
csv = readtable('training_frames_behavior.csv','Delimiter',',');
n_sequences = length(csv.trial);

save_path = 'training_data_behavior.mat';
pre_win = 20; %10; % Frames
post_win = 19; %9; % Frames

% Load config file
path_config = 'config.toml';
config = toml.read(path_config);
config = toml.map_to_struct(config);
config.reference_sampling_rate = config.camera.sampling_rate;
config.dir.data = config.dir.daq_data;   

lstm_data = {};
lstm_label = {};

h = figure;

% Loop over sequences
for iSequence = 1:n_sequences

    % Set directory
    config.trial_name = csv.trial{iSequence};
    config.experiment = config.trial_name(1:end-4);

    % Load DAQ data
    load([config.dir.data,config.experiment,'/',config.trial_name,'.mat']);
    daq_data = trial_data;
    clearvars trial_data

    % Process DAQ data
    [time,camera_data,~,~] = utils_process_daq_data(daq_data,config);
    config.last_frame = length(time); % For utils_process_deeplabcut_data()

    % Process DeepLabCut data
    for iCamera = 1:numel(config.camera.camera_names)
        camera_name = config.camera.camera_names{iCamera};
        config.camera.(['is_',camera_name]) = true;
        config.camera.(['is_data_',camera_name]) = true;
    end
    camera_data = utils_process_deeplabcut_data(camera_data,config);

    % Prepare LSTM data
    start_frame = csv.start_frame(iSequence);
    camera_index = str2num(csv.camera{iSequence});
    leg_index = str2num(csv.leg{iSequence});
    feature = [];
    for iCamera = 1:numel(camera_index)
        camera_name = config.camera.camera_names{camera_index(iCamera)};
        camera_orientation = config.camera.camera_orientations{strcmp(config.camera.camera_names,camera_name)};
        if strcmp(camera_orientation,'left')
            label = 'L';
        else
            label = 'R';
        end
        for iLeg = 1:numel(leg_index)
            feature = [feature, camera_data.([label,num2str(iLeg),'_leg_vector_velocity'])(start_frame-pre_win : start_frame+post_win)];
        end
    end

    % Prepare LSTM label
    class_label = csv.class{iSequence};

    % Store data and labels
    lstm_data{iSequence,1} = feature'; %[feature_1, feature_2]';
    lstm_labels{iSequence,1} = class_label;

    % Plot feature
    figure(h), clf
    plot(lstm_data{iSequence}','k')
    title(lstm_labels{iSequence},'Interpreter','none')
    xlabel('Frame')
    ylabel('Feature')
    set(gca,'Color','none')
end

% Save data and labels 
lstm.data = lstm_data;
lstm.labels = categorical(lstm_labels);

save(save_path,'-struct','lstm')

disp('Done!')

% % Inspect LSTM data and labels
% h = figure;
% for i = 1:numel(lstm_data)
%     figure(h), clf
%     plot(lstm_data{i}','k')
%     title(lstm_labels{i},'Interpreter','none')
%     xlabel('Frame')
%     ylabel('Feature')
%     set(gca,'Color','none')
%     pause()
% end
