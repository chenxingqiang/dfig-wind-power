function gui_parameter_config()
%GUI_PARAMETER_CONFIG DFIG System Parameter Configuration GUI
% Interactive GUI for configuring DFIG wind power system parameters
%
% Features:
% • DFIG parameters (power, voltage, speed)
% • ESS parameters (capacity, SOC limits, response time)  
% • Control parameters (FRT, frequency control, mode switching)
% • Deep learning configuration (LSTM, DRL settings)
% • Real-time parameter validation
% • Export/Import configuration files
% • Direct integration with simulation

%% Create Main GUI Figure
fig = figure('Name', 'DFIG System Parameter Configuration v2.0', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'figure', ...
    'Position', [100, 100, 1200, 800], ...
    'Resize', 'on', ...
    'CloseRequestFcn', @closeGUI);

% Store GUI data
setappdata(fig, 'params', load_default_parameters());
setappdata(fig, 'modified', false);

%% Create Tab Group
tabgroup = uitabgroup(fig, 'Position', [0.02 0.15 0.96 0.83]);

%% Create Tabs
tab1 = create_dfig_tab(tabgroup);
tab2 = create_ess_tab(tabgroup);  
tab3 = create_control_tab(tabgroup);
tab4 = create_deeplearning_tab(tabgroup);
tab5 = create_simulation_tab(tabgroup);

%% Create Control Panel
create_control_panel(fig);

%% Initialize GUI with default values
refresh_gui(fig);

fprintf('🎛️  DFIG Parameter Configuration GUI loaded successfully!\n');
fprintf('Configure your system parameters and click "Apply & Save"\n\n');

%% ========================================================================
%% TAB CREATION FUNCTIONS
%% ========================================================================

function tab = create_dfig_tab(tabgroup)
    % DFIG Parameters Tab
    tab = uitab(tabgroup, 'Title', '🌪️ DFIG System');
    
    % Main panel
    panel = uipanel(tab, 'Title', 'DFIG Generator Parameters', ...
        'Position', [0.02 0.02 0.96 0.96], 'FontWeight', 'bold');
    
    % Left column - Basic parameters
    create_parameter_group(panel, 'Basic DFIG Parameters', [0.05 0.7 0.4 0.25], {
        {'Rated Power (MW)', 'dfig_rated_power', 2.0, [0.5, 10]}
        {'Rated Voltage (V)', 'dfig_rated_voltage', 690, [400, 1500]}  
        {'Rated Speed (rpm)', 'dfig_rated_speed', 1500, [1000, 2000]}
        {'Number of Poles', 'dfig_poles', 4, [2, 8]}
    });
    
    % Right column - Electrical parameters
    create_parameter_group(panel, 'Electrical Parameters', [0.55 0.7 0.4 0.25], {
        {'Stator Resistance (pu)', 'dfig_Rs', 0.023, [0.001, 0.1]}
        {'Rotor Resistance (pu)', 'dfig_Rr', 0.016, [0.001, 0.1]}
        {'Stator Inductance (pu)', 'dfig_Ls', 0.18, [0.1, 0.5]}  
        {'Rotor Inductance (pu)', 'dfig_Lr', 0.16, [0.1, 0.5]}
    });
    
    % Wind turbine parameters
    create_parameter_group(panel, 'Wind Turbine Parameters', [0.05 0.4 0.4 0.25], {
        {'Rotor Diameter (m)', 'turbine_diameter', 90, [50, 150]}
        {'Cut-in Speed (m/s)', 'turbine_cut_in', 3, [2, 5]}
        {'Cut-out Speed (m/s)', 'turbine_cut_out', 25, [20, 35]}
        {'Air Density (kg/m³)', 'air_density', 1.225, [1.0, 1.5]}
    });
    
    % Converter parameters
    create_parameter_group(panel, 'Converter Parameters', [0.55 0.4 0.4 0.25], {
        {'RSC Power Rating (%)', 'rsc_power_rating', 30, [20, 40]}
        {'GSC Power Rating (%)', 'gsc_power_rating', 30, [20, 40]}  
        {'DC Link Voltage (V)', 'dc_link_voltage', 1200, [800, 1500]}
        {'Switching Freq (Hz)', 'switching_freq', 2500, [1000, 5000]}
    });
    
    % Performance display
    create_performance_display(panel, [0.05 0.05 0.9 0.3]);
end

