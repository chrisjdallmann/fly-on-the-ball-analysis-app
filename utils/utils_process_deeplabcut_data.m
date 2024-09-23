function camera_data = utils_process_deeplabcut_data(camera_data,config)
% UTILS_PROCESS_DEEPLABCUT_DATA.m processes 2D tracking data from DeepLabCut 
% 
% Functions/toolboxes required:
%   h5read.m

% Author: Chris J. Dallmann
% Affiliation: University of Wuerzburg
% Last revision: 23-September-2024

% ------------- BEGIN CODE ------------- 

for iCamera = 1:numel(config.camera.camera_names)
    camera_name = config.camera.camera_names{iCamera};
    if config.camera.(['is_data_',camera_name])
        % Load data
        h5_data = h5read( ...
            [config.dir.data, ...
            config.experiment, ...
            config.camera.folder_videos, ...
            config.trial_name, '_',...
            camera_name, ...
            config.deeplabcut.model_name,'.h5'], ...
            '/df_with_missing/table');
        fields = fieldnames(h5_data);

        temp_camera_data = h5_data.(fields{end})';

        % Trim data to length of trial
        temp_camera_data(config.last_frame+1:end,:) = [];

        % Python starts indexing at 0, Matlab at 1. Therefore,
        % add 1 to all keypoint coordinates.
        temp_camera_data(1:3:end) = temp_camera_data(1:3:end)+1;
        temp_camera_data(2:3:end) = temp_camera_data(2:3:end)+1;

        % Apply median filter (helps with single-frame
        % outliers)
        keypoint_names = config.deeplabcut.keypoint_names;
        for iKeypoint = 1:numel(keypoint_names)
            keypoint_indices = double(config.deeplabcut.keypoint_indices{iKeypoint});
            temp_camera_data_filtered(:,keypoint_indices) = ...
                medfilt1(temp_camera_data(:,keypoint_indices));
        end

        % Apply 
        % % Quick fix for video export
        % for iKeypoint = [2,3,5,10,15]
        %     keypoint_indices = double(app.config.deeplabcut.keypoint_indices{iKeypoint});
        %     temp_camera_data_filtered(:,keypoint_indices) = ...
        %         repmat(mean(temp_camera_data_filtered(:,keypoint_indices)),size(temp_camera_data_filtered,1),1);
        % end

        camera_data.(['data_',camera_name]) = temp_camera_data;
        camera_data.(['data_',camera_name,'_filtered']) = temp_camera_data_filtered;

        % Calculate virtual leg features (leg vector between joints A and E) 
        keypoints = {{'I1A','I1E'},{'I2A','I2E'},{'I3A','I3E'}};
        for iLeg = 1:3
            % Calculate leg vector
            x_values = [];
            y_values = [];
            for iKeypoint = 1:numel(keypoints{iLeg})
                keypoint_indices = double(config.deeplabcut.keypoint_indices{strcmp(keypoint_names,keypoints{iLeg}{iKeypoint})});
                x_values(:,iKeypoint) = temp_camera_data_filtered(:,keypoint_indices(1));
                y_values(:,iKeypoint) = temp_camera_data_filtered(:,keypoint_indices(2));
            end
            leg_vector = [x_values(:,2)-x_values(:,1), y_values(:,2)-y_values(:,1)];
            leg_vector_video_position = [x_values(:,1), x_values(:,2), y_values(:,1), y_values(:,2)];

            % Calculate angle relative to vertical 
            reference_vector = repmat([0,1],size(leg_vector,1),1);
            for iFrame = 1:size(leg_vector,1)
                x1 = leg_vector(iFrame,1);
                y1 = leg_vector(iFrame,2);
                x2 = reference_vector(iFrame,1);
                y2 = reference_vector(iFrame,2);
                leg_vector_angle(iFrame,:) = atan2d(x1*y2-y1*x2,x1*x2+y1*y2);
            end
            
            % Filter angle
            leg_vector_angle = smooth(leg_vector_angle,5);
            
            % Calculate derivative
            leg_vector_velocity = [0; diff(leg_vector_angle) ./ (1000/double(config.reference_sampling_rate))]; % deg/s
    
            camera_orientation = config.camera.camera_orientations{iCamera};
            if strcmp(camera_orientation,'left')
                label = 'L';
            else
                label = 'R';
            end
            camera_data.([label,num2str(iLeg),'_leg_vector']) = leg_vector;
            camera_data.([label,num2str(iLeg),'_leg_vector_angle']) = leg_vector_angle;
            camera_data.([label,num2str(iLeg),'_leg_vector_velocity']) = leg_vector_velocity;
            camera_data.([label,num2str(iLeg),'_leg_vector_video_position']) = leg_vector_video_position;
        
        end
        clearvars h5_data temp_camera_data temp_camera_data_filtered
    end
    clearvars camera_name
end
clearvars iCamera

end