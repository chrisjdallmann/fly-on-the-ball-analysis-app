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
% Last revision: 19-February-2025

% ------------- BEGIN CODE ------------- 

clear, clc

disp('Preparing training data...')

% Load csv file with metadata and training frames  
csv = readtable('training_frames_behavior.csv','Delimiter',',');
n_sequences = length(csv.trial);

save_path = ['C:\Users\Chris\Documents\GitHub\fly-on-the-ball-analysis-app\utils\lstm_network\' ...
    'training_data_behavior.mat'];

% Load config file
path_config = 'config.toml';
config = toml.read(path_config);
config = toml.map_to_struct(config);
config.reference_sampling_rate = config.camera.sampling_rate;
config.dir.data = config.dir.daq_data;   

sliding_window = config.classification.sliding_window_behavior;
pre_win = sliding_window/2; %20; %10; % Frames
post_win = sliding_window/2-1; %19; %9; % Frames

lstm_data = {};
lstm_label = {};

h = figure;

% Loop over sequences
n_sequence = 0;
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

    % Get frame
    frame = csv.frame(iSequence);
    if frame-pre_win <= 0
        disp([config.trial_name, ': frame=', num2str(frame), ' is too small'])
    elseif frame+post_win > config.last_frame
        disp([config.trial_name, ': frame=', num2str(frame), ' is too large'])
    else
        
        % Process DeepLabCut data
        for iCamera = 1:numel(config.camera.camera_names)
            camera_name = config.camera.camera_names{iCamera};
            config.camera.(['is_',camera_name]) = true;
            config.camera.(['is_data_',camera_name]) = true;
        end
        camera_data = utils_process_deeplabcut_data(camera_data,config);
    
        % Prepare LSTM data
        frame = csv.frame(iSequence);
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
                feature = [feature, camera_data.([label,num2str(iLeg),'_leg_vector_velocity'])(frame-pre_win : frame+post_win)];
            end
        end
          
        n_sequence = n_sequence+1;

        % Prepare LSTM label
        class_label = csv.class{n_sequence};
    
        % Store data and labels
        lstm_data{n_sequence,1} = feature'; %[feature_1, feature_2]';
        lstm_labels{n_sequence,1} = class_label;
    
        % Plot feature
        figure(h), clf
        plot(lstm_data{n_sequence}','k')
        title(lstm_labels{n_sequence},'Interpreter','none')
        xlabel('Frame')
        ylabel('Feature')
        set(gca,'Color','none')
    end
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