function tab = create_ess_tab(tabgroup)
    % Energy Storage System Tab
    tab = uitab(tabgroup, 'Title', '🔋 Energy Storage');
    
    panel = uipanel(tab, 'Title', 'Energy Storage System Parameters', ...
        'Position', [0.02 0.02 0.96 0.96], 'FontWeight', 'bold');
    
    % ESS Basic Parameters
    create_parameter_group(panel, 'Basic ESS Parameters', [0.05 0.7 0.4 0.25], {
        {'Rated Power (MW)', 'ess_rated_power', 0.5, [0.1, 2.0]}
        {'Capacity (MWh)', 'ess_capacity', 1.0, [0.5, 5.0]}
        {'Rated Voltage (V)', 'ess_rated_voltage', 800, [400, 1200]}
        {'Efficiency (%)', 'ess_efficiency', 95, [85, 98]}
    });
    
    % SOC Management
    create_parameter_group(panel, 'SOC Management', [0.55 0.7 0.4 0.25], {
        {'Minimum SOC (%)', 'ess_min_soc', 20, [10, 30]}
        {'Maximum SOC (%)', 'ess_max_soc', 90, [80, 95]}
        {'Initial SOC (%)', 'ess_initial_soc', 50, [30, 70]}
        {'SOC Deadband (%)', 'ess_soc_deadband', 5, [1, 10]}
    });
    
    % Response Characteristics
    create_parameter_group(panel, 'Response Characteristics', [0.05 0.4 0.4 0.25], {
        {'Power Response Time (ms)', 'ess_power_response', 50, [10, 200]}
        {'Voltage Response Time (ms)', 'ess_voltage_response', 25, [5, 100]}
        {'Max Power Ramp (MW/s)', 'ess_max_ramp', 10, [1, 50]}
        {'Standby Losses (kW)', 'ess_standby_losses', 5, [0, 20]}
    });
    
    % Protection & Monitoring
    create_parameter_group(panel, 'Protection & Monitoring', [0.55 0.4 0.4 0.25], {
        {'Over-temperature (°C)', 'ess_temp_max', 60, [50, 80]}
        {'Under-voltage (V)', 'ess_voltage_min', 600, [400, 700]}
        {'Over-current (A)', 'ess_current_max', 1000, [500, 1500]}
        {'Fault Reset Time (s)', 'ess_fault_reset', 10, [5, 30]}
    });
    
    % ESS Status Display
    create_ess_status_display(panel, [0.05 0.05 0.9 0.3]);
end

function tab = create_control_tab(tabgroup)
    % Control Systems Tab
    tab = uitab(tabgroup, 'Title', '⚙️ Control Systems');
    
    panel = uipanel(tab, 'Title', 'Advanced Control Parameters', ...
        'Position', [0.02 0.02 0.96 0.96], 'FontWeight', 'bold');
    
    % FRT Control
    create_parameter_group(panel, 'Fault Ride-Through (FRT)', [0.05 0.7 0.28 0.25], {
        {'Voltage Threshold (pu)', 'frt_voltage_threshold', 0.85, [0.5, 0.95]}
        {'Current Limit (pu)', 'frt_current_limit', 1.2, [1.0, 1.5]}
        {'Reactive Gain', 'frt_reactive_gain', 2.0, [1.0, 5.0]}
        {'Response Time (ms)', 'frt_response_time', 10, [5, 50]}
    });
    
    % Frequency Control
    create_parameter_group(panel, 'Frequency Control', [0.36 0.7 0.28 0.25], {
        {'Virtual Inertia (s)', 'freq_virtual_inertia', 5.0, [2.0, 10.0]}
        {'DFIG Droop Gain', 'freq_droop_dfig', 20, [10, 50]}
        {'ESS Droop Gain', 'freq_droop_ess', 15, [5, 30]}
        {'Freq Threshold (Hz)', 'freq_threshold', 0.5, [0.1, 1.0]}
    });
    
    % Mode Switching
    create_parameter_group(panel, 'Mode Switching', [0.67 0.7 0.28 0.25], {
        {'Switch Threshold V (pu)', 'mode_voltage_threshold', 0.85, [0.7, 0.95]}
        {'Switch Threshold f (Hz)', 'mode_freq_threshold', 0.5, [0.2, 1.0]}
        {'Ramp Rate (pu/s)', 'mode_ramp_rate', 0.1, [0.01, 1.0]}
        {'Hysteresis (%)', 'mode_hysteresis', 5, [1, 20]}
    });
    
    % Control Performance
    create_parameter_group(panel, 'Control Performance', [0.05 0.4 0.45 0.25], {
        {'Sample Time (μs)', 'control_sample_time', 100, [50, 500]}
        {'PI Controller Kp', 'control_kp', 1.5, [0.5, 5.0]}
        {'PI Controller Ki', 'control_ki', 50, [10, 200]}
        {'Anti-windup Limit', 'control_antiwindup', 1.2, [1.0, 2.0]}
        {'Deadband Size (%)', 'control_deadband', 2, [0.5, 10]}
        {'Filter Time Constant (ms)', 'control_filter_tc', 5, [1, 20]}
    });
    
    % Grid Code Compliance
    create_parameter_group(panel, 'Grid Code Compliance', [0.52 0.4 0.43 0.25], {
        {'Voltage Ride-Through', 'grid_code_vrt', 'IEEE 1547', {'IEEE 1547', 'IEC 61400-27', 'Custom'}}
        {'Frequency Limits (Hz)', 'grid_code_freq_limits', '49.5-50.5', {'49.5-50.5', '47-52', 'Custom'}}
        {'Power Quality', 'grid_code_pq', 'IEEE 519', {'IEEE 519', 'IEC 61000', 'Custom'}}
        {'Reconnection Delay (s)', 'grid_code_reconnect', 60, [30, 300]}
    });
    
    % Control Status
    create_control_status_display(panel, [0.05 0.05 0.9 0.3]);
