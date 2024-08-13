function [time,camera_data,treadmill_data,stimulus_data] = utils_process_daq_data(daq_data,config)
%Utility function for fly_on_the_ball_analysis.mlapp
%   Downsamples DAQ data to reference sampling rate

x = 1:size(daq_data,1);
xx = linspace(1,size(daq_data,1), ...
    double(config.reference_sampling_rate)/double(config.daq.sampling_rate)*size(daq_data,1));

time = spline(x,seconds(daq_data.Time),xx);
camera_data.camera_frames = spline(x,daq_data.([config.daq.name,'_',config.daq.channel_camera_01]),xx);
treadmill_data.x_velocity_V = spline(x,daq_data.([config.daq.name,'_',config.daq.channel_treadmill_x]),xx);
treadmill_data.y_velocity_V = spline(x,daq_data.([config.daq.name,'_',config.daq.channel_treadmill_y]),xx);
treadmill_data.z_velocity_V = spline(x,daq_data.([config.daq.name,'_',config.daq.channel_treadmill_z]),xx);
stimulus_data = spline(x,daq_data.([config.daq.name,'_',config.daq.channel_stimulus]),xx);

end