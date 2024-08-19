% Pool data
% 
% Uses util functions from fly_on_the_ball_analysis.mlapp

clear, clc

% Settings
settings.genotype = ''; 
settings.stimulus_pre_win = 300; % Frames
settings.stimulus_post_win = 300; % Frames
settings.treadmill = 1;
settings.stimulus_duration = 1;
settings.stimulus_intensity = 0;
settings.resting = 0;
settings.walking = 1;
settings.FL_grooming = 0;

% Load csv file with data overview
csv = readtable('C:\Users\Chris\Desktop\fly-on-the-ball_data.csv','Delimiter',',');
n_trials = height(csv);

% Load config file
path_config = 'config.toml';
config = toml.read(path_config);
config = toml.map_to_struct(config);
config.reference_sampling_rate = config.camera.sampling_rate;
config.dir.data = config.dir.daq_data;   

x_velocity = [];
n_trials_total = 0;

% Loop over trials
for iTrial = 1:n_trials
    if strcmp(csv.genotype{iTrial},settings.genotype) ...
            && csv.treadmill(iTrial) == settings.treadmill ...
            && csv.stimulus_duration(iTrial) == settings.stimulus_duration ...
            && csv.stimulus_intensity(iTrial) == settings.stimulus_intensity ...
            && csv.resting(iTrial) == settings.resting ...
            && csv.walking(iTrial) == settings.walking ...
            && csv.FL_grooming(iTrial) == settings.FL_grooming

        include_trial = true;
    else
        include_trial = false;       
    end

    if include_trial
        n_trials_total = n_trials_total+1;

        % Set directory
        config.experiment = csv.experiment{iTrial};
        config.trial_name = [csv.experiment{iTrial},'_',sprintf( '%03d',csv.trial(iTrial))];
                
        disp(['Processing ',config.trial_name])

        % Load DAQ data
        load([config.dir.data,config.experiment,'/',config.trial_name,'.mat']);
        daq_data = trial_data;
        clearvars trial_data
        
        % Process DAQ data
        [time,camera_data,treadmill_data,stimulus_data] = utils_process_daq_data(daq_data,config);
        
        % Process treadmill data
        treadmill_data = utils_process_treadmill_data(treadmill_data,config);     

        % Store data  
        stimulus_onset = find(stimulus_data>-8,1,'first');
        x_velocity(:,n_trials_total) = treadmill_data.x_velocity(stimulus_onset-settings.stimulus_pre_win : stimulus_onset+settings.stimulus_post_win-1);
       
        clearvars daq_data treadmill_data stimulus_onset 
    end
end

figure
imagesc(x_velocity')
c = colorbar; 
c.Label.String = 'Velocity (mm/s)'; 
xlabel('Frames')
ylabel('Trials')

figure
plot(mean(x_velocity,2))
xlabel('Frames')
ylabel('Velocity (mm/s)')
set(gca,'Color','none')