end

function tab = create_deeplearning_tab(tabgroup)
    % Deep Learning Configuration Tab
    tab = uitab(tabgroup, 'Title', '🧠 Deep Learning');
    
    panel = uipanel(tab, 'Title', 'Deep Learning & AI Configuration', ...
        'Position', [0.02 0.02 0.96 0.96], 'FontWeight', 'bold');
    
    % LSTM Configuration
    create_parameter_group(panel, 'LSTM Predictor', [0.05 0.7 0.42 0.25], {
        {'Input Features', 'lstm_input_size', 5, [3, 10]}
        {'Hidden Layer 1', 'lstm_hidden1', 64, [32, 128]}
        {'Hidden Layer 2', 'lstm_hidden2', 32, [16, 64]}
        {'Sequence Length', 'lstm_sequence_length', 100, [50, 200]}
        {'Training Epochs', 'lstm_max_epochs', 100, [50, 500]}
        {'Learning Rate', 'lstm_learning_rate', 0.001, [0.0001, 0.01]}
    });
    
    % DRL Configuration  
    create_parameter_group(panel, 'DRL Agent (SOC Optimization)', [0.53 0.7 0.42 0.25], {
        {'State Dimension', 'drl_state_dim', 6, [4, 10]}
        {'Action Dimension', 'drl_action_dim', 2, [1, 4]}
        {'Batch Size', 'drl_batch_size', 32, [16, 128]}
        {'Buffer Size', 'drl_buffer_size', 10000, [1000, 50000]}
        {'Discount Factor', 'drl_gamma', 0.99, [0.9, 0.999]}
        {'Target Update Rate', 'drl_tau', 0.001, [0.0001, 0.01]}
    });
    
    % Training Configuration
    create_parameter_group(panel, 'Training Configuration', [0.05 0.4 0.42 0.25], {
        {'Enable Training', 'dl_enable_training', 'Off', {'On', 'Off'}}
        {'Training Mode', 'dl_training_mode', 'Offline', {'Online', 'Offline', 'Mixed'}}
        {'Data Collection', 'dl_data_collection', 'Continuous', {'Continuous', 'Event-based', 'Manual'}}
        {'Model Update Freq', 'dl_update_frequency', 1000, [100, 10000]}
        {'Validation Split (%)', 'dl_validation_split', 20, [10, 30]}
        {'Early Stopping', 'dl_early_stopping', 'On', {'On', 'Off'}}
    });
    
    % Performance Tuning
    create_parameter_group(panel, 'Performance & Rewards', [0.53 0.4 0.42 0.25], {
        {'SOC Weight', 'drl_reward_soc', 0.4, [0.1, 0.8]}
        {'Grid Support Weight', 'drl_reward_grid', 0.3, [0.1, 0.8]}
        {'Power Smoothing Weight', 'drl_reward_smooth', 0.3, [0.1, 0.8]}
        {'Exploration Noise', 'drl_exploration_noise', 0.1, [0.01, 0.5]}
        {'Performance Threshold', 'drl_performance_threshold', 0.85, [0.7, 0.95]}
        {'Convergence Criterion', 'drl_convergence', 0.001, [0.0001, 0.01]}
    });
    
    % AI Status & Monitoring
    create_ai_status_display(panel, [0.05 0.05 0.9 0.3]);
end

