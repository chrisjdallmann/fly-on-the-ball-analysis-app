% UTILS_POOL_DATA.m pools data from experiments of interests  
% 
% Files required:
%   trial_metadata.csv
% 
% Functions/toolboxes required:
%   utils_process_daq_data.m
%   utils_process_treadmill_data.m
%   matlab-toml

% Author: Chris J. Dallmann
% Affiliation: University of Wuerzburg
% Last revision: 19-September-2025

% ------------- BEGIN CODE ------------- 

clear, clc

% Settings
settings.save_path = '';
settings.genotype = '';  
settings.include = 1;  
settings.stim_duration = 1;
settings.treadmill = 1;
settings.stim_intensity = [-3,0];
settings.resting = 1;
settings.walking = 0;
settings.t1_grooming = 0;
settings.t3_grooming = 0;
settings.flight = 0;

settings.stimulus_pre_win = 300; % Frames
settings.stimulus_post_win = 300; % Frames

settings.parameters = {'animal_id', 'animal_sex', 'frame', 'time', 'stimulus', ...
    'resting', 'walking', 'grooming', 'flight', 'other', ...
    'forward_velocity', 'lateral_velocity', 'angular_velocity', ...
    'swing_L1', 'swing_L2', 'swing_L3', ...
    'swing_R1', 'swing_R2', 'swing_R3'};

% Load metatdata file
trial_metadata = readtable('C:\Users\Chris\Desktop\trial_metadata.csv','Delimiter',',');

% Trim metadata file to relevant data
trials_to_include = sum([contains(trial_metadata.genotype, settings.genotype), ...
    (trial_metadata.include == settings.include), ...
    (trial_metadata.stim_duration == settings.stim_duration), ...
    (trial_metadata.resting == settings.resting), ...
    (trial_metadata.walking == settings.walking), ...
    (trial_metadata.t1_grooming == settings.t1_grooming), ...
    (trial_metadata.t3_grooming == settings.t3_grooming), ...
    (trial_metadata.flight == settings.flight)],2) == 8;
trial_metadata = trial_metadata(trials_to_include,:);

% Load config file
path_config = 'config.toml';
config = toml.read(path_config);
config = toml.map_to_struct(config);
config.reference_sampling_rate = config.camera.sampling_rate;
config.dir.data = config.dir.daq_data;   

% Initialize pooled data 
pooled_data = [];
for parameter = 1:numel(settings.parameters)
    pooled_data.(settings.parameters{parameter}) = [];  
end


% Loop over trials
n_trials = height(trial_metadata);
n_trials_total = 0;
for trial = 1:n_trials

    % Set directory
    config.experiment = trial_metadata.experiment{trial};
    config.trial_name = [trial_metadata.experiment{trial},'_',sprintf( '%03d',trial_metadata.trial(trial))];
            
    disp(['Processing ',config.trial_name])

    % Load DAQ data
    daq_data = load([config.dir.data,config.experiment,'/',config.trial_name,'.mat']);
    trial_data.daq_data = daq_data.trial_data;
    clearvars daq_data
    
    % Process DAQ data
    [trial_data.time, trial_data.camera_data, trial_data.treadmill_data, trial_data.stimulus_data] = utils_process_daq_data(trial_data.daq_data, config);
    
    % Process treadmill data
    trial_data.treadmill_data = utils_process_treadmill_data(trial_data.treadmill_data, config);     

    % Load behavior classification 
    % Columns: Analyze, resting, walking, grooming with front legs, 
    % grooming with hind legs, ball pushing, other leg movements, 
    % flight, annotation 
    trial_data.behavior = readtable([config.dir.data,config.experiment,'/cameras/',config.trial_name,'_classification_behavior.csv']);
    trial_data.behavior = table2array(trial_data.behavior);

    % Load swing classification
    if any(contains(settings.parameters,'swing'))
        trial_data.swing = readtable([config.dir.data,config.experiment,'/cameras/',config.trial_name,'_classification_swing.csv']);
        trial_data.swing = table2array(trial_data.swing);
    end

    % Prepare data  
    trial_data.n_frames = numel(trial_data.time);
    trial_data.animal_id = repmat(trial_metadata.animal_id(trial),trial_data.n_frames,1);
    trial_data.animal_sex = trial_metadata.sex(trial);
    if strcmp(trial_data.animal_sex,'f')
        trial_data.animal_sex = repmat({'female'},trial_data.n_frames,1);
    else
        trial_data.animal_sex = repmat({'male'},trial_data.n_frames,1);
    end
    trial_data.frame = (1:numel(trial_data.time))';
    trial_data.time = trial_data.time';
    trial_data.stimulus = trial_data.stimulus_data';
    trial_data.resting = trial_data.behavior(:,2);
    trial_data.walking = trial_data.behavior(:,3);
    trial_data.grooming = trial_data.behavior(:,4) + trial_data.behavior(:,5); 
    trial_data.other = trial_data.behavior(:,6) + trial_data.behavior(:,7);
    trial_data.flight = trial_data.behavior(:,8);
    
    if any(contains(settings.parameters,'velocity'))
        trial_data.forward_velocity = trial_data.treadmill_data.x_velocity';
        trial_data.lateral_velocity = trial_data.treadmill_data.y_velocity';
        trial_data.angular_velocity = trial_data.treadmill_data.z_velocity';
    end

    if any(contains(settings.parameters,'swing'))
        trial_data.swing_L1 = trial_data.swing(:,1);
        trial_data.swing_L2 = trial_data.swing(:,2);
        trial_data.swing_L3 = trial_data.swing(:,3);
        trial_data.swing_R1 = trial_data.swing(:,4);
        trial_data.swing_R2 = trial_data.swing(:,5);
        trial_data.swing_R3 = trial_data.swing(:,6);
    end
    
    % Store data
    for parameter = 1:numel(settings.parameters)
        pooled_data.(settings.parameters{parameter}) = [...
            pooled_data.(settings.parameters{parameter});...
            trial_data.(settings.parameters{parameter})];  
    end

    clearvars trial_data
end

% Save data
T = struct2table(pooled_data);
writetable(T, settings.save_path)
disp(['Data saved as ',settings.save_path])
