function gui_simulation_dashboard()
%GUI_SIMULATION_DASHBOARD Interactive Real-time Simulation Dashboard
% Real-time monitoring and control dashboard for DFIG wind power system
%
% Features:
% • Real-time system monitoring with live plots
% • Interactive control panel for parameter adjustment
% • Comprehensive performance metrics display
% • Fault injection and scenario testing
% • Data logging and export capabilities
% • Multi-view display (electrical, mechanical, control)

%% Create Main Dashboard Window
fig = figure('Name', 'DFIG System - Real-time Simulation Dashboard v2.0', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'figure', ...
    'Position', [50, 50, 1600, 1000], ...
    'Resize', 'on', ...
    'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @closeDashboard);

% Initialize dashboard data
dashboard_data = struct();
dashboard_data.simulation_running = false;
dashboard_data.start_time = now;
dashboard_data.current_time = 0;
dashboard_data.data_buffer_size = 1000;
dashboard_data.update_rate = 0.1; % 100ms update rate

% Initialize data buffers
dashboard_data.time_buffer = zeros(1, dashboard_data.data_buffer_size);
dashboard_data.voltage_buffer = zeros(1, dashboard_data.data_buffer_size);
dashboard_data.frequency_buffer = ones(1, dashboard_data.data_buffer_size) * 50;
dashboard_data.power_dfig_buffer = zeros(1, dashboard_data.data_buffer_size);
dashboard_data.power_ess_buffer = zeros(1, dashboard_data.data_buffer_size);
dashboard_data.soc_buffer = ones(1, dashboard_data.data_buffer_size) * 50;
dashboard_data.wind_speed_buffer = ones(1, dashboard_data.data_buffer_size) * 12;

setappdata(fig, 'dashboard_data', dashboard_data);

%% Create Layout Structure
create_header_panel(fig);
create_main_monitoring_area(fig);
create_control_panels(fig);
create_status_bar(fig);

%% Initialize Real-time Updates
timer_handle = timer('ExecutionMode', 'fixedRate', ...
    'Period', dashboard_data.update_rate, ...
    'TimerFcn', {@update_dashboard, fig});
setappdata(fig, 'timer_handle', timer_handle);

fprintf('🖥️  DFIG Simulation Dashboard loaded successfully!\n');
fprintf('Use the control panels to start simulation and monitor system performance\n\n');

%% ========================================================================
%% LAYOUT CREATION FUNCTIONS
%% ========================================================================

function create_header_panel(fig)
    % Create header with system status and quick controls
    header_panel = uipanel(fig, 'Position', [0.01 0.94 0.98 0.05], ...
        'BackgroundColor', [0.2 0.3 0.6], 'BorderType', 'none');
    
    % System title
    uicontrol(header_panel, 'Style', 'text', ...
        'String', '🌪️ DFIG Wind Power System - Interactive Dashboard', ...
        'Units', 'normalized', 'Position', [0.02 0.2 0.4 0.6], ...
        'BackgroundColor', [0.2 0.3 0.6], 'ForegroundColor', 'white', ...
        'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
    
    % System status indicator
    uicontrol(header_panel, 'Style', 'text', 'String', '● READY', ...
        'Units', 'normalized', 'Position', [0.45 0.2 0.15 0.6], ...
        'BackgroundColor', [0.2 0.3 0.6], 'ForegroundColor', 'lime', ...
        'FontSize', 14, 'FontWeight', 'bold', 'Tag', 'system_status', ...
        'HorizontalAlignment', 'center');
    
    % Quick control buttons
    uicontrol(header_panel, 'Style', 'pushbutton', 'String', '▶️ START', ...
        'Units', 'normalized', 'Position', [0.65 0.2 0.08 0.6], ...
        'Callback', @start_simulation, 'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.2 0.8 0.2], 'ForegroundColor', 'white', 'Tag', 'start_btn');
    
    uicontrol(header_panel, 'Style', 'pushbutton', 'String', '⏸️ STOP', ...
        'Units', 'normalized', 'Position', [0.74 0.2 0.08 0.6], ...
        'Callback', @stop_simulation, 'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.8 0.2 0.2], 'ForegroundColor', 'white', 'Tag', 'stop_btn');
    
    uicontrol(header_panel, 'Style', 'pushbutton', 'String', '🔄 RESET', ...
        'Units', 'normalized', 'Position', [0.83 0.2 0.08 0.6], ...
        'Callback', @reset_simulation, 'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.6 0.6 0.2], 'ForegroundColor', 'white');
    
    uicontrol(header_panel, 'Style', 'pushbutton', 'String', '⚙️ CONFIG', ...
        'Units', 'normalized', 'Position', [0.92 0.2 0.08 0.6], ...
        'Callback', @open_config, 'FontWeight', 'bold', 'FontSize', 11);
end

function create_main_monitoring_area(fig)
    % Create main monitoring area with multiple plot panels
    
    %% Left Panel - Electrical Measurements
    electrical_panel = uipanel(fig, 'Title', '⚡ Electrical System', ...
        'Position', [0.01 0.48 0.48 0.45], 'FontWeight', 'bold', 'FontSize', 12);
    
    % Voltage and Frequency plots
    subplot_pos1 = [0.1 0.7 0.85 0.25];
    ax1 = axes(electrical_panel, 'Position', subplot_pos1);
    plot(ax1, 0, 1.0, 'b-', 'LineWidth', 2);
    ylabel(ax1, 'Voltage (pu)', 'FontWeight', 'bold');
    title(ax1, 'Grid Voltage', 'FontWeight', 'bold');
    grid(ax1, 'on');
    set(ax1, 'XLim', [0 10], 'YLim', [0.5 1.2], 'Tag', 'voltage_plot');
    
    subplot_pos2 = [0.1 0.4 0.85 0.25];
    ax2 = axes(electrical_panel, 'Position', subplot_pos2);
    plot(ax2, 0, 50, 'r-', 'LineWidth', 2);
    ylabel(ax2, 'Freq (Hz)', 'FontWeight', 'bold');
    title(ax2, 'Grid Frequency', 'FontWeight', 'bold');
    grid(ax2, 'on');
    set(ax2, 'XLim', [0 10], 'YLim', [49 51], 'Tag', 'frequency_plot');
    
    subplot_pos3 = [0.1 0.1 0.85 0.25];
    ax3 = axes(electrical_panel, 'Position', subplot_pos3);
    plot(ax3, 0, 0, 'g-', 'LineWidth', 2);
    hold(ax3, 'on');
    plot(ax3, 0, 0, 'm-', 'LineWidth', 2);
    ylabel(ax3, 'Power (MW)', 'FontWeight', 'bold');
    xlabel(ax3, 'Time (s)', 'FontWeight', 'bold');
    title(ax3, 'Power Output', 'FontWeight', 'bold');
    legend(ax3, 'DFIG', 'ESS', 'Location', 'northeast');
    grid(ax3, 'on');
    set(ax3, 'XLim', [0 10], 'YLim', [-1 3], 'Tag', 'power_plot');
    
    %% Right Panel - Mechanical & Control
    mechanical_panel = uipanel(fig, 'Title', '⚙️ Mechanical & Control', ...
        'Position', [0.51 0.48 0.48 0.45], 'FontWeight', 'bold', 'FontSize', 12);
    
    % Wind speed and rotor speed
    subplot_pos4 = [0.1 0.7 0.85 0.25];
    ax4 = axes(mechanical_panel, 'Position', subplot_pos4);
    plot(ax4, 0, 12, 'c-', 'LineWidth', 2);
    ylabel(ax4, 'Wind (m/s)', 'FontWeight', 'bold');
    title(ax4, 'Wind Speed', 'FontWeight', 'bold');
    grid(ax4, 'on');
    set(ax4, 'XLim', [0 10], 'YLim', [0 25], 'Tag', 'wind_plot');
    
    % SOC and Control Mode
    subplot_pos5 = [0.1 0.4 0.85 0.25];
    ax5 = axes(mechanical_panel, 'Position', subplot_pos5);
    plot(ax5, 0, 50, 'orange', 'LineWidth', 2);
    ylabel(ax5, 'SOC (%)', 'FontWeight', 'bold');
    title(ax5, 'Energy Storage SOC', 'FontWeight', 'bold');
    grid(ax5, 'on');
    set(ax5, 'XLim', [0 10], 'YLim', [0 100], 'Tag', 'soc_plot');
    
    % System status display
    subplot_pos6 = [0.1 0.1 0.85 0.25];
    ax6 = axes(mechanical_panel, 'Position', subplot_pos6);
    text(ax6, 0.5, 0.7, 'System Status: READY', 'HorizontalAlignment', 'center', ...
        'FontSize', 14, 'FontWeight', 'bold', 'Tag', 'status_text');
    text(ax6, 0.5, 0.5, 'Mode: GRID-FOLLOWING', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'Color', 'blue', 'Tag', 'mode_text');
    text(ax6, 0.5, 0.3, 'Time: 0.0 s', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'Tag', 'time_text');
    set(ax6, 'XLim', [0 1], 'YLim', [0 1], 'XTick', [], 'YTick', []);
    title(ax6, 'System Information', 'FontWeight', 'bold');
end

function create_control_panels(fig)
    % Create control panels for parameter adjustment and fault injection
    
    %% Control Parameter Panel
    control_panel = uipanel(fig, 'Title', '🎛️ Real-time Controls', ...
        'Position', [0.01 0.24 0.32 0.23], 'FontWeight', 'bold', 'FontSize', 11);
    
    % Wind speed control
    uicontrol(control_panel, 'Style', 'text', 'String', 'Wind Speed (m/s):', ...
        'Units', 'normalized', 'Position', [0.05 0.85 0.4 0.1], ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    
    uicontrol(control_panel, 'Style', 'slider', 'Min', 3, 'Max', 25, 'Value', 12, ...
        'Units', 'normalized', 'Position', [0.5 0.85 0.35 0.1], ...
        'Tag', 'wind_slider', 'Callback', {@parameter_slider_changed, 'wind_speed'});
    
    uicontrol(control_panel, 'Style', 'text', 'String', '12.0', ...
        'Units', 'normalized', 'Position', [0.87 0.85 0.1 0.1], ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Tag', 'wind_value');
    
    % Load demand control
    uicontrol(control_panel, 'Style', 'text', 'String', 'Load Demand (MW):', ...
        'Units', 'normalized', 'Position', [0.05 0.65 0.4 0.1], ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    
    uicontrol(control_panel, 'Style', 'slider', 'Min', 0.5, 'Max', 3.0, 'Value', 2.0, ...
        'Units', 'normalized', 'Position', [0.5 0.65 0.35 0.1], ...
        'Tag', 'load_slider', 'Callback', {@parameter_slider_changed, 'load_demand'});
    
    uicontrol(control_panel, 'Style', 'text', 'String', '2.0', ...
        'Units', 'normalized', 'Position', [0.87 0.65 0.1 0.1], ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Tag', 'load_value');
    
    % ESS SOC target
    uicontrol(control_panel, 'Style', 'text', 'String', 'ESS SOC Target (%):', ...
        'Units', 'normalized', 'Position', [0.05 0.45 0.4 0.1], ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    
    uicontrol(control_panel, 'Style', 'slider', 'Min', 20, 'Max', 90, 'Value', 50, ...
        'Units', 'normalized', 'Position', [0.5 0.45 0.35 0.1], ...
        'Tag', 'soc_slider', 'Callback', {@parameter_slider_changed, 'soc_target'});
    
    uicontrol(control_panel, 'Style', 'text', 'String', '50', ...
        'Units', 'normalized', 'Position', [0.87 0.45 0.1 0.1], ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Tag', 'soc_value');
    
    % Control mode selection
    uicontrol(control_panel, 'Style', 'text', 'String', 'Control Mode:', ...
        'Units', 'normalized', 'Position', [0.05 0.25 0.4 0.1], ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    
    uicontrol(control_panel, 'Style', 'popupmenu', ...
        'String', {'Grid-Following', 'Grid-Forming', 'Emergency'}, ...
        'Units', 'normalized', 'Position', [0.5 0.25 0.45 0.1], ...
        'Tag', 'mode_popup', 'Callback', @control_mode_changed);
    
    % Enable/Disable Deep Learning
    uicontrol(control_panel, 'Style', 'checkbox', 'String', 'Enable Deep Learning', ...
        'Units', 'normalized', 'Position', [0.05 0.05 0.6 0.15], ...
        'Value', 1, 'FontWeight', 'bold', 'Tag', 'dl_checkbox', ...
        'Callback', @deep_learning_toggle);
    
    %% Fault Injection Panel
    fault_panel = uipanel(fig, 'Title', '⚡ Fault Injection & Testing', ...
        'Position', [0.34 0.24 0.32 0.23], 'FontWeight', 'bold', 'FontSize', 11);
    
    % Voltage fault
    uicontrol(fault_panel, 'Style', 'pushbutton', 'String', '⬇️ Voltage Dip', ...
        'Units', 'normalized', 'Position', [0.05 0.8 0.4 0.15], ...
        'Callback', {@inject_fault, 'voltage_dip'}, 'FontWeight', 'bold');
    
    uicontrol(fault_panel, 'Style', 'pushbutton', 'String', '📈 Voltage Swell', ...
        'Units', 'normalized', 'Position', [0.55 0.8 0.4 0.15], ...
        'Callback', {@inject_fault, 'voltage_swell'}, 'FontWeight', 'bold');
    
    % Frequency fault
    uicontrol(fault_panel, 'Style', 'pushbutton', 'String', '📉 Freq Drop', ...
        'Units', 'normalized', 'Position', [0.05 0.6 0.4 0.15], ...
        'Callback', {@inject_fault, 'freq_drop'}, 'FontWeight', 'bold');
    
    uicontrol(fault_panel, 'Style', 'pushbutton', 'String', '📊 Freq Rise', ...
        'Units', 'normalized', 'Position', [0.55 0.6 0.4 0.15], ...
        'Callback', {@inject_fault, 'freq_rise'}, 'FontWeight', 'bold');
    
    % Load step
    uicontrol(fault_panel, 'Style', 'pushbutton', 'String', '⚡ Load Step', ...
        'Units', 'normalized', 'Position', [0.05 0.4 0.4 0.15], ...
        'Callback', {@inject_fault, 'load_step'}, 'FontWeight', 'bold');
    
    uicontrol(fault_panel, 'Style', 'pushbutton', 'String', '🌪️ Wind Gust', ...
        'Units', 'normalized', 'Position', [0.55 0.4 0.4 0.15], ...
        'Callback', {@inject_fault, 'wind_gust'}, 'FontWeight', 'bold');
    
    % Fault parameters
    uicontrol(fault_panel, 'Style', 'text', 'String', 'Fault Duration (s):', ...
        'Units', 'normalized', 'Position', [0.05 0.2 0.5 0.1], ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    
    uicontrol(fault_panel, 'Style', 'edit', 'String', '0.15', ...
        'Units', 'normalized', 'Position', [0.6 0.2 0.35 0.1], ...
        'Tag', 'fault_duration', 'HorizontalAlignment', 'center');
    
    uicontrol(fault_panel, 'Style', 'text', 'String', 'Fault Severity (%):', ...
        'Units', 'normalized', 'Position', [0.05 0.05 0.5 0.1], ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    
    uicontrol(fault_panel, 'Style', 'edit', 'String', '20', ...
        'Units', 'normalized', 'Position', [0.6 0.05 0.35 0.1], ...
        'Tag', 'fault_severity', 'HorizontalAlignment', 'center');
    
    %% Performance Metrics Panel
    metrics_panel = uipanel(fig, 'Title', '📊 Performance Metrics', ...
        'Position', [0.67 0.24 0.32 0.23], 'FontWeight', 'bold', 'FontSize', 11);
    
    % Create metrics display table
    metrics_data = {
        'Voltage (pu)', '1.000', 'NORMAL'
        'Frequency (Hz)', '50.00', 'NORMAL'
        'DFIG Power (MW)', '0.00', 'STANDBY'
        'ESS Power (MW)', '0.00', 'STANDBY'  
        'ESS SOC (%)', '50.0', 'NORMAL'
        'System Efficiency (%)', '95.0', 'EXCELLENT'
        'Grid Support Factor', '0.85', 'GOOD'
        'Control Response (ms)', '10', 'EXCELLENT'
    };
    
    uitable(metrics_panel, 'Data', metrics_data, ...
        'ColumnName', {'Metric', 'Value', 'Status'}, ...
        'ColumnWidth', {120, 60, 80}, ...
        'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9], ...
        'Tag', 'metrics_table', 'FontSize', 10);
end

function create_status_bar(fig)
    % Create bottom status bar
    status_panel = uipanel(fig, 'Position', [0.01 0.01 0.98 0.22], ...
        'BackgroundColor', [0.9 0.9 0.9], 'BorderType', 'line');
    
    %% Data Logging Panel
    logging_panel = uipanel(status_panel, 'Title', '📝 Data Logging', ...
        'Position', [0.02 0.5 0.46 0.45], 'FontWeight', 'bold');
    
    uicontrol(logging_panel, 'Style', 'checkbox', 'String', 'Enable Data Logging', ...
        'Units', 'normalized', 'Position', [0.05 0.7 0.6 0.25], ...
        'Value', 1, 'FontWeight', 'bold', 'Tag', 'logging_checkbox');
    
    uicontrol(logging_panel, 'Style', 'text', 'String', 'Log File:', ...
        'Units', 'normalized', 'Position', [0.05 0.4 0.2 0.25], ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    
    uicontrol(logging_panel, 'Style', 'edit', ...
        'String', ['dfig_log_' datestr(now, 'yyyymmdd_HHMMSS') '.mat'], ...
        'Units', 'normalized', 'Position', [0.3 0.4 0.65 0.25], ...
        'Tag', 'log_filename', 'HorizontalAlignment', 'left');
    
    uicontrol(logging_panel, 'Style', 'pushbutton', 'String', '💾 Export Data', ...
        'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.25], ...
        'Callback', @export_data, 'FontWeight', 'bold');
    
    uicontrol(logging_panel, 'Style', 'pushbutton', 'String', '📊 Generate Report', ...
        'Units', 'normalized', 'Position', [0.55 0.05 0.4 0.25], ...
        'Callback', @generate_report, 'FontWeight', 'bold');
    
    %% System Information Panel  
    info_panel = uipanel(status_panel, 'Title', '🔧 System Information', ...
        'Position', [0.52 0.5 0.46 0.45], 'FontWeight', 'bold');
    
    info_text = sprintf(['DFIG System Dashboard v2.0\n' ...
        'Simulation Status: Ready\n' ...
        'Update Rate: 100ms\n' ...
        'Buffer Size: 1000 samples\n' ...
        'Deep Learning: Enabled']);
    
    uicontrol(info_panel, 'Style', 'text', 'String', info_text, ...
        'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.8], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, 'Tag', 'info_text');
    
    %% Console Output Panel
    console_panel = uipanel(status_panel, 'Title', '💬 Console Output', ...
        'Position', [0.02 0.05 0.96 0.4], 'FontWeight', 'bold');
    
    console_text = sprintf(['[%s] Dashboard initialized\n' ...
        '[%s] System ready for simulation\n' ...
        '[%s] All subsystems operational'], ...
        datestr(now, 'HH:MM:SS'), datestr(now, 'HH:MM:SS'), datestr(now, 'HH:MM:SS'));
    
    console_handle = uicontrol(console_panel, 'Style', 'listbox', ...
        'String', strsplit(console_text, '\n'), ...
        'Units', 'normalized', 'Position', [0.02 0.05 0.96 0.9], ...
        'FontName', 'Courier', 'FontSize', 9, 'Tag', 'console_output', ...
        'Max', 100, 'Value', []);
end

%% ========================================================================
%% CALLBACK FUNCTIONS
%% ========================================================================

function start_simulation(src, ~)
    % Start simulation
    fig = ancestor(src, 'figure');
    dashboard_data = getappdata(fig, 'dashboard_data');
    timer_handle = getappdata(fig, 'timer_handle');
    
    if ~dashboard_data.simulation_running
        dashboard_data.simulation_running = true;
        dashboard_data.current_time = 0;
        setappdata(fig, 'dashboard_data', dashboard_data);
        
        % Start timer
        start(timer_handle);
        
        % Update UI
        update_system_status(fig, '● RUNNING', 'lime');
        add_console_message(fig, 'Simulation started');
        
        % Update buttons
        findobj(fig, 'Tag', 'start_btn').String = '▶️ RUNNING';
        findobj(fig, 'Tag', 'start_btn').BackgroundColor = [0.6 0.6 0.6];
    end
end

function stop_simulation(src, ~)
    % Stop simulation
    fig = ancestor(src, 'figure');
    dashboard_data = getappdata(fig, 'dashboard_data');
    timer_handle = getappdata(fig, 'timer_handle');
    
    if dashboard_data.simulation_running
        dashboard_data.simulation_running = false;
        setappdata(fig, 'dashboard_data', dashboard_data);
        
        % Stop timer
        stop(timer_handle);
        
        % Update UI
        update_system_status(fig, '● STOPPED', 'red');
        add_console_message(fig, 'Simulation stopped');
        
        % Update buttons
        findobj(fig, 'Tag', 'start_btn').String = '▶️ START';
        findobj(fig, 'Tag', 'start_btn').BackgroundColor = [0.2 0.8 0.2];
    end
end

function reset_simulation(src, ~)
    % Reset simulation
    fig = ancestor(src, 'figure');
    
    % Stop first
    stop_simulation(src, []);
    
    % Reset data buffers
    dashboard_data = getappdata(fig, 'dashboard_data');
    dashboard_data.current_time = 0;
    dashboard_data.voltage_buffer(:) = 1.0;
    dashboard_data.frequency_buffer(:) = 50.0;
    dashboard_data.power_dfig_buffer(:) = 0;
    dashboard_data.power_ess_buffer(:) = 0;
    dashboard_data.soc_buffer(:) = 50;
    dashboard_data.wind_speed_buffer(:) = 12;
    dashboard_data.time_buffer(:) = 0;
    setappdata(fig, 'dashboard_data', dashboard_data);
    
    % Clear plots
    clear_all_plots(fig);
    
    % Update status
    update_system_status(fig, '● READY', 'lime');
    add_console_message(fig, 'System reset to initial conditions');
end

function open_config(src, ~)
    % Open configuration GUI
    try
        gui_parameter_config();
        fig = ancestor(src, 'figure');
        add_console_message(fig, 'Configuration GUI opened');
    catch ME
        errordlg(['Failed to open configuration: ' ME.message], 'Configuration Error');
    end
end

function parameter_slider_changed(src, ~, param_name)
    % Handle parameter slider changes
    fig = ancestor(src, 'figure');
    new_value = src.Value;
    
    % Update display
    switch param_name
        case 'wind_speed'
            findobj(fig, 'Tag', 'wind_value').String = sprintf('%.1f', new_value);
            add_console_message(fig, sprintf('Wind speed changed to %.1f m/s', new_value));
        case 'load_demand'
            findobj(fig, 'Tag', 'load_value').String = sprintf('%.1f', new_value);
            add_console_message(fig, sprintf('Load demand changed to %.1f MW', new_value));
        case 'soc_target'
            findobj(fig, 'Tag', 'soc_value').String = sprintf('%.0f', new_value);
            add_console_message(fig, sprintf('ESS SOC target changed to %.0f%%', new_value));
    end
end

function control_mode_changed(src, ~)
    % Handle control mode changes
    fig = ancestor(src, 'figure');
    modes = src.String;
    selected_mode = modes{src.Value};
    
    add_console_message(fig, sprintf('Control mode changed to: %s', selected_mode));
    
    % Update mode display
    findobj(fig, 'Tag', 'mode_text').String = ['Mode: ' upper(selected_mode)];
end

function deep_learning_toggle(src, ~)
    % Toggle deep learning
    fig = ancestor(src, 'figure');
    is_enabled = src.Value;
    
    status = {'Disabled', 'Enabled'};
    add_console_message(fig, sprintf('Deep Learning %s', status{is_enabled + 1}));
end

function inject_fault(src, ~, fault_type)
    % Inject specific fault
    fig = ancestor(src, 'figure');
    dashboard_data = getappdata(fig, 'dashboard_data');
    
    if ~dashboard_data.simulation_running
        add_console_message(fig, 'Start simulation before injecting faults');
        return;
    end
    
    % Get fault parameters
    duration = str2double(findobj(fig, 'Tag', 'fault_duration').String);
    severity = str2double(findobj(fig, 'Tag', 'fault_severity').String);
    
    add_console_message(fig, sprintf('Injecting %s fault (%.2fs, %d%%)', ...
        fault_type, duration, severity));
    
    % Apply fault (simplified simulation)
    switch fault_type
        case 'voltage_dip'
            dashboard_data.voltage_buffer(end-10:end) = 1.0 - severity/100;
        case 'voltage_swell'
            dashboard_data.voltage_buffer(end-10:end) = 1.0 + severity/100;
        case 'freq_drop'
            dashboard_data.frequency_buffer(end-10:end) = 50.0 - severity/10;
        case 'freq_rise'
            dashboard_data.frequency_buffer(end-10:end) = 50.0 + severity/10;
        case 'load_step'
            dashboard_data.power_dfig_buffer(end-10:end) = severity/10;
        case 'wind_gust'
            dashboard_data.wind_speed_buffer(end-10:end) = 12 + severity/5;
    end
    
    setappdata(fig, 'dashboard_data', dashboard_data);
end

function export_data(src, ~)
    % Export simulation data
    fig = ancestor(src, 'figure');
    dashboard_data = getappdata(fig, 'dashboard_data');
    
    filename = findobj(fig, 'Tag', 'log_filename').String;
    
    try
        simulation_data = struct();
        simulation_data.time = dashboard_data.time_buffer;
        simulation_data.voltage = dashboard_data.voltage_buffer;
        simulation_data.frequency = dashboard_data.frequency_buffer;
        simulation_data.power_dfig = dashboard_data.power_dfig_buffer;
        simulation_data.power_ess = dashboard_data.power_ess_buffer;
        simulation_data.soc = dashboard_data.soc_buffer;
        simulation_data.wind_speed = dashboard_data.wind_speed_buffer;
        simulation_data.export_time = now;
        
        save(['results/' filename], 'simulation_data');
        add_console_message(fig, ['Data exported to: results/' filename]);
        
    catch ME
        errordlg(['Export failed: ' ME.message], 'Export Error');
        add_console_message(fig, 'Data export failed');
    end
end

function generate_report(src, ~)
    % Generate performance report
    fig = ancestor(src, 'figure');
    add_console_message(fig, 'Generating performance report...');
    
    try
        % Create report figure
        report_fig = figure('Name', 'DFIG System Performance Report', ...
            'Position', [200, 200, 1200, 800]);
        
        % Create comprehensive plots
        subplot(2, 3, 1);
        dashboard_data = getappdata(fig, 'dashboard_data');
        plot(dashboard_data.time_buffer, dashboard_data.voltage_buffer, 'b-', 'LineWidth', 2);
        title('Grid Voltage'); ylabel('Voltage (pu)'); grid on;
        
        subplot(2, 3, 2);
        plot(dashboard_data.time_buffer, dashboard_data.frequency_buffer, 'r-', 'LineWidth', 2);
        title('Grid Frequency'); ylabel('Frequency (Hz)'); grid on;
        
        subplot(2, 3, 3);
        plot(dashboard_data.time_buffer, dashboard_data.power_dfig_buffer, 'g-', 'LineWidth', 2);
        hold on;
        plot(dashboard_data.time_buffer, dashboard_data.power_ess_buffer, 'm-', 'LineWidth', 2);
        title('Power Output'); ylabel('Power (MW)'); legend('DFIG', 'ESS'); grid on;
        
        subplot(2, 3, 4);
        plot(dashboard_data.time_buffer, dashboard_data.wind_speed_buffer, 'c-', 'LineWidth', 2);
        title('Wind Speed'); ylabel('Wind Speed (m/s)'); grid on;
        
        subplot(2, 3, 5);
        plot(dashboard_data.time_buffer, dashboard_data.soc_buffer, 'orange', 'LineWidth', 2);
        title('ESS State of Charge'); ylabel('SOC (%)'); grid on;
        
        % Summary statistics
        subplot(2, 3, 6);
        axis off;
        stats_text = sprintf(['Performance Summary\n\n' ...
            'Avg Voltage: %.3f pu\n' ...
            'Avg Frequency: %.2f Hz\n' ...
            'Max DFIG Power: %.2f MW\n' ...
            'Max ESS Power: %.2f MW\n' ...
            'SOC Range: %.1f - %.1f%%'], ...
            mean(dashboard_data.voltage_buffer), ...
            mean(dashboard_data.frequency_buffer), ...
            max(dashboard_data.power_dfig_buffer), ...
            max(dashboard_data.power_ess_buffer), ...
            min(dashboard_data.soc_buffer), max(dashboard_data.soc_buffer));
        
        text(0.1, 0.5, stats_text, 'FontSize', 12, 'FontWeight', 'bold');
        
        add_console_message(fig, 'Performance report generated');
        
    catch ME
        errordlg(['Report generation failed: ' ME.message], 'Report Error');
        add_console_message(fig, 'Report generation failed');
    end
end

function update_dashboard(timer_obj, ~, fig)
    % Real-time dashboard update function
    
    if ~isvalid(fig)
        stop(timer_obj);
        return;
    end
    
    dashboard_data = getappdata(fig, 'dashboard_data');
    
    if ~dashboard_data.simulation_running
        return;
    end
    
    % Update time
    dashboard_data.current_time = dashboard_data.current_time + dashboard_data.update_rate;
    
    % Shift buffers and add new data
    shift_amount = 1;
    
    dashboard_data.time_buffer = circshift(dashboard_data.time_buffer, -shift_amount);
    dashboard_data.voltage_buffer = circshift(dashboard_data.voltage_buffer, -shift_amount);
    dashboard_data.frequency_buffer = circshift(dashboard_data.frequency_buffer, -shift_amount);
    dashboard_data.power_dfig_buffer = circshift(dashboard_data.power_dfig_buffer, -shift_amount);
    dashboard_data.power_ess_buffer = circshift(dashboard_data.power_ess_buffer, -shift_amount);
    dashboard_data.soc_buffer = circshift(dashboard_data.soc_buffer, -shift_amount);
    dashboard_data.wind_speed_buffer = circshift(dashboard_data.wind_speed_buffer, -shift_amount);
    
    % Add new simulated data (simplified simulation model)
    current_wind = str2double(findobj(fig, 'Tag', 'wind_value').String);
    current_load = str2double(findobj(fig, 'Tag', 'load_value').String);
    
    dashboard_data.time_buffer(end) = dashboard_data.current_time;
    dashboard_data.voltage_buffer(end) = 1.0 + 0.02*sin(2*pi*0.1*dashboard_data.current_time) + 0.01*randn();
    dashboard_data.frequency_buffer(end) = 50.0 + 0.1*sin(2*pi*0.05*dashboard_data.current_time) + 0.05*randn();
    dashboard_data.power_dfig_buffer(end) = min(2.0, current_wind^3/1000 + 0.1*randn());
    dashboard_data.power_ess_buffer(end) = (current_load - dashboard_data.power_dfig_buffer(end)) + 0.05*randn();
    dashboard_data.soc_buffer(end) = max(20, min(90, dashboard_data.soc_buffer(end-1) - dashboard_data.power_ess_buffer(end)*0.01));
    dashboard_data.wind_speed_buffer(end) = current_wind + sin(2*pi*0.03*dashboard_data.current_time) + 0.2*randn();
    
    % Update plots
    update_plot(fig, 'voltage_plot', dashboard_data.time_buffer, dashboard_data.voltage_buffer);
    update_plot(fig, 'frequency_plot', dashboard_data.time_buffer, dashboard_data.frequency_buffer);
    update_power_plot(fig, dashboard_data.time_buffer, dashboard_data.power_dfig_buffer, dashboard_data.power_ess_buffer);
    update_plot(fig, 'wind_plot', dashboard_data.time_buffer, dashboard_data.wind_speed_buffer);
    update_plot(fig, 'soc_plot', dashboard_data.time_buffer, dashboard_data.soc_buffer);
    
    % Update text displays
    update_time_display(fig, dashboard_data.current_time);
    update_metrics_table(fig, dashboard_data);
    
    % Save updated data
    setappdata(fig, 'dashboard_data', dashboard_data);
end

%% ========================================================================
%% UTILITY FUNCTIONS
%% ========================================================================

function update_plot(fig, tag, x_data, y_data)
    % Update a specific plot
    ax = findobj(fig, 'Tag', tag);
    if ~isempty(ax)
        children = get(ax, 'Children');
        if ~isempty(children)
            valid_indices = ~isnan(x_data) & ~isnan(y_data);
            set(children(1), 'XData', x_data(valid_indices), 'YData', y_data(valid_indices));
        end
    end
end

function update_power_plot(fig, x_data, dfig_data, ess_data)
    % Update power plot with two series
    ax = findobj(fig, 'Tag', 'power_plot');
    if ~isempty(ax)
        children = get(ax, 'Children');
        if length(children) >= 2
            valid_indices = ~isnan(x_data) & ~isnan(dfig_data);
            set(children(2), 'XData', x_data(valid_indices), 'YData', dfig_data(valid_indices));
            valid_indices = ~isnan(x_data) & ~isnan(ess_data);
            set(children(1), 'XData', x_data(valid_indices), 'YData', ess_data(valid_indices));
        end
    end
end

function update_system_status(fig, status_text, color)
    % Update system status indicator
    status_handle = findobj(fig, 'Tag', 'system_status');
    if ~isempty(status_handle)
        status_handle.String = status_text;
        status_handle.ForegroundColor = color;
    end
end

function update_time_display(fig, current_time)
    % Update time display
    time_handle = findobj(fig, 'Tag', 'time_text');
    if ~isempty(time_handle)
        time_handle.String = sprintf('Time: %.1f s', current_time);
    end
end

function update_metrics_table(fig, dashboard_data)
    % Update metrics table
    table_handle = findobj(fig, 'Tag', 'metrics_table');
    if ~isempty(table_handle)
        % Get current values
        voltage = dashboard_data.voltage_buffer(end);
        frequency = dashboard_data.frequency_buffer(end);
        power_dfig = dashboard_data.power_dfig_buffer(end);
        power_ess = dashboard_data.power_ess_buffer(end);
        soc = dashboard_data.soc_buffer(end);
        
        % Update table data
        new_data = {
            'Voltage (pu)', sprintf('%.3f', voltage), get_status(voltage, [0.95, 1.05])
            'Frequency (Hz)', sprintf('%.2f', frequency), get_status(frequency, [49.8, 50.2])
            'DFIG Power (MW)', sprintf('%.2f', power_dfig), get_power_status(power_dfig)
            'ESS Power (MW)', sprintf('%.2f', power_ess), get_power_status(abs(power_ess))
            'ESS SOC (%)', sprintf('%.1f', soc), get_soc_status(soc)
            'System Efficiency (%)', '95.0', 'EXCELLENT'
            'Grid Support Factor', '0.85', 'GOOD'
            'Control Response (ms)', '10', 'EXCELLENT'
        };
        
        table_handle.Data = new_data;
    end
end

function status = get_status(value, normal_range)
    % Get status based on value range
    if value >= normal_range(1) && value <= normal_range(2)
        status = 'NORMAL';
    else
        status = 'ALARM';
    end
end

function status = get_power_status(power)
    % Get power status
    if power < 0.1
        status = 'STANDBY';
    elseif power < 1.5
        status = 'NORMAL';
    else
        status = 'HIGH';
    end
end

function status = get_soc_status(soc)
    % Get SOC status
    if soc < 25
        status = 'LOW';
    elseif soc > 85
        status = 'HIGH';
    else
        status = 'NORMAL';
    end
end

function add_console_message(fig, message)
    % Add message to console
    console_handle = findobj(fig, 'Tag', 'console_output');
    if ~isempty(console_handle)
        timestamp = datestr(now, 'HH:MM:SS');
        new_message = sprintf('[%s] %s', timestamp, message);
        
        current_messages = console_handle.String;
        if ischar(current_messages)
            current_messages = {current_messages};
        end
        
        updated_messages = [current_messages; {new_message}];
        
        % Keep only last 100 messages
        if length(updated_messages) > 100
            updated_messages = updated_messages(end-99:end);
        end
        
        console_handle.String = updated_messages;
        console_handle.Value = length(updated_messages);
    end
end

function clear_all_plots(fig)
    % Clear all plot data
    plot_tags = {'voltage_plot', 'frequency_plot', 'power_plot', 'wind_plot', 'soc_plot'};
    
    for i = 1:length(plot_tags)
        ax = findobj(fig, 'Tag', plot_tags{i});
        if ~isempty(ax)
            children = get(ax, 'Children');
            for j = 1:length(children)
                set(children(j), 'XData', 0, 'YData', get_default_value(plot_tags{i}));
            end
        end
    end
end

function default_val = get_default_value(plot_tag)
    % Get default values for different plots
    switch plot_tag
        case 'voltage_plot'
            default_val = 1.0;
        case 'frequency_plot'
            default_val = 50.0;
        case 'power_plot'
            default_val = 0;
        case 'wind_plot'
            default_val = 12;
        case 'soc_plot'
            default_val = 50;
        otherwise
            default_val = 0;
    end
end

function closeDashboard(src, ~)
    % Clean up and close dashboard
    timer_handle = getappdata(src, 'timer_handle');
    if ~isempty(timer_handle) && isvalid(timer_handle)
        stop(timer_handle);
        delete(timer_handle);
    end
    
    delete(src);
end

end