function tab = create_simulation_tab(tabgroup)
    % Simulation & Testing Tab
    tab = uitab(tabgroup, 'Title', '🎯 Simulation');
    
    panel = uipanel(tab, 'Title', 'Simulation & Testing Configuration', ...
        'Position', [0.02 0.02 0.96 0.96], 'FontWeight', 'bold');
    
    % Simulation Settings
    create_parameter_group(panel, 'Simulation Settings', [0.05 0.7 0.42 0.25], {
        {'Simulation Time (s)', 'sim_time', 10, [1, 100]}
        {'Solver Type', 'sim_solver', 'ode23t', {'ode23t', 'ode45', 'ode23s', 'ode15s'}}
        {'Fixed Step Size (μs)', 'sim_step_size', 100, [10, 1000]}
        {'Relative Tolerance', 'sim_rel_tol', 1e-3, [1e-6, 1e-1]}
        {'Absolute Tolerance', 'sim_abs_tol', 1e-6, [1e-9, 1e-3]}
        {'Data Logging', 'sim_data_logging', 'On', {'On', 'Off'}}
    });
    
    % Test Scenarios
    create_parameter_group(panel, 'Test Scenarios', [0.53 0.7 0.42 0.25], {
        {'Wind Profile', 'test_wind_profile', 'Variable', {'Constant', 'Variable', 'Gusty', 'Ramp'}}
        {'Grid Fault Type', 'test_fault_type', 'Voltage Dip', {'Voltage Dip', 'Frequency Step', 'Asymmetric', 'None'}}
        {'Fault Start Time (s)', 'test_fault_start', 2.0, [0.5, 8.0]}
        {'Fault Duration (s)', 'test_fault_duration', 0.15, [0.05, 2.0]}
        {'Load Step Size (MW)', 'test_load_step', 0.5, [0.1, 2.0]}
        {'Load Step Time (s)', 'test_load_step_time', 5.0, [1.0, 9.0]}
    });
    
    % Analysis Options
    create_parameter_group(panel, 'Analysis & Visualization', [0.05 0.4 0.42 0.25], {
        {'Generate Report', 'analysis_report', 'On', {'On', 'Off'}}  
        {'Plot Results', 'analysis_plots', 'On', {'On', 'Off'}}
        {'Export Data', 'analysis_export', 'MATLAB', {'MATLAB', 'Excel', 'CSV', 'None'}}
        {'Performance Metrics', 'analysis_metrics', 'All', {'All', 'Basic', 'Advanced', 'Custom'}}
        {'Comparison Mode', 'analysis_comparison', 'None', {'None', 'Baseline', 'Previous', 'Custom'}}
        {'Real-time Display', 'analysis_realtime', 'On', {'On', 'Off'}}
    });
    
    % Quick Actions
    create_simulation_controls(panel, [0.53 0.4 0.42 0.25]);
    
    % Simulation Status
    create_simulation_status_display(panel, [0.05 0.05 0.9 0.3]);
end

%% ========================================================================
%% UTILITY FUNCTIONS FOR GUI CREATION
%% ========================================================================

function create_parameter_group(parent, title, position, params)
    % Create parameter input group
    group_panel = uipanel(parent, 'Title', title, 'Position', position, ...
        'FontWeight', 'bold', 'BackgroundColor', [0.94 0.94 0.94]);
    
    num_params = length(params);
    for i = 1:num_params
        param = params{i};
        param_name = param{1};
        param_tag = param{2};
        param_default = param{3};
        param_range = param{4};
        
        y_pos = 1 - i * (0.8 / num_params) - 0.1;
        
        % Parameter label
        uicontrol(group_panel, 'Style', 'text', 'String', param_name, ...
            'Units', 'normalized', 'Position', [0.05, y_pos, 0.55, 0.12], ...
            'HorizontalAlignment', 'left', 'FontSize', 9);
        
        % Parameter input
        if iscell(param_range)  % Dropdown
            uicontrol(group_panel, 'Style', 'popupmenu', 'String', param_range, ...
                'Units', 'normalized', 'Position', [0.62, y_pos, 0.35, 0.12], ...
                'Tag', param_tag, 'Value', find(strcmp(param_range, param_default)), ...
                'Callback', {@parameter_changed, param_tag});
        else  % Numeric input with slider
            % Text input
            uicontrol(group_panel, 'Style', 'edit', 'String', num2str(param_default), ...
                'Units', 'normalized', 'Position', [0.62, y_pos, 0.2, 0.12], ...
                'Tag', param_tag, 'Callback', {@parameter_changed, param_tag});
            
            % Slider (if numeric range provided)
            if length(param_range) == 2
                uicontrol(group_panel, 'Style', 'slider', ...
                    'Min', param_range(1), 'Max', param_range(2), 'Value', param_default, ...
                    'Units', 'normalized', 'Position', [0.84, y_pos, 0.13, 0.12], ...
                    'Tag', [param_tag '_slider'], ...
                    'Callback', {@slider_changed, param_tag});
            end
        end
    end
end

