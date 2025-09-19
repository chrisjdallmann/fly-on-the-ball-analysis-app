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
% Last revision: 19-September-2025

% ------------- BEGIN CODE ------------- 

clear, clc

disp('Preparing training data...')

% Load csv file with metadata and training frames  
data = readtable('training_frames_swing.csv','Delimiter',',');

save_path = ['C:\Users\Chris\Documents\GitHub\fly-on-the-ball-analysis-app\utils\lstm_network\' ...
    'training_data_I3_swing_offset.mat'];
target_leg = '[3]';
target_class = 'swing_offset';
prepare_swing_data = true;
sliding_window_name = 'sliding_window_swing';
plot_data = false;

if prepare_swing_data
   data = data(strcmp(data.leg,target_leg),:);
   data.class(~strcmp(data.class,target_class)) = {'other'};
end

% Load config file
path_config = 'config.toml';
config = toml.read(path_config);
config = toml.map_to_struct(config);
config.reference_sampling_rate = config.camera.sampling_rate;
config.dir.data = config.dir.daq_data;   

% Select sliding window
sliding_window = config.classification.(sliding_window_name);
pre_win = sliding_window/2; 
post_win = sliding_window/2-1; 

lstm_data = {};
lstm_label = {};

if plot_data
    h = figure;
end

% Loop over sequences
n_sequences = length(data.trial);
n_sequence = 0;
for iSequence = 1:n_sequences
    
    % Set directory
    config.trial_name = data.trial{iSequence};
    config.experiment = config.trial_name(1:end-4);

    % Load DAQ data
    load([config.dir.data,config.experiment,'/',config.trial_name,'.mat']);
    daq_data = trial_data;
    clearvars trial_data

    % Process DAQ data
    [time,camera_data,~,~] = utils_process_daq_data(daq_data,config);
    config.last_frame = length(time); % For utils_process_deeplabcut_data()

    % Get frame
    frame = data.frame(iSequence);
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
        frame = data.frame(iSequence);
        camera_index = str2num(data.camera{iSequence});
        leg_index = str2num(data.leg{iSequence});
        feature_1 = [];
        feature_2 = [];
        for iCamera = 1:numel(camera_index)
            camera_name = config.camera.camera_names{camera_index(iCamera)};
            camera_orientation = config.camera.camera_orientations{strcmp(config.camera.camera_names,camera_name)};
            if strcmp(camera_orientation,'left')
                label = 'L';
            else
                label = 'R';
            end
            for iLeg = 1:numel(leg_index)
                feature_1 = [feature_1, camera_data.([label,num2str(leg_index(iLeg)),'_leg_vector_velocity'])(frame-pre_win : frame+post_win)];
                feature_2 = [feature_2, camera_data.([label,num2str(leg_index(iLeg)),'E_y_velocity'])(frame-pre_win : frame+post_win)];
            end
        end
          
        n_sequence = n_sequence+1;

        % Prepare LSTM label
        class_label = data.class{n_sequence};
        
        % Store data and labels
        lstm_data{n_sequence,1} = [feature_1, feature_2]'; %feature'; %[feature_1, feature_2]';
        lstm_labels{n_sequence,1} = class_label;
    
        % Plot feature
        if plot_data
            figure(h), clf
            plot(lstm_data{n_sequence}')
            legend({'Feature 1','Feature 2'})
            title(lstm_labels{n_sequence},'Interpreter','none')
            xlabel('Frame')
            ylabel('Feature')
            set(gca,'Color','none')
        end
    end
end

% Save data and labels 
lstm.data = lstm_data;
lstm.labels = categorical(lstm_labels);

save(save_path,'-struct','lstm')

disp('Done!')

summary(lstm.labels)

% Plot all sequences of a class
if plot_data
    figure
    hold on
    for i = 1:numel(lstm.labels)
        if strcmp(lstm_labels(i),target_class)
            plot(lstm_data{i}')
        end
    end
    hold off
    xlabel('Frame')
    ylabel('Feature')
    ylim([-5,5])
    set(gca,'Color','none')
end


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
