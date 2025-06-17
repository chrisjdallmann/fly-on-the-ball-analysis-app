

trials = {'2024-09-16_A07_010'};

start_frame = 600;
end_frame = 900;
edges = -5:2:25;
probability_legs_in_stance = zeros(length(edges)-1, 6, numel(trials));

% Load config file
path_config = 'C:\Users\Chris\Documents\GitHub\fly-on-the-ball-analysis-app\config.toml';
config = toml.read(path_config);
config = toml.map_to_struct(config);
config.reference_sampling_rate = config.camera.sampling_rate;
config.dir.data = config.dir.daq_data;   

% Loop over trials
for iTrial = 1:numel(trials)
    
     % Set directory
    config.trial_name = trials{iTrial};
    config.experiment = config.trial_name(1:end-4);

    % Load DAQ data
    load([config.dir.data,config.experiment,'/',config.trial_name,'.mat']);
    daq_data = trial_data;
    clearvars trial_data
    
    % Process DAQ data
    [time,~,treadmill_data,stimulus_data] = utils_process_daq_data(daq_data,config);
    %config.last_frame = length(time); % For utils_process_deeplabcut_data()
    
    % Process treadmill data
    treadmill_data = utils_process_treadmill_data(treadmill_data,config);
    
    % Load swing classification
    swing_classification = csvread([config.dir.data,config.experiment,'/cameras/',config.trial_name,'_swing_classification.csv']);
           
    legs_in_stance = 6-sum(swing_classification(start_frame:end_frame,:),2);
    velocity = treadmill_data.x_velocity(start_frame:end_frame);

    for iLeg = 1:6
        leg_in_stance_index = find(legs_in_stance==iLeg);
        
        if ~isempty(leg_in_stance_index)
            leg_in_stance_velocity = velocity(leg_in_stance_index);
    
            % Store data    
            probability_legs_in_stance(:,iLeg,iTrial) = histcounts( ...
                leg_in_stance_velocity,edges,'normalization','probability');
        end
    end
end

bins = edges(1:end-1)+2;
figure
hold on
for iLeg = 1:6
    plot(bins, mean(probability_legs_in_stance(:,iLeg,:),2))
end
hold off
legend({'1','2','3','4','5','6'})
set(gca,'Color','none')
ylim([-0.1,1.1])
xlabel('Fwd velocity (mm/s)')
ylabel('Probability')
