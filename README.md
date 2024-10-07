# fly-on-the-ball-analysis-app
MATLAB app for analyzing fly-on-the-ball experiments.

This is work in progress. Currently, users can play recorded videos, manually label and export key points for individual video frames (for DeepLabCut), and automatically detect fly behavior and swing phases of the legs with LSTM networks. The settings are specified in `config.toml`.   

## Requirements 
The code was tested with MATLAB R2023a. It requires the packages [matlab-toml](https://www.mathworks.com/matlabcentral/fileexchange/67858-matlab-toml) and [export_fig](https://www.mathworks.com/matlabcentral/fileexchange/23629-export_fig) in the MATLAB path. Training and using the LSTM networks requires the Deep Learning Toolbox.