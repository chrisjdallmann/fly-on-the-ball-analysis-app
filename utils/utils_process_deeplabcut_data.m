function camera_data = utils_process_deeplabcut_data(camera_data,config)
%Utility function for fly_on_the_ball_analysis.mlapp
%   Loads and filteres DeepLabCut data 

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

        % % Quick fix for video export
        % for iKeypoint = [2,3,5,10,15]
        %     keypoint_indices = double(app.config.deeplabcut.keypoint_indices{iKeypoint});
        %     temp_camera_data_filtered(:,keypoint_indices) = ...
        %         repmat(mean(temp_camera_data_filtered(:,keypoint_indices)),size(temp_camera_data_filtered,1),1);
        % end

        camera_data.(['data_',camera_name]) = temp_camera_data;
        camera_data.(['data_',camera_name,'_filtered']) = temp_camera_data_filtered;

        clearvars h5_data temp_camera_data temp_camera_data_filtered
    end
    clearvars camera_name
end
clearvars iCamera

end