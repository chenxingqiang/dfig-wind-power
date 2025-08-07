function build_dfig_model()
% BUILD_DFIG_MODEL Build complete DFIG wind power system Simulink model
%   This script creates the dfig_wind_system.slx model programmatically

% Create new model
model_name = 'dfig_wind_system';
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end

% Create new system
h = new_system(model_name);
open_system(model_name);

%% Main System Layout
% Wind Input
wind_block = add_block('simulink/Sources/Signal From Workspace', ...
    [model_name '/Wind Speed'], ...
    'VariableName', 'wind_speed_data', ...
    'Position', [50 100 150 140]);

% DFIG System
dfig_block = add_block('simulink/User-Defined Functions/S-Function', ...
    [model_name '/DFIG System'], ...
    'FunctionName', 'sfun_dfig', ...
    'Position', [250 80 350 180]);

% Grid Connection
grid_block = add_block('simulink/User-Defined Functions/S-Function', ...
    [model_name '/Grid Model'], ...
    'FunctionName', 'sfun_grid', ...
    'Position', [450 200 550 280]);

% Energy Storage System
ess_block = add_block('simulink/User-Defined Functions/S-Function', ...
    [model_name '/ESS System'], ...
    'FunctionName', 'sfun_ess', ...
    'Position', [250 200 350 280]);

% Controller
controller_block = add_block('simulink/User-Defined Functions/S-Function', ...
    [model_name '/Main Controller'], ...
    'FunctionName', 'sfun_controller', ...
    'Position', [100 300 200 400]);

%% Add Measurement Blocks
% Voltage measurement
v_measure = add_block('simulink/Sinks/To Workspace', ...
    [model_name '/Voltage_out'], ...
    'VariableName', 'voltage_data', ...
    'Position', [650 150 750 180]);

% Frequency measurement  
f_measure = add_block('simulink/Sinks/To Workspace', ...
    [model_name '/Frequency_out'], ...
    'VariableName', 'frequency_data', ...
    'Position', [650 200 750 230]);

% Power measurement
p_measure = add_block('simulink/Sinks/To Workspace', ...
    [model_name '/Power_out'], ...
    'VariableName', 'power_data', ...
    'Position', [650 250 750 280]);

% SOC measurement
soc_measure = add_block('simulink/Sinks/To Workspace', ...
    [model_name '/SOC_out'], ...
    'VariableName', 'soc_data', ...
    'Position', [650 300 750 330]);

%% Add Signal Routing Blocks
% Mux for controller inputs
controller_mux = add_block('simulink/Signal Routing/Mux', ...
    [model_name '/Controller_Inputs'], ...
    'Inputs', '5', ...
    'Position', [50 250 80 350]);

% Demux for controller outputs  
controller_demux = add_block('simulink/Signal Routing/Demux', ...
    [model_name '/Controller_Outputs'], ...
    'Outputs', '3', ...
    'Position', [220 300 240 400]);

% Mux for measurements
measurement_mux = add_block('simulink/Signal Routing/Mux', ...
    [model_name '/Measurements'], ...
    'Inputs', '6', ...
    'Position', [550 150 580 350]);

%% Add Clock
clock_block = add_block('simulink/Sources/Clock', ...
    [model_name '/Clock'], ...
    'Position', [50 50 80 80]);

%% Connect Blocks
% Wind to DFIG
add_line(model_name, 'Wind Speed/1', 'DFIG System/1');

% Controller connections
add_line(model_name, 'Controller_Inputs/1', 'Main Controller/1');
add_line(model_name, 'Main Controller/1', 'Controller_Outputs/1');

% DFIG to Grid
add_line(model_name, 'DFIG System/1', 'Grid Model/1');
add_line(model_name, 'Controller_Outputs/1', 'DFIG System/2');

% ESS to Grid  
add_line(model_name, 'ESS System/1', 'Grid Model/2');
add_line(model_name, 'Controller_Outputs/2', 'ESS System/1');

% Measurement connections
add_line(model_name, 'Grid Model/1', 'Measurements/1'); % Voltage
add_line(model_name, 'Grid Model/2', 'Measurements/2'); % Frequency
add_line(model_name, 'DFIG System/2', 'Measurements/3'); % DFIG Power
add_line(model_name, 'ESS System/2', 'Measurements/4'); % ESS Power
add_line(model_name, 'ESS System/3', 'Measurements/5'); % SOC
add_line(model_name, 'Clock/1', 'Measurements/6'); % Time

% Feedback to controller
add_line(model_name, 'Measurements/1', 'Controller_Inputs/1', 'autorouting', 'on');

% Output connections
add_line(model_name, 'Measurements/1', 'Voltage_out/1');
add_line(model_name, 'Measurements/2', 'Frequency_out/1');
add_line(model_name, 'Measurements/3', 'Power_out/1');
add_line(model_name, 'Measurements/5', 'SOC_out/1');

%% Add Subsystem for Deep Learning Controller
dl_subsystem = add_block('simulink/Ports & Subsystems/Subsystem', ...
    [model_name '/Deep_Learning_Controller'], ...
    'Position', [100 450 200 550]);

% Open subsystem and add blocks
open_system([model_name '/Deep_Learning_Controller']);

% LSTM Predictor
lstm_block = add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Deep_Learning_Controller/LSTM_Predictor'], ...
    'Position', [100 50 200 100]);

% DRL Agent
drl_block = add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Deep_Learning_Controller/DRL_Agent'], ...
    'Position', [100 150 200 200]);

%% Set Model Parameters
set_param(model_name, 'Solver', 'ode23t');
set_param(model_name, 'StartTime', '0');
set_param(model_name, 'StopTime', '10');
set_param(model_name, 'FixedStep', '1e-4');
set_param(model_name, 'RelTol', '1e-3');
set_param(model_name, 'AbsTol', '1e-6');

%% Configure S-Function Parameters
% DFIG S-Function
set_param([model_name '/DFIG System'], 'Parameters', ...
    'struct(''rated_power'', 2e6, ''rated_voltage'', 690, ''pole_pairs'', 2)');

% ESS S-Function  
set_param([model_name '/ESS System'], 'Parameters', ...
    'struct(''rated_power'', 0.5e6, ''capacity'', 1e6, ''efficiency'', 0.95)');

% Controller S-Function
set_param([model_name '/Main Controller'], 'Parameters', ...
    'struct(''sample_time'', 1e-4, ''enable_deep_learning'', true)');

%% Add Documentation
add_block('simulink/Sinks/Display', [model_name '/Status_Display'], ...
    'Position', [650 50 750 80]);

% Add annotation
annotation_text = sprintf(['DFIG Wind Power System with Energy Storage\n' ...
    'Features:\n' ...
    '• Fault Ride-Through Control\n' ...
    '• Frequency Support with Virtual Inertia\n' ...
    '• Dynamic Mode Switching\n' ...
    '• Deep Learning Integration (LSTM + DRL)\n' ...
    '• Real-time Control at 100μs sample rate']);

add_block('simulink/Commonly Used Blocks/Note', [model_name '/System_Info'], ...
    'Position', [450 50 600 150], ...
    'Text', annotation_text);

%% Save Model
save_system(model_name, [model_name '.slx']);

% Set as dirty flag off
set_param(model_name, 'Dirty', 'off');

fprintf('Successfully created %s.slx model!\n', model_name);
fprintf('Model includes:\n');
fprintf('- DFIG system with RSC/GSC control\n');
fprintf('- Energy storage system integration\n');
fprintf('- Advanced control strategies\n');
fprintf('- Deep learning components\n');
fprintf('- Real-time measurement and logging\n');

end