function create_control_panel(fig)
    % Create bottom control panel
    control_panel = uipanel(fig, 'Title', 'Actions', ...
        'Position', [0.02 0.02 0.96 0.12], 'FontWeight', 'bold');
    
    % Load/Save buttons
    uicontrol(control_panel, 'Style', 'pushbutton', 'String', '📁 Load Config', ...
        'Units', 'normalized', 'Position', [0.02 0.3 0.12 0.4], ...
        'Callback', @load_config, 'FontSize', 10);
    
    uicontrol(control_panel, 'Style', 'pushbutton', 'String', '💾 Save Config', ...
        'Units', 'normalized', 'Position', [0.15 0.3 0.12 0.4], ...
        'Callback', @save_config, 'FontSize', 10);
    
    % Reset button
    uicontrol(control_panel, 'Style', 'pushbutton', 'String', '🔄 Reset to Defaults', ...
        'Units', 'normalized', 'Position', [0.3 0.3 0.15 0.4], ...
        'Callback', @reset_defaults, 'FontSize', 10);
    
    % Validation button
    uicontrol(control_panel, 'Style', 'pushbutton', 'String', '✅ Validate Parameters', ...
        'Units', 'normalized', 'Position', [0.48 0.3 0.15 0.4], ...
        'Callback', @validate_parameters, 'FontSize', 10);
    
    % Apply button
    uicontrol(control_panel, 'Style', 'pushbutton', 'String', '🚀 Apply & Save', ...
        'Units', 'normalized', 'Position', [0.66 0.3 0.15 0.4], ...
        'Callback', @apply_config, 'FontSize', 10, ...
        'BackgroundColor', [0.2 0.8 0.2], 'ForegroundColor', 'white', ...
        'FontWeight', 'bold');
    
    % Run Simulation button
    uicontrol(control_panel, 'Style', 'pushbutton', 'String', '▶️ Run Simulation', ...
        'Units', 'normalized', 'Position', [0.84 0.3 0.14 0.4], ...
        'Callback', @run_simulation, 'FontSize', 10, ...
        'BackgroundColor', [0.8 0.3 0.2], 'ForegroundColor', 'white', ...
        'FontWeight', 'bold');
    
    % Status text
    uicontrol(control_panel, 'Style', 'text', 'String', 'Ready - Configure parameters and click Apply & Save', ...
        'Units', 'normalized', 'Position', [0.02 0.05 0.96 0.2], ...
        'Tag', 'status_text', 'FontSize', 9, 'FontWeight', 'bold');
end

%% ========================================================================
%% CALLBACK FUNCTIONS
%% ========================================================================

function parameter_changed(src, ~, param_tag)
    % Handle parameter changes
    fig = ancestor(src, 'figure');
    params = getappdata(fig, 'params');
    
    if strcmp(src.Style, 'edit')
        new_value = str2double(src.String);
        if isnan(new_value)
            src.String = num2str(params.(param_tag));
            return;
        end
    elseif strcmp(src.Style, 'popupmenu')
        options = src.String;
        new_value = options{src.Value};
    end
    
    params.(param_tag) = new_value;
    setappdata(fig, 'params', params);
    setappdata(fig, 'modified', true);
    
    update_status(fig, 'Parameters modified - Click Apply & Save to update system');
    
    % Update corresponding slider if exists
    slider_handle = findobj(fig, 'Tag', [param_tag '_slider']);
    if ~isempty(slider_handle) && isnumeric(new_value)
        slider_handle.Value = new_value;
    end
end

function slider_changed(src, ~, param_tag)
    % Handle slider changes
    fig = ancestor(src, 'figure');
    params = getappdata(fig, 'params');
    
    new_value = src.Value;
    params.(param_tag) = new_value;
    setappdata(fig, 'params', params);
    setappdata(fig, 'modified', true);
    
    % Update corresponding text box
    text_handle = findobj(fig, 'Tag', param_tag);
    if ~isempty(text_handle)
        text_handle.String = num2str(new_value);
    end
    
    update_status(fig, 'Parameters modified - Click Apply & Save to update system');
end

function load_config(src, ~)
    % Load configuration from file
    fig = ancestor(src, 'figure');
    
    [filename, pathname] = uigetfile('*.mat', 'Load DFIG Configuration');
    if filename == 0, return; end
    
    try
        loaded_data = load(fullfile(pathname, filename));
        if isfield(loaded_data, 'dfig_params')
            setappdata(fig, 'params', loaded_data.dfig_params);
            refresh_gui(fig);
            update_status(fig, ['Configuration loaded from: ' filename]);
        else
            error('Invalid configuration file format');
        end
    catch ME
        errordlg(['Failed to load configuration: ' ME.message], 'Load Error');
    end
end

function save_config(src, ~)
    % Save configuration to file
    fig = ancestor(src, 'figure');
    params = getappdata(fig, 'params');
    
    [filename, pathname] = uiputfile('*.mat', 'Save DFIG Configuration');
    if filename == 0, return; end
    
    try
        dfig_params = params;  %#ok<NASGU>
        save(fullfile(pathname, filename), 'dfig_params');
        update_status(fig, ['Configuration saved to: ' filename]);
    catch ME
        errordlg(['Failed to save configuration: ' ME.message], 'Save Error');
    end
