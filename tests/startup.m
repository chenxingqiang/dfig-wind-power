% Add paths
addpath(pwd);  % Add current directory
addpath(fullfile(pwd, '..'));  % Add parent directory
addpath(fullfile(pwd, '../simulation'));  % Add simulation directory
addpath(fullfile(pwd, '../controllers'));  % Add controllers directory
addpath(fullfile(pwd, '../models'));  % Add models directory
addpath(fullfile(pwd, '../utils'));  % Add utils directory

% Initialize workspace
clear all; close all; clc;

% Display startup message
disp('DFIG Wind Power System Test Environment');
disp('=====================================');
disp('Available commands:');
disp('  run_all_tests      - Run complete test suite');
disp('  run_load_tests     - Run only load step tests');
disp('  run_fault_tests    - Run only fault tests');
disp('');

% Check if required toolboxes are available
v = ver;
required_toolboxes = {'MATLAB', 'Simulink', 'Control System Toolbox'};
missing_toolboxes = {};

for i = 1:length(required_toolboxes)
    if ~any(strcmp({v.Name}, required_toolboxes{i}))
        missing_toolboxes{end+1} = required_toolboxes{i};
    end
end

if ~isempty(missing_toolboxes)
    warning('Missing required toolboxes:');
    for i = 1:length(missing_toolboxes)
        warning('  - %s', missing_toolboxes{i});
    end
end

% Initialize Simulink
if exist('init_simulink.m', 'file')
    init_simulink;
end 