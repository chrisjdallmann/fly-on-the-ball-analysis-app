function treadmill_data = utils_process_treadmill_data(treadmill_data,config)
% UTILS_PROCESS_TREADMILL_DATA.m calculates velocities and virtual path from treadmill data  

% Author: Chris J. Dallmann
% Affiliation: University of Wuerzburg
% Last revision: 23-September-2024

% ------------- BEGIN CODE ------------- 

% Treadmill coordinate system: x points forward, y points leftward, z
% points upward. Thus, negative x corresponds to forward stepping, negative
% y corresponds to left side stepping, and negative z corresponds to
% leftward turning.
x_velocity_V = treadmill_data.x_velocity_V * -1;
y_velocity_V = treadmill_data.y_velocity_V * -1;
z_velocity_V = treadmill_data.z_velocity_V * -1;

% Downsample from reference sampling rate to treadmill sampling rate
n = double(config.reference_sampling_rate)/double(config.treadmill.sampling_rate);
x_velocity_V = x_velocity_V(1:n:end);
y_velocity_V = y_velocity_V(1:n:end);
z_velocity_V = z_velocity_V(1:n:end);

% Convert velocities from V/s to mm/s or deg/s
%
% In the treadmill setup, 56 counts/s corresponds to 1 ball
% revolution/s.
% 128 counts/s corresponds to 5 V/s, thus 56 counts/s = 2.1875 V/s.
%
% 1 revolution corresponds to the circumference of
% ball, which is 2*pi*r = 2*pi*3 mm = 18.8496 mm.
% Thus, 2.1875 V/s = 18.8496 mm/s, or 1 V/s = 8.6170 mm/s.
%
% 1 rad corresponds to 2*pi = 6.2832.
% Thus, 2.1875 V/s = 6.2832 rad/s, or 1 V/s = 2.8723 rad/s.
%
% 1 revolution corresponds to 360 deg.
% Thus, 2.1875 V/s = 360 deg/s, or 1 V/s = 164.5714 deg/s.
V_to_mm = 8.6170; % Sander: 8.79
V_to_rad = 2.8723; % Same as V_to_mm/3
V_to_deg = 164.5714;

x_velocity_mm = x_velocity_V * V_to_mm;
y_velocity_mm = y_velocity_V * V_to_mm;
z_velocity_deg = z_velocity_V * V_to_deg;
z_velocity_rad = z_velocity_V * V_to_rad;

% Calculate virtual path
n_frames = numel(x_velocity_mm);
x_position_mm = x_velocity_mm/50;
y_position_mm = y_velocity_mm/50;
z_heading_rad = z_velocity_rad/50;

% path = [z in rad, x in mm, y in mm]
path = nan(n_frames+1,3);
path(1,:) = [0,0,0];

for iFrame = 1:n_frames
    current_theta = path(iFrame,1);
    current_x = path(iFrame,2);
    current_y = path(iFrame,3);

    % Heading
    theta = current_theta + z_heading_rad(iFrame)*-1;

    % Calculate x position in coordinate system rotated by theta
    x = current_x ...
        + (x_position_mm(iFrame)) * cos(theta) ...
        + (y_position_mm(iFrame)) * sin(theta);

    % Calculate y position in coordinate system rotated by theta
    y = current_y ...
        - (x_position_mm(iFrame)) * sin(theta) ...
        + (y_position_mm(iFrame)) * cos(theta);

    path(iFrame+1,:) = [theta, x, y];
end
path = path(1:end-1,:);

% Upsample from treadmill sampling rate to reference sampling rate
x = 1:numel(x_velocity_mm);
xx = linspace(1,numel(x_velocity_mm), ...
    double(config.reference_sampling_rate)/double(config.treadmill.sampling_rate)*numel(x_velocity_mm));

treadmill_data.x_velocity = spline(x,x_velocity_mm,xx);
treadmill_data.y_velocity = spline(x,y_velocity_mm,xx);
treadmill_data.z_velocity = spline(x,z_velocity_deg,xx);

treadmill_data.heading = spline(x,path(:,1),xx);
treadmill_data.x_path = spline(x,path(:,2),xx);
treadmill_data.y_path = spline(x,path(:,3),xx);

end