end

function reset_defaults(src, ~)
    % Reset to default parameters
    fig = ancestor(src, 'figure');
    
    answer = questdlg('Reset all parameters to default values?', ...
        'Reset Confirmation', 'Yes', 'No', 'No');
    
    if strcmp(answer, 'Yes')
        setappdata(fig, 'params', load_default_parameters());
        refresh_gui(fig);
        update_status(fig, 'Parameters reset to default values');
    end
end

function validate_parameters(src, ~)
    % Validate current parameters
    fig = ancestor(src, 'figure');
    params = getappdata(fig, 'params');
    
    [is_valid, errors] = validate_dfig_parameters(params);
    
    if is_valid
        msgbox('✅ All parameters are valid!', 'Validation Success', 'help');
        update_status(fig, 'Parameter validation passed');
    else
        error_msg = sprintf('❌ Parameter validation failed:\n\n%s', ...
            strjoin(errors, '\n'));
        errordlg(error_msg, 'Validation Errors');
        update_status(fig, 'Parameter validation failed - Check error dialog');
    end
end

function apply_config(src, ~)
    % Apply configuration to system
    fig = ancestor(src, 'figure');
    params = getappdata(fig, 'params');
    
    [is_valid, errors] = validate_dfig_parameters(params);
    
    if ~is_valid
        error_msg = sprintf('Cannot apply invalid parameters:\n\n%s', ...
            strjoin(errors, '\n'));
        errordlg(error_msg, 'Application Error');
        return;
    end
    
    try
        % Save to default configuration location
        save('config/dfig_parameters.mat', 'params');
        
        % Update workspace variables
        assignin('base', 'dfig_params', params);
        
        % Update status
        setappdata(fig, 'modified', false);
        update_status(fig, '✅ Configuration applied successfully!');
        
        % Show confirmation
        msgbox('Configuration has been applied and saved to the system!', ...
            'Success', 'help');
        
    catch ME
        errordlg(['Failed to apply configuration: ' ME.message], 'Application Error');
    end
end

function run_simulation(src, ~)
    % Run simulation with current parameters
    fig = ancestor(src, 'figure');
    params = getappdata(fig, 'params');
    
    if getappdata(fig, 'modified')
        answer = questdlg('Parameters have been modified. Apply changes before running simulation?', ...
            'Apply Changes', 'Yes', 'No', 'Cancel', 'Yes');
        
        switch answer
            case 'Yes'
                apply_config(src, []);
            case 'Cancel'
                return;
        end
    end
    
    try
        update_status(fig, '🏃 Running simulation...');
        
        % Run the main simulation
        evalin('base', 'main');
        
        update_status(fig, '✅ Simulation completed successfully!');
        
    catch ME
        errordlg(['Simulation failed: ' ME.message], 'Simulation Error');
        update_status(fig, '❌ Simulation failed - Check error dialog');
    end
end

%% ========================================================================
%% UTILITY FUNCTIONS
%% ========================================================================

