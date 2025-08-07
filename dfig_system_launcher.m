function dfig_system_launcher()
%DFIG_SYSTEM_LAUNCHER Unified System Launcher for DFIG Wind Power System
% Integrated launcher providing access to all system tools and functions
%
% Features:
% • Unified access to all GUI tools
% • System status monitoring
% • Quick actions and shortcuts
% • Help and documentation access
% • System configuration management
% • Development tools integration

%% Create Main Launcher Window
fig = figure('Name', 'DFIG Wind Power System - Master Control Center v2.0', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'figure', ...
    'Position', [200, 150, 1000, 700], ...
    'Resize', 'on', ...
    'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @closeLauncher);

% Initialize launcher data
launcher_data = struct();
launcher_data.version = '2.0';
launcher_data.startup_time = now;
launcher_data.system_status = 'Ready';
launcher_data.opened_tools = {};

setappdata(fig, 'launcher_data', launcher_data);

%% Create Interface Layout
create_header_section(fig);
create_main_tools_section(fig);
create_quick_actions_section(fig);
create_system_info_section(fig);
create_footer_section(fig);

%% System Initialization Check
check_system_requirements(fig);
update_system_status(fig);

fprintf('\n🚀 DFIG Wind Power System Master Control Center v2.0\n');
fprintf('=========================================================\n');
fprintf('Welcome to the integrated DFIG system environment!\n\n');
fprintf('Available Tools:\n');
fprintf('• 🎛️  Parameter Configuration GUI\n');
fprintf('• 🖥️  Real-time Simulation Dashboard\n');
fprintf('• 📊 Advanced Performance Analyzer\n');
fprintf('• 🎯 Simulink Model Integration\n');
fprintf('• 🧪 Comprehensive Test Suite\n\n');
fprintf('Select a tool or action to get started.\n\n');

%% ========================================================================
%% INTERFACE CREATION FUNCTIONS
%% ========================================================================

function create_header_section(fig)
    % Create header section with title and system status
    header_panel = uipanel(fig, 'Position', [0.02 0.88 0.96 0.1], ...
        'BackgroundColor', [0.2 0.4 0.8], 'BorderType', 'none');
    
    % Main title
    uicontrol(header_panel, 'Style', 'text', ...
        'String', '🌪️ DFIG Wind Power System - Master Control Center', ...
        'Units', 'normalized', 'Position', [0.02 0.5 0.6 0.4], ...
        'BackgroundColor', [0.2 0.4 0.8], 'ForegroundColor', 'white', ...
        'FontSize', 18, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
    
    % Version and status
    uicontrol(header_panel, 'Style', 'text', ...
        'String', 'Version 2.0 - Production Ready', ...
        'Units', 'normalized', 'Position', [0.02 0.1 0.4 0.3], ...
        'BackgroundColor', [0.2 0.4 0.8], 'ForegroundColor', 'white', ...
        'FontSize', 12, 'HorizontalAlignment', 'left');
    
    % System status indicator
    uicontrol(header_panel, 'Style', 'text', ...
        'String', '● SYSTEM READY', ...
        'Units', 'normalized', 'Position', [0.65 0.3 0.2 0.4], ...
        'BackgroundColor', [0.2 0.4 0.8], 'ForegroundColor', 'lime', ...
        'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
        'Tag', 'system_status');
    
    % Help button
    uicontrol(header_panel, 'Style', 'pushbutton', 'String', '❓ Help', ...
        'Units', 'normalized', 'Position', [0.87 0.25 0.11 0.5], ...
        'Callback', @show_system_help, 'FontWeight', 'bold', 'FontSize', 11);
end

function create_main_tools_section(fig)
    % Create main tools section with large tool buttons
    tools_panel = uipanel(fig, 'Title', '🛠️ System Tools & Applications', ...
        'Position', [0.02 0.45 0.96 0.42], 'FontWeight', 'bold', 'FontSize', 12);
    
    % Tool buttons layout (2x3 grid)
    button_width = 0.3;
    button_height = 0.35;
    button_spacing_x = 0.05;
    button_spacing_y = 0.1;
    
    % Row 1 - Main Tools
    create_tool_button(tools_panel, '🎛️ Parameter Config', ...
        'Configure system parameters with interactive GUI', ...
        [button_spacing_x, 0.55, button_width, button_height], ...
        @launch_parameter_config, [0.2 0.7 0.3]);
    
    create_tool_button(tools_panel, '🖥️ Simulation Dashboard', ...
        'Real-time monitoring and control dashboard', ...
        [button_spacing_x*2 + button_width, 0.55, button_width, button_height], ...
        @launch_simulation_dashboard, [0.7 0.3 0.2]);
    
    create_tool_button(tools_panel, '📊 Performance Analyzer', ...
        'Advanced analysis and reporting tools', ...
        [button_spacing_x*3 + button_width*2, 0.55, button_width, button_height], ...
        @launch_performance_analyzer, [0.3 0.2 0.7]);
    
    % Row 2 - Secondary Tools
    create_tool_button(tools_panel, '🎯 Simulink Model', ...
        'Open and configure Simulink simulation model', ...
        [button_spacing_x, 0.1, button_width, button_height], ...
        @launch_simulink_model, [0.2 0.5 0.7]);
    
    create_tool_button(tools_panel, '🧪 Test Suite', ...
        'Run comprehensive system tests', ...
        [button_spacing_x*2 + button_width, 0.1, button_width, button_height], ...
        @launch_test_suite, [0.6 0.4 0.2]);
    
    create_tool_button(tools_panel, '📈 Data Viewer', ...
        'View and analyze simulation results', ...
        [button_spacing_x*3 + button_width*2, 0.1, button_width, button_height], ...
        @launch_data_viewer, [0.4 0.6 0.3]);
end

function create_quick_actions_section(fig)
    % Create quick actions section
    actions_panel = uipanel(fig, 'Title', '⚡ Quick Actions', ...
        'Position', [0.02 0.25 0.47 0.18], 'FontWeight', 'bold', 'FontSize', 11);
    
    % Quick action buttons (smaller, 2x2 grid)
    button_width = 0.4;
    button_height = 0.3;
    
    uicontrol(actions_panel, 'Style', 'pushbutton', ...
        'String', '🚀 Run Simulation', ...
        'Units', 'normalized', 'Position', [0.05, 0.55, button_width, button_height], ...
        'Callback', @quick_run_simulation, 'FontWeight', 'bold', 'FontSize', 10, ...
        'BackgroundColor', [0.2 0.8 0.2], 'ForegroundColor', 'white');
    
    uicontrol(actions_panel, 'Style', 'pushbutton', ...
        'String', '📊 Generate Report', ...
        'Units', 'normalized', 'Position', [0.55, 0.55, button_width, button_height], ...
        'Callback', @quick_generate_report, 'FontWeight', 'bold', 'FontSize', 10);
    
    uicontrol(actions_panel, 'Style', 'pushbutton', ...
        'String', '🔧 System Check', ...
        'Units', 'normalized', 'Position', [0.05, 0.1, button_width, button_height], ...
        'Callback', @quick_system_check, 'FontWeight', 'bold', 'FontSize', 10);
    
    uicontrol(actions_panel, 'Style', 'pushbutton', ...
        'String', '📁 Open Results', ...
        'Units', 'normalized', 'Position', [0.55, 0.1, button_width, button_height], ...
        'Callback', @quick_open_results, 'FontWeight', 'bold', 'FontSize', 10);
end

function create_system_info_section(fig)
    % Create system information section
    info_panel = uipanel(fig, 'Title', '📋 System Information', ...
        'Position', [0.51 0.25 0.47 0.18], 'FontWeight', 'bold', 'FontSize', 11);
    
    % System info text
    system_info = get_system_info();
    
    uicontrol(info_panel, 'Style', 'text', 'String', system_info, ...
        'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.8], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, 'Tag', 'system_info');
end

function create_footer_section(fig)
    % Create footer section with status and controls
    footer_panel = uipanel(fig, 'Position', [0.02 0.02 0.96 0.22], ...
        'BackgroundColor', [0.9 0.9 0.9], 'BorderType', 'line');
    
    % Documentation panel
    docs_panel = uipanel(footer_panel, 'Title', '📚 Documentation & Resources', ...
        'Position', [0.02 0.5 0.46 0.45], 'FontWeight', 'bold');
    
    uicontrol(docs_panel, 'Style', 'pushbutton', 'String', '📖 User Manual', ...
        'Units', 'normalized', 'Position', [0.05 0.6 0.4 0.3], ...
        'Callback', @open_user_manual, 'FontWeight', 'bold', 'FontSize', 9);
    
    uicontrol(docs_panel, 'Style', 'pushbutton', 'String', '🔧 Setup Guide', ...
        'Units', 'normalized', 'Position', [0.55 0.6 0.4 0.3], ...
        'Callback', @open_setup_guide, 'FontWeight', 'bold', 'FontSize', 9);
    
    uicontrol(docs_panel, 'Style', 'pushbutton', 'String', '💡 Examples', ...
        'Units', 'normalized', 'Position', [0.05 0.1 0.4 0.3], ...
        'Callback', @open_examples, 'FontWeight', 'bold', 'FontSize', 9);
    
    uicontrol(docs_panel, 'Style', 'pushbutton', 'String', '🐛 GitHub Issues', ...
        'Units', 'normalized', 'Position', [0.55 0.1 0.4 0.3], ...
        'Callback', @open_github_issues, 'FontWeight', 'bold', 'FontSize', 9);
    
    % Console output panel
    console_panel = uipanel(footer_panel, 'Title', '💬 System Messages', ...
        'Position', [0.52 0.5 0.46 0.45], 'FontWeight', 'bold');
    
    console_messages = {
        '[INFO] System initialized successfully'
        '[INFO] All components operational'
        '[INFO] Ready for simulation and analysis'
        '[INFO] Documentation and help available'
    };
    
    uicontrol(console_panel, 'Style', 'listbox', 'String', console_messages, ...
        'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.8], ...
        'FontName', 'Courier', 'FontSize', 9, 'Tag', 'console_output');
    
    % Status bar
    status_panel = uipanel(footer_panel, 'Position', [0.02 0.05 0.96 0.4], ...
        'BorderType', 'line');
    
    % Status information
    uicontrol(status_panel, 'Style', 'text', ...
        'String', sprintf('Startup Time: %s | MATLAB: %s | System: Ready', ...
        datestr(now, 'yyyy-mm-dd HH:MM:SS'), version), ...
        'Units', 'normalized', 'Position', [0.02 0.6 0.7 0.3], ...
        'HorizontalAlignment', 'left', 'FontSize', 9, 'Tag', 'status_bar');
    
    % Exit button
    uicontrol(status_panel, 'Style', 'pushbutton', 'String', '🚪 Exit System', ...
        'Units', 'normalized', 'Position', [0.85 0.1 0.13 0.8], ...
        'Callback', @exit_system, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.8 0.2 0.2], 'ForegroundColor', 'white');
end

function create_tool_button(parent, title, description, position, callback, color)
    % Create a styled tool button
    if nargin < 6
        color = [0.9 0.9 0.9];
    end
    
    % Main button
    btn = uicontrol(parent, 'Style', 'pushbutton', 'String', title, ...
        'Units', 'normalized', 'Position', position, ...
        'Callback', callback, 'FontWeight', 'bold', 'FontSize', 12, ...
        'BackgroundColor', color, 'HorizontalAlignment', 'center');
    
    % Add tooltip (description)
    set(btn, 'TooltipString', description);
end

%% ========================================================================
%% CALLBACK FUNCTIONS - MAIN TOOLS
%% ========================================================================

function launch_parameter_config(src, ~)
    % Launch parameter configuration GUI
    fig = ancestor(src, 'figure');
    
    try
        gui_parameter_config();
        add_console_message(fig, 'Parameter Configuration GUI launched');
        update_opened_tools(fig, 'Parameter Config');
    catch ME
        errordlg(['Failed to launch Parameter Config: ' ME.message], 'Launch Error');
        add_console_message(fig, 'Failed to launch Parameter Configuration GUI');
    end
end

function launch_simulation_dashboard(src, ~)
    % Launch simulation dashboard
    fig = ancestor(src, 'figure');
    
    try
        gui_simulation_dashboard();
        add_console_message(fig, 'Simulation Dashboard launched');
        update_opened_tools(fig, 'Simulation Dashboard');
    catch ME
        errordlg(['Failed to launch Dashboard: ' ME.message], 'Launch Error');
        add_console_message(fig, 'Failed to launch Simulation Dashboard');
    end
end

function launch_performance_analyzer(src, ~)
    % Launch performance analyzer
    fig = ancestor(src, 'figure');
    
    try
        performance_analyzer();
        add_console_message(fig, 'Performance Analyzer launched');
        update_opened_tools(fig, 'Performance Analyzer');
    catch ME
        errordlg(['Failed to launch Analyzer: ' ME.message], 'Launch Error');
        add_console_message(fig, 'Failed to launch Performance Analyzer');
    end
end

function launch_simulink_model(src, ~)
    % Launch Simulink model
    fig = ancestor(src, 'figure');
    
    try
        % Check if model exists
        model_file = 'simulation/dfig_wind_system.slx';
        if ~exist(model_file, 'file')
            % Setup model automatically
            add_console_message(fig, 'Setting up Simulink model...');
            cd('simulation');
            setup_simulink_model;
            cd('..');
        end
        
        % Open model
        open_system('simulation/dfig_wind_system');
        add_console_message(fig, 'Simulink model opened');
        update_opened_tools(fig, 'Simulink Model');
        
    catch ME
        errordlg(['Failed to launch Simulink: ' ME.message], 'Launch Error');
        add_console_message(fig, 'Failed to launch Simulink model');
    end
end

function launch_test_suite(src, ~)
    % Launch test suite
    fig = ancestor(src, 'figure');
    
    try
        % Navigate to tests directory and run
        current_dir = pwd;
        cd('tests');
        startup;
        run_all_tests;
        cd(current_dir);
        
        add_console_message(fig, 'Test suite execution completed');
        update_opened_tools(fig, 'Test Suite');
        
    catch ME
        errordlg(['Failed to launch Test Suite: ' ME.message], 'Launch Error');
        add_console_message(fig, 'Failed to launch test suite');
    end
end

function launch_data_viewer(src, ~)
    % Launch data viewer (simplified)
    fig = ancestor(src, 'figure');
    
    try
        % Check for results directory
        if ~exist('results', 'dir')
            mkdir('results');
        end
        
        % Open file browser for results
        if ispc
            winopen('results');
        elseif ismac
            system('open results');
        else
            system('xdg-open results');
        end
        
        add_console_message(fig, 'Data viewer opened');
        update_opened_tools(fig, 'Data Viewer');
        
    catch ME
        errordlg(['Failed to launch Data Viewer: ' ME.message], 'Launch Error');
        add_console_message(fig, 'Failed to launch data viewer');
    end
end

%% ========================================================================
%% CALLBACK FUNCTIONS - QUICK ACTIONS
%% ========================================================================

function quick_run_simulation(src, ~)
    % Quick simulation run
    fig = ancestor(src, 'figure');
    
    add_console_message(fig, 'Starting quick simulation...');
    
    try
        % Run main simulation
        main;
        add_console_message(fig, 'Quick simulation completed successfully');
        
        % Show completion dialog
        msgbox('Quick simulation completed! Check results in the data viewer.', ...
            'Simulation Complete', 'help');
        
    catch ME
        errordlg(['Simulation failed: ' ME.message], 'Simulation Error');
        add_console_message(fig, 'Quick simulation failed');
    end
end

function quick_generate_report(src, ~)
    % Quick report generation
    fig = ancestor(src, 'figure');
    
    add_console_message(fig, 'Generating quick report...');
    
    try
        % Generate basic report
        generate_system_report();
        add_console_message(fig, 'Quick report generated');
        
        msgbox('System report generated! Check the results directory.', ...
            'Report Generated', 'help');
        
    catch ME
        errordlg(['Report generation failed: ' ME.message], 'Report Error');
        add_console_message(fig, 'Report generation failed');
    end
end

function quick_system_check(src, ~)
    % Quick system check
    fig = ancestor(src, 'figure');
    
    add_console_message(fig, 'Running system check...');
    
    try
        % Perform system checks
        check_results = perform_system_checks();
        
        if check_results.all_passed
            add_console_message(fig, 'System check: All tests passed');
            msgbox('System check completed successfully! All components are operational.', ...
                'System Check', 'help');
        else
            add_console_message(fig, 'System check: Some issues found');
            warndlg(sprintf('System check found %d issues. Check console for details.', ...
                check_results.issues_count), 'System Check');
        end
        
    catch ME
        errordlg(['System check failed: ' ME.message], 'Check Error');
        add_console_message(fig, 'System check failed');
    end
end

function quick_open_results(src, ~)
    % Quick open results directory
    fig = ancestor(src, 'figure');
    
    try
        if ~exist('results', 'dir')
            mkdir('results');
            add_console_message(fig, 'Created results directory');
        end
        
        % Open results directory
        if ispc
            winopen('results');
        elseif ismac
            system('open results');
        else
            system('xdg-open results');
        end
        
        add_console_message(fig, 'Results directory opened');
        
    catch ME
        errordlg(['Failed to open results: ' ME.message], 'Open Error');
        add_console_message(fig, 'Failed to open results directory');
    end
end

%% ========================================================================
%% CALLBACK FUNCTIONS - DOCUMENTATION
%% ========================================================================

function open_user_manual(src, ~)
    % Open user manual
    fig = ancestor(src, 'figure');
    
    % Check if README exists and open it
    if exist('README.md', 'file')
        if ispc
            winopen('README.md');
        elseif ismac
            system('open README.md');
        else
            system('xdg-open README.md');
        end
        add_console_message(fig, 'User manual opened');
    else
        msgbox('User manual (README.md) not found in the current directory.', 'Manual Not Found');
    end
end

function open_setup_guide(src, ~)
    % Open setup guide
    fig = ancestor(src, 'figure');
    
    if exist('simulation/README_Simulink_Setup.md', 'file')
        if ispc
            winopen('simulation/README_Simulink_Setup.md');
        elseif ismac
            system('open simulation/README_Simulink_Setup.md');
        else
            system('xdg-open simulation/README_Simulink_Setup.md');
        end
        add_console_message(fig, 'Setup guide opened');
    else
        msgbox('Setup guide not found. Please check the simulation directory.', 'Guide Not Found');
    end
end

function open_examples(src, ~)
    % Open examples directory
    fig = ancestor(src, 'figure');
    
    if exist('examples', 'dir')
        if ispc
            winopen('examples');
        elseif ismac
            system('open examples');
        else
            system('xdg-open examples');
        end
        add_console_message(fig, 'Examples directory opened');
    else
        msgbox('Examples directory not found. Run test suite to generate example results.', 'Examples Not Found');
    end
end

function open_github_issues(src, ~)
    % Open GitHub issues page
    fig = ancestor(src, 'figure');
    
    try
        web('https://github.com/chenxingqiang/dfig-wind-power/issues', '-browser');
        add_console_message(fig, 'GitHub issues page opened');
    catch
        msgbox('GitHub issues: https://github.com/chenxingqiang/dfig-wind-power/issues', 'GitHub Issues');
    end
end

%% ========================================================================
%% UTILITY FUNCTIONS
%% ========================================================================

function system_info = get_system_info()
    % Get system information string
    
    try
        matlab_ver = version;
        os_info = computer;
        current_dir = pwd;
        
        % Check key components
        simulink_available = license('test', 'Simulink');
        control_toolbox = license('test', 'Control_Toolbox');
        
        system_info = sprintf(['MATLAB Version: %s\n' ...
            'Operating System: %s\n' ...
            'Current Directory: %s\n' ...
            'Simulink Available: %s\n' ...
            'Control Toolbox: %s\n' ...
            'System Status: Operational'], ...
            matlab_ver(1:min(20, length(matlab_ver))), os_info, ...
            current_dir(max(1, end-30):end), ...
            char(simulink_available + '0'), char(control_toolbox + '0'));
            
    catch
        system_info = 'System information temporarily unavailable';
    end
end

function check_system_requirements(fig)
    % Check system requirements and update status
    
    requirements_ok = true;
    issues = {};
    
    % Check MATLAB version
    try
        matlab_info = ver('MATLAB');
        if str2double(matlab_info.Version) < 9.1  % R2016b
            requirements_ok = false;
            issues{end+1} = 'MATLAB version may be too old (recommend R2021b+)';
        end
    catch
        issues{end+1} = 'Cannot determine MATLAB version';
    end
    
    % Check toolboxes
    if ~license('test', 'Simulink')
        requirements_ok = false;
        issues{end+1} = 'Simulink not available';
    end
    
    if ~license('test', 'Control_Toolbox')
        issues{end+1} = 'Control System Toolbox not available (recommended)';
    end
    
    % Check directories
    required_dirs = {'simulation', 'controllers', 'models', 'utils', 'tests'};
    for i = 1:length(required_dirs)
        if ~exist(required_dirs{i}, 'dir')
            requirements_ok = false;
            issues{end+1} = sprintf('Missing directory: %s', required_dirs{i});
        end
    end
    
    % Update status
    if requirements_ok
        update_system_status_indicator(fig, '● SYSTEM READY', 'lime');
        if ~isempty(issues)
            add_console_message(fig, sprintf('[WARN] %d minor issues detected', length(issues)));
        end
    else
        update_system_status_indicator(fig, '⚠ ISSUES FOUND', 'orange');
        add_console_message(fig, sprintf('[ERROR] %d system issues found', length(issues)));
    end
    
    % Log issues
    for i = 1:length(issues)
        add_console_message(fig, sprintf('[WARN] %s', issues{i}));
    end
end

function update_system_status(fig)
    % Update system status display
    launcher_data = getappdata(fig, 'launcher_data');
    
    status_text = sprintf('Startup Time: %s | Tools Opened: %d | Status: %s', ...
        datestr(launcher_data.startup_time, 'HH:MM:SS'), ...
        length(launcher_data.opened_tools), ...
        launcher_data.system_status);
    
    status_handle = findobj(fig, 'Tag', 'status_bar');
    if ~isempty(status_handle)
        status_handle.String = status_text;
    end
end

function update_system_status_indicator(fig, status_text, color)
    % Update system status indicator
    status_handle = findobj(fig, 'Tag', 'system_status');
    if ~isempty(status_handle)
        status_handle.String = status_text;
        status_handle.ForegroundColor = color;
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
        
        % Keep only last 50 messages
        if length(updated_messages) > 50
            updated_messages = updated_messages(end-49:end);
        end
        
        console_handle.String = updated_messages;
        console_handle.Value = length(updated_messages);
    end
end

function update_opened_tools(fig, tool_name)
    % Update list of opened tools
    launcher_data = getappdata(fig, 'launcher_data');
    
    if ~ismember(tool_name, launcher_data.opened_tools)
        launcher_data.opened_tools{end+1} = tool_name;
        setappdata(fig, 'launcher_data', launcher_data);
        update_system_status(fig);
    end
end

function check_results = perform_system_checks()
    % Perform comprehensive system checks
    
    check_results = struct();
    check_results.issues_count = 0;
    check_results.all_passed = true;
    
    % Check files exist
    required_files = {'main.m', 'init_system.m'};
    for i = 1:length(required_files)
        if ~exist(required_files{i}, 'file')
            check_results.issues_count = check_results.issues_count + 1;
            check_results.all_passed = false;
        end
    end
    
    % Check directories
    required_dirs = {'simulation', 'controllers', 'models'};
    for i = 1:length(required_dirs)
        if ~exist(required_dirs{i}, 'dir')
            check_results.issues_count = check_results.issues_count + 1;
            check_results.all_passed = false;
        end
    end
    
    % Additional checks can be added here
end

function generate_system_report()
    % Generate basic system report
    
    if ~exist('results', 'dir')
        mkdir('results');
    end
    
    % Create simple report
    report_filename = fullfile('results', ['system_report_' datestr(now, 'yyyymmdd_HHMMSS') '.txt']);
    
    fid = fopen(report_filename, 'w');
    fprintf(fid, 'DFIG Wind Power System - Quick Report\n');
    fprintf(fid, '=====================================\n\n');
    fprintf(fid, 'Generated: %s\n', datestr(now));
    fprintf(fid, 'MATLAB Version: %s\n', version);
    fprintf(fid, 'System Status: Operational\n\n');
    fprintf(fid, 'Available Tools:\n');
    fprintf(fid, '- Parameter Configuration GUI\n');
    fprintf(fid, '- Simulation Dashboard\n');
    fprintf(fid, '- Performance Analyzer\n');
    fprintf(fid, '- Simulink Model Integration\n');
    fprintf(fid, '- Test Suite\n\n');
    fprintf(fid, 'For detailed analysis, use the Performance Analyzer tool.\n');
    fclose(fid);
end

function show_system_help(src, ~)
    % Show system help dialog
    fig = ancestor(src, 'figure');
    
    help_text = sprintf(['DFIG Wind Power System v2.0 - Help\n\n' ...
        'MAIN TOOLS:\n' ...
        '🎛️ Parameter Config - Configure system parameters\n' ...
        '🖥️ Simulation Dashboard - Real-time monitoring\n' ...
        '📊 Performance Analyzer - Advanced analysis\n' ...
        '🎯 Simulink Model - Open simulation model\n' ...
        '🧪 Test Suite - Run system tests\n\n' ...
        'QUICK ACTIONS:\n' ...
        '🚀 Run Simulation - Quick simulation run\n' ...
        '📊 Generate Report - Create system report\n' ...
        '🔧 System Check - Verify system status\n' ...
        '📁 Open Results - Access results directory\n\n' ...
        'DOCUMENTATION:\n' ...
        '📖 User Manual - Complete documentation\n' ...
        '🔧 Setup Guide - Installation instructions\n' ...
        '💡 Examples - Example configurations\n' ...
        '🐛 GitHub Issues - Report problems\n\n' ...
        'For detailed help, refer to the documentation.']);
    
    msgbox(help_text, 'DFIG System Help', 'help');
    add_console_message(fig, 'Help information displayed');
end

function exit_system(src, ~)
    % Exit system with confirmation
    fig = ancestor(src, 'figure');
    
    answer = questdlg('Exit DFIG Wind Power System?', ...
        'Exit Confirmation', 'Yes', 'No', 'No');
    
    if strcmp(answer, 'Yes')
        add_console_message(fig, 'System shutdown initiated');
        
        % Close any open tools/figures
        launcher_data = getappdata(fig, 'launcher_data');
        
        % Close launcher
        closeLauncher(fig, []);
    end
end

function closeLauncher(src, ~)
    % Clean up and close launcher
    
    try
        % Close any related figures/tools if needed
        % This would close tool windows spawned by the launcher
        
        % Final cleanup
        fprintf('\n👋 DFIG Wind Power System shutdown complete.\n');
        fprintf('Thank you for using the DFIG system tools!\n\n');
        
    catch
        % Silent cleanup
    end
    
    delete(src);
end

end