function params = load_default_parameters()
    % Load default system parameters
    
    % DFIG Parameters
    params.dfig_rated_power = 2.0;       % MW
    params.dfig_rated_voltage = 690;     % V
    params.dfig_rated_speed = 1500;      % rpm  
    params.dfig_poles = 4;
    params.dfig_Rs = 0.023;              % pu
    params.dfig_Rr = 0.016;              % pu
    params.dfig_Ls = 0.18;               % pu
    params.dfig_Lr = 0.16;               % pu
    
    % Wind Turbine
    params.turbine_diameter = 90;        % m
    params.turbine_cut_in = 3;           % m/s
    params.turbine_cut_out = 25;         % m/s
    params.air_density = 1.225;          % kg/m³
    
    % Converters
    params.rsc_power_rating = 30;        % %
    params.gsc_power_rating = 30;        % %
    params.dc_link_voltage = 1200;       % V
    params.switching_freq = 2500;        % Hz
    
    % ESS Parameters
    params.ess_rated_power = 0.5;        % MW
    params.ess_capacity = 1.0;           % MWh
    params.ess_rated_voltage = 800;      % V
    params.ess_efficiency = 95;          % %
    params.ess_min_soc = 20;             % %
    params.ess_max_soc = 90;             % %
    params.ess_initial_soc = 50;         % %
    params.ess_soc_deadband = 5;         % %
    params.ess_power_response = 50;      % ms
    params.ess_voltage_response = 25;    % ms
    params.ess_max_ramp = 10;            % MW/s
    params.ess_standby_losses = 5;       % kW
    params.ess_temp_max = 60;            % °C
    params.ess_voltage_min = 600;        % V
    params.ess_current_max = 1000;       % A
    params.ess_fault_reset = 10;         % s
    
    % Control Parameters
    params.frt_voltage_threshold = 0.85;  % pu
    params.frt_current_limit = 1.2;       % pu
    params.frt_reactive_gain = 2.0;
    params.frt_response_time = 10;        % ms
    
    params.freq_virtual_inertia = 5.0;    % s
    params.freq_droop_dfig = 20;
    params.freq_droop_ess = 15;
    params.freq_threshold = 0.5;          % Hz
    
    params.mode_voltage_threshold = 0.85; % pu
    params.mode_freq_threshold = 0.5;     % Hz
    params.mode_ramp_rate = 0.1;          % pu/s
    params.mode_hysteresis = 5;           % %
    
    params.control_sample_time = 100;     % μs
    params.control_kp = 1.5;
    params.control_ki = 50;
    params.control_antiwindup = 1.2;
    params.control_deadband = 2;          % %
    params.control_filter_tc = 5;         % ms
    
    params.grid_code_vrt = 'IEEE 1547';
    params.grid_code_freq_limits = '49.5-50.5';
    params.grid_code_pq = 'IEEE 519';
    params.grid_code_reconnect = 60;      % s
    
    % Deep Learning
    params.lstm_input_size = 5;
    params.lstm_hidden1 = 64;
    params.lstm_hidden2 = 32;
    params.lstm_sequence_length = 100;
    params.lstm_max_epochs = 100;
    params.lstm_learning_rate = 0.001;
    
    params.drl_state_dim = 6;
    params.drl_action_dim = 2;
    params.drl_batch_size = 32;
    params.drl_buffer_size = 10000;
    params.drl_gamma = 0.99;
    params.drl_tau = 0.001;
    
    params.dl_enable_training = 'Off';
    params.dl_training_mode = 'Offline';
    params.dl_data_collection = 'Continuous';
    params.dl_update_frequency = 1000;
    params.dl_validation_split = 20;      % %
    params.dl_early_stopping = 'On';
    
    params.drl_reward_soc = 0.4;
    params.drl_reward_grid = 0.3;
    params.drl_reward_smooth = 0.3;
    params.drl_exploration_noise = 0.1;
    params.drl_performance_threshold = 0.85;
    params.drl_convergence = 0.001;
    
    % Simulation
    params.sim_time = 10;                 % s
    params.sim_solver = 'ode23t';
    params.sim_step_size = 100;           % μs
    params.sim_rel_tol = 1e-3;
    params.sim_abs_tol = 1e-6;
    params.sim_data_logging = 'On';
    
    params.test_wind_profile = 'Variable';
    params.test_fault_type = 'Voltage Dip';
    params.test_fault_start = 2.0;        % s
    params.test_fault_duration = 0.15;    % s
    params.test_load_step = 0.5;          % MW
    params.test_load_step_time = 5.0;     % s
    
    params.analysis_report = 'On';
    params.analysis_plots = 'On';
    params.analysis_export = 'MATLAB';
    params.analysis_metrics = 'All';
    params.analysis_comparison = 'None';
    params.analysis_realtime = 'On';
end

function refresh_gui(fig)
    % Refresh all GUI elements with current parameters
    params = getappdata(fig, 'params');
    
    % Find all parameter input controls and update them
    all_controls = findall(fig, 'Type', 'uicontrol');
    
    for control = all_controls'
        if ~isempty(control.Tag) && isfield(params, control.Tag)
            param_value = params.(control.Tag);
            
            switch control.Style
                case 'edit'
                    control.String = num2str(param_value);
                case 'popupmenu'
                    % Find matching value in popup options
                    options = control.String;
                    match_idx = find(strcmp(options, param_value));
                    if ~isempty(match_idx)
                        control.Value = match_idx;
                    end
                case 'slider'
                    if isnumeric(param_value)
                        control.Value = param_value;
                    end
            end
        end
    end
end

function [is_valid, errors] = validate_dfig_parameters(params)
    % Validate parameter ranges and consistency
    errors = {};
    
    % DFIG validations
    if params.dfig_rated_power <= 0 || params.dfig_rated_power > 10
        errors{end+1} = 'DFIG rated power must be between 0.1 and 10 MW';
    end
    
    if params.dfig_rated_voltage < 400 || params.dfig_rated_voltage > 1500
        errors{end+1} = 'DFIG rated voltage must be between 400 and 1500 V';
    end
    
    % ESS validations
    if params.ess_min_soc >= params.ess_max_soc
        errors{end+1} = 'ESS minimum SOC must be less than maximum SOC';
    end
    
    if params.ess_initial_soc < params.ess_min_soc || params.ess_initial_soc > params.ess_max_soc
        errors{end+1} = 'ESS initial SOC must be between minimum and maximum SOC';
    end
    
    % Control validations
    if params.control_sample_time > 1000
        errors{end+1} = 'Control sample time too large (max 1000 μs for stability)';
    end
    
    % Deep learning validations
    if strcmp(params.dl_enable_training, 'On') && params.lstm_max_epochs < 10
        errors{end+1} = 'LSTM training requires at least 10 epochs';
    end
    
    % Simulation validations
    if params.sim_time <= 0 || params.sim_time > 100
        errors{end+1} = 'Simulation time must be between 0 and 100 seconds';
    end
    
    is_valid = isempty(errors);
end

function update_status(fig, message)
    % Update status text
    status_handle = findobj(fig, 'Tag', 'status_text');
    if ~isempty(status_handle)
        status_handle.String = message;
        drawnow;
    end
end

function closeGUI(src, ~)
    % Handle GUI close
    if getappdata(src, 'modified')
        answer = questdlg('Parameters have been modified. Save before closing?', ...
            'Save Changes', 'Yes', 'No', 'Cancel', 'Cancel');
        
        switch answer
            case 'Yes'
                save_config(src, []);
                delete(src);
            case 'No'
                delete(src);
            case 'Cancel'
                return;
        end
    else
        delete(src);
    end
end

% Placeholder functions for display panels
function create_performance_display(parent, position)
    panel = uipanel(parent, 'Title', 'System Performance Preview', 'Position', position);
    uicontrol(panel, 'Style', 'text', 'String', 'Performance metrics will be displayed here after validation', ...
        'Units', 'normalized', 'Position', [0.1 0.4 0.8 0.2], 'FontSize', 10);
end

function create_ess_status_display(parent, position)
    panel = uipanel(parent, 'Title', 'ESS Status & Health', 'Position', position);
    uicontrol(panel, 'Style', 'text', 'String', 'ESS status indicators and health metrics will be shown here', ...
        'Units', 'normalized', 'Position', [0.1 0.4 0.8 0.2], 'FontSize', 10);
end

function create_control_status_display(parent, position)
    panel = uipanel(parent, 'Title', 'Control System Status', 'Position', position);  
    uicontrol(panel, 'Style', 'text', 'String', 'Control system status and performance indicators', ...
        'Units', 'normalized', 'Position', [0.1 0.4 0.8 0.2], 'FontSize', 10);
end

function create_ai_status_display(parent, position)
    panel = uipanel(parent, 'Title', 'AI/ML Model Status & Training Progress', 'Position', position);
    uicontrol(panel, 'Style', 'text', 'String', 'Deep learning model status, training progress, and performance metrics', ...
        'Units', 'normalized', 'Position', [0.1 0.4 0.8 0.2], 'FontSize', 10);
end

function create_simulation_controls(parent, position)
    panel = uipanel(parent, 'Title', 'Quick Actions', 'Position', position);
    
    uicontrol(panel, 'Style', 'pushbutton', 'String', '⚡ Quick Test', ...
        'Units', 'normalized', 'Position', [0.1 0.7 0.35 0.2], ...
        'Callback', @quick_test);
    
    uicontrol(panel, 'Style', 'pushbutton', 'String', '📊 View Results', ...
        'Units', 'normalized', 'Position', [0.55 0.7 0.35 0.2], ...
        'Callback', @view_results);
    
    uicontrol(panel, 'Style', 'pushbutton', 'String', '🔧 Model Setup', ...
        'Units', 'normalized', 'Position', [0.1 0.4 0.35 0.2], ...
        'Callback', @model_setup);
    
    uicontrol(panel, 'Style', 'pushbutton', 'String', '📈 Performance Analysis', ...
        'Units', 'normalized', 'Position', [0.55 0.4 0.35 0.2], ...
        'Callback', @performance_analysis);
end

function create_simulation_status_display(parent, position)
    panel = uipanel(parent, 'Title', 'Simulation Status & Progress', 'Position', position);
    uicontrol(panel, 'Style', 'text', 'String', 'Simulation status, progress indicators, and real-time metrics', ...
        'Units', 'normalized', 'Position', [0.1 0.4 0.8 0.2], 'FontSize', 10);
end

% Placeholder callback functions
function quick_test(~, ~), msgbox('Quick test functionality will run a 2-second validation simulation', 'Quick Test'); end
function view_results(~, ~), msgbox('Results viewer will display latest simulation data and plots', 'View Results'); end  
function model_setup(~, ~), msgbox('Model setup will configure and initialize the Simulink model', 'Model Setup'); end
function performance_analysis(~, ~), msgbox('Performance analysis will generate comprehensive system reports', 'Performance Analysis'); end

end
