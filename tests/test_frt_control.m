%% Test Fault Ride-Through Control
% Test script for FRT control functionality

clear;
clc;

%% Test Setup
% Load configuration
config;

% Initialize components
dfig = dfig_model(dfig_params);
ess = ess_model(ess_params);
grid = grid_model(grid_params);
lstm_predictor = lstm_predictor(lstm_config);

% Initialize test parameters
test_duration = 3;  % seconds
Ts = 0.001;        % sampling time
t = 0:Ts:test_duration;
n_samples = length(t);

% Initialize data storage
voltage_data = zeros(n_samples, 1);
current_data = zeros(n_samples, 1);
power_data = zeros(n_samples, 1);
reactive_power_data = zeros(n_samples, 1);
lstm_prediction_data = zeros(n_samples, 1);
mode_data = zeros(n_samples, 1);

%% Test Cases

% Test Case 1: Symmetric Voltage Dip
fprintf('\nTest Case 1: Symmetric Voltage Dip Response\n');
run_voltage_dip_test(0.2, 0.15);  % 20% remaining voltage, 150ms

% Test Case 2: Asymmetric Voltage Dip
fprintf('\nTest Case 2: Asymmetric Voltage Dip Response\n');
run_voltage_dip_test(0.5, 0.2);   % 50% remaining voltage, 200ms

% Test Case 3: Multiple Voltage Dips
fprintf('\nTest Case 3: Multiple Voltage Dips Response\n');
run_multiple_dips_test();

%% Test Functions
function run_voltage_dip_test(remaining_voltage, duration)
    % Apply voltage dip
    fault_params = struct(...
        'type', 'voltage_dip',...
        'remaining_voltage', remaining_voltage,...
        'duration', duration...
    );
    
    % Run simulation
    for i = 1:n_samples
        % Apply fault
        if t(i) >= 1.0 && t(i) < (1.0 + duration)
            grid_state = grid.apply_fault(fault_params);
        else
            grid_state = grid.get_states();
        end
        
        % Get LSTM prediction
        [prediction, confidence] = lstm_predictor.predict(create_lstm_input(grid_state));
        
        % Get system state
        state = struct(...
            'grid_voltage', grid_state.voltage,...
            'grid_frequency', grid_state.frequency,...
            'time', t(i),...
            'soc', ess.get_states().soc...
        );
        
        % Execute FRT control
        [dfig_refs, ess_refs] = frt_control(state, ...
            struct('power_demand', prediction, 'confidence', confidence), ...
            params);
        
        % Store data
        store_data(i, state, dfig_refs, ess_refs, prediction);
    end
    
    % Analyze results
    analyze_results(remaining_voltage);
end

function run_multiple_dips_test()
    % Define multiple dips
    dips = [...
        1.0, 0.3, 0.1;   % time, remaining voltage, duration
        1.5, 0.5, 0.15;
        2.0, 0.4, 0.12
    ];
    
    % Run simulation
    for i = 1:n_samples
        % Check for dips
        grid_state = grid.get_states();
        for j = 1:size(dips, 1)
            if t(i) >= dips(j,1) && t(i) < (dips(j,1) + dips(j,3))
                fault_params = struct(...
                    'type', 'voltage_dip',...
                    'remaining_voltage', dips(j,2),...
                    'duration', dips(j,3)...
                );
                grid_state = grid.apply_fault(fault_params);
                break;
            end
        end
        
        % Get LSTM prediction
        [prediction, confidence] = lstm_predictor.predict(create_lstm_input(grid_state));
        
        % Get system state
        state = struct(...
            'grid_voltage', grid_state.voltage,...
            'grid_frequency', grid_state.frequency,...
            'time', t(i),...
            'soc', ess.get_states().soc...
        );
        
        % Execute FRT control
        [dfig_refs, ess_refs] = frt_control(state, ...
            struct('power_demand', prediction, 'confidence', confidence), ...
            params);
        
        % Store data
        store_data(i, state, dfig_refs, ess_refs, prediction);
    end
    
    % Analyze results for multiple dips
    analyze_multiple_dips_results();
end

function lstm_input = create_lstm_input(grid_state)
    % Create input for LSTM predictor
    lstm_input = struct(...
        'grid_voltage', grid_state.voltage,...
        'grid_frequency', grid_state.frequency,...
        'power_output', dfig.get_states().power_output,...
        'wind_speed', 12,...  % Example wind speed
        'soc', ess.get_states().soc...
    );
end

function store_data(idx, state, dfig_refs, ess_refs, prediction)
    % Store simulation data
    voltage_data(idx) = state.grid_voltage;
    current_data(idx) = sqrt(dfig_refs.Id_ref^2 + dfig_refs.Iq_ref^2);
    power_data(idx) = ess_refs.P_ref;
    reactive_power_data(idx) = ess_refs.Q_ref;
    lstm_prediction_data(idx) = prediction;
end

function analyze_results(remaining_voltage)
    % Analyze test results
    
    % Current limiting check
    max_current = max(current_data);
    fprintf('Maximum current during fault: %.2f p.u.\n', max_current);
    assert(max_current <= params.current_limit, 'Current limit violated');
    
    % Voltage recovery check
    voltage_recovery = voltage_data(end);
    fprintf('Final voltage: %.2f p.u.\n', voltage_recovery);
    assert(voltage_recovery > 0.9, 'Voltage recovery insufficient');
    
    % Recovery time check
    recovery_idx = find(voltage_data(n_samples/2:end) >= 0.9, 1);
    recovery_time = recovery_idx * Ts;
    fprintf('Recovery time: %.2f ms\n', recovery_time * 1000);
    assert(recovery_time <= 0.15, 'Recovery time too long');
    
    % Reactive power support check
    max_q_support = max(abs(reactive_power_data));
    fprintf('Maximum reactive power support: %.2f p.u.\n', max_q_support);
    
    % LSTM prediction accuracy
    prediction_error = mean(abs(power_data - lstm_prediction_data));
    fprintf('Average LSTM prediction error: %.2f p.u.\n', prediction_error);
end

function analyze_multiple_dips_results()
    % Analyze results for multiple dips scenario
    
    % Check recovery between dips
    dip_recoveries = find(diff(voltage_data < 0.9) == -1);
    recovery_times = diff(dip_recoveries) * Ts;
    fprintf('Average recovery time between dips: %.2f ms\n', mean(recovery_times) * 1000);
    
    % Check cumulative stress
    cumulative_stress = sum(current_data > params.rated_current) * Ts;
    fprintf('Cumulative overcurrent duration: %.2f ms\n', cumulative_stress * 1000);
    
    % Check ESS utilization
    ess_energy = trapz(t, power_data) * Ts;
    fprintf('Total ESS energy contribution: %.2f p.u.*s\n', ess_energy);
end

%% Advanced Analysis and Visualization
% Create multiple figures for different analysis aspects
figure_main = figure('Position', [100, 100, 1200, 1400], 'Name', 'FRT Control Analysis');
figure_comparison = figure('Position', [1300, 100, 800, 1200], 'Name', 'Fault Response Comparison');
figure_interactive = figure('Position', [100, 100, 1000, 800], 'Name', 'Interactive Analysis');

% Enhanced color scheme with gradients
colors = struct(...
    'voltage', [0.2 0.5 0.9],...
    'current', [0.9 0.3 0.3],...
    'power', [0.3 0.7 0.4],...
    'reactive', [0.6 0.4 0.7],...
    'prediction', [0.4 0.3 0.8],...
    'fault', [0.8 0.2 0.2],...
    'recovery', [0.2 0.8 0.2],...
    'background', [0.95 0.95 0.95],...
    'gradient_start', [0.9 0.9 1.0],...
    'gradient_end', [0.2 0.2 0.4]);

%% Main Analysis Figure
figure(figure_main);

% Create enhanced subplot layout
subplot_layout = struct(...
    'main', [0.1 0.35 0.6 0.6],... % Main time series plots
    'response', [0.75 0.35 0.2 0.2],... % Response characteristics
    'stats', [0.75 0.6 0.2 0.35],... % Statistics
    'analysis', [0.1 0.1 0.85 0.2]... % Fault analysis
);

% Main time series plots with enhanced features
subplot('Position', subplot_layout.main);
create_main_plots();

% Enhanced response characteristics
axes('Position', subplot_layout.response);
create_response_characteristics();

% Enhanced statistics panel
axes('Position', subplot_layout.stats);
create_performance_metrics();

% Enhanced fault analysis
axes('Position', subplot_layout.analysis);
create_fault_analysis();

%% Comparison Analysis Figure
figure(figure_comparison);

% Create comparison subplots
subplot(3,1,1);
create_fault_comparison_plot();

subplot(3,1,2);
create_response_strategy_plot();

subplot(3,1,3);
create_lstm_performance_plot();

%% Interactive Analysis Figure
figure(figure_interactive);

% Create interactive elements
create_interactive_analysis();

% Save all figures
save_analysis_figures();

% Helper functions for main analysis
function create_main_plots()
    % Enhanced main plots with gradient backgrounds
    create_voltage_plot();
    create_current_plot();
    create_active_power_plot();
    create_reactive_power_plot();
    create_lstm_plot();
end

function create_voltage_plot()
    subplot(5,1,1);
    plot_with_gradient(t, voltage_data, colors.voltage, 'Grid Voltage', 'Voltage (p.u.)', [0 1.1]);
    add_tooltips('voltage');
end

function create_current_plot()
    subplot(5,1,2);
    plot_with_gradient(t, current_data, colors.current, 'Total Current', 'Current (p.u.)', ...
        [0 params.current_limit*1.2], {'Current Limit'});
    add_tooltips('current');
end

function create_active_power_plot()
    subplot(5,1,3);
    plot_with_gradient(t, power_data, colors.power, 'ESS Active Power', 'P (p.u.)', []);
    add_tooltips('power');
end

function create_reactive_power_plot()
    subplot(5,1,4);
    plot_with_gradient(t, reactive_power_data, colors.reactive, 'ESS Reactive Power', 'Q (p.u.)', []);
    add_tooltips('reactive');
end

function create_lstm_plot()
    subplot(5,1,5);
    plot_lstm_comparison();
    add_tooltips('lstm');
end

% Enhanced plotting functions
function plot_with_gradient(t, data, color, title_str, ylabel_str, ylim_range, limit_labels)
    % Create gradient background
    hold on;
    fill_gradient_background();
    
    % Plot data with enhanced styling
    plot(t, data, 'Color', color, 'LineWidth', 1.5);
    
    % Add limits if provided
    if nargin >= 7
        for i = 1:length(ylim_range)-1
            yline(ylim_range(i+1), '--r', limit_labels{i});
        end
    end
    
    % Add styling
    title(title_str, 'FontWeight', 'bold');
    ylabel(ylabel_str);
    if ~isempty(ylim_range)
        ylim(ylim_range);
    end
    grid on;
    
    % Add interactive elements
    add_data_cursor();
    add_zoom_buttons();
    add_fault_highlights();
end

function fill_gradient_background()
    % Create gradient background effect
    yl = ylim;
    xl = xlim;
    
    % Create gradient mesh
    [X,Y] = meshgrid(xl(1):0.1:xl(2), yl(1):0.1:yl(2));
    C = Y*0 + 1;
    
    % Plot gradient
    surface(X,Y,zeros(size(X))-1,C,...
        'EdgeColor','none',...
        'FaceColor','interp',...
        'FaceAlpha',0.1);
end

function plot_lstm_comparison()
    plot(t, lstm_prediction_data, 'Color', colors.prediction, 'LineWidth', 1.5);
    hold on;
    plot(t, power_data, '--', 'Color', colors.power, 'LineWidth', 1.5);
    hold off;
    title('LSTM Prediction vs Actual Power', 'FontWeight', 'bold');
    ylabel('Power (p.u.)');
    xlabel('Time (s)');
    legend('Predicted', 'Actual', 'Location', 'southeast');
    grid on;
    add_fault_highlights();
end

function add_fault_highlights()
    hold on;
    % Find fault periods
    fault_regions = voltage_data < 0.9;
    area(t, fault_regions * ylim(2), 'FaceColor', colors.fault, ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none');
    
    % Find recovery periods
    recovery_regions = [0; diff(voltage_data > 0.9) == 1];
    area(t, recovery_regions * ylim(2), 'FaceColor', colors.recovery, ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none');
    
    % Add fault duration labels
    fault_starts = find(diff(fault_regions) == 1);
    fault_ends = find(diff(fault_regions) == -1);
    
    if ~isempty(fault_starts)
        for i = 1:length(fault_starts)
            if i <= length(fault_ends)
                duration_ms = (t(fault_ends(i)) - t(fault_starts(i))) * 1000;
                midpoint = t(fault_starts(i)) + ...
                    (t(fault_ends(i)) - t(fault_starts(i)))/2;
                text(midpoint, ylim(2), sprintf('%.0f ms', duration_ms), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'Color', colors.fault);
            end
        end
    end
    hold off;
end

% Interactive elements
function add_data_cursor()
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', @custom_data_cursor);
end

function add_zoom_buttons()
    % Add custom zoom controls
    uicontrol('Style', 'pushbutton',...
        'String', 'Zoom In',...
        'Position', [10 10 60 20],...
        'Callback', @zoom_in_callback);
    
    uicontrol('Style', 'pushbutton',...
        'String', 'Zoom Out',...
        'Position', [80 10 60 20],...
        'Callback', @zoom_out_callback);
end

function add_tooltips(data_type)
    % Add tooltips based on data type
    switch data_type
        case 'voltage'
            title(sprintf('Voltage Analysis\nClick for details'), 'ButtonDownFcn', @voltage_tooltip);
        case 'current'
            title(sprintf('Current Analysis\nClick for details'), 'ButtonDownFcn', @current_tooltip);
        case 'power'
            title(sprintf('Active Power Analysis\nClick for details'), 'ButtonDownFcn', @power_tooltip);
        case 'reactive'
            title(sprintf('Reactive Power Analysis\nClick for details'), 'ButtonDownFcn', @reactive_tooltip);
        case 'lstm'
            title(sprintf('LSTM Analysis\nClick for details'), 'ButtonDownFcn', @lstm_tooltip);
    end
end

% Callback functions
function txt = custom_data_cursor(~, event_obj)
    pos = get(event_obj, 'Position');
    txt = sprintf('Time: %.3fs\nValue: %.3f', pos(1), pos(2));
end

function zoom_in_callback(~, ~)
    zoom(gca, 1.2);
end

function zoom_out_callback(~, ~)
    zoom(gca, 0.8);
end

% Tooltip callbacks
function voltage_tooltip(~, ~)
    voltage_stats = calculate_voltage_statistics();
    msgbox(sprintf('Voltage Analysis\n\nMin: %.2f p.u.\nRecovery: %.1f ms\nDips: %d', ...
        voltage_stats.min_voltage, voltage_stats.recovery_time*1000, voltage_stats.n_dips));
end

function current_tooltip(~, ~)
    current_stats = calculate_current_statistics();
    msgbox(sprintf('Current Analysis\n\nMax: %.2f p.u.\nRMS: %.2f p.u.\nLimit Violations: %d', ...
        current_stats.max_current, current_stats.rms, current_stats.violations));
end

function power_tooltip(~, ~)
    power_stats = calculate_power_statistics();
    msgbox(sprintf('Active Power Analysis\n\nMax: %.2f p.u.\nMin: %.2f p.u.\nEnergy: %.2f p.u.s', ...
        power_stats.max_power, power_stats.min_power, power_stats.energy));
end

function reactive_tooltip(~, ~)
    reactive_stats = calculate_reactive_statistics();
    msgbox(sprintf('Reactive Power Analysis\n\nMax: %.2f p.u.\nAvg Support: %.2f p.u.\nEnergy: %.2f p.u.s', ...
        reactive_stats.max_q, reactive_stats.avg_q, reactive_stats.q_energy));
end

function lstm_tooltip(~, ~)
    lstm_stats = calculate_lstm_statistics();
    msgbox(sprintf('LSTM Analysis\n\nRMSE: %.2f%%\nMax Error: %.2f%%\nCorrelation: %.2f', ...
        lstm_stats.rmse*100, lstm_stats.max_error*100, lstm_stats.correlation));
end

% Save functions
function save_analysis_figures()
    % Save main analysis
    figure(figure_main);
    saveas(gcf, 'test_results/frt_control_analysis_main.png');
    
    % Save comparison analysis
    figure(figure_comparison);
    saveas(gcf, 'test_results/frt_control_comparison.png');
    
    % Save interactive analysis
    figure(figure_interactive);
    saveas(gcf, 'test_results/frt_control_interactive.png');
    
    fprintf('Enhanced analysis figures saved to test_results/\n');
end

%% Additional Analysis Features
function create_response_characteristics()
    % Calculate response characteristics
    voltage_dips = findpeaks(-voltage_data);
    current_peaks = findpeaks(current_data);
    reactive_peaks = findpeaks(abs(reactive_power_data));
    
    % Create scatter plot with size based on reactive power
    scatter(voltage_dips, current_peaks, 50 + abs(reactive_peaks)*100, colors.fault, 'filled', 'MarkerFaceAlpha', 0.6);
    
    % Add trend line
    p = polyfit(voltage_dips, current_peaks, 1);
    hold on;
    plot(voltage_dips, polyval(p, voltage_dips), '--', 'Color', colors.power);
    
    % Add current limit reference
    yline(params.current_limit, '--r', 'Current Limit');
    
    title('FRT Response Characteristics', 'FontWeight', 'bold');
    xlabel('Voltage Dip (p.u.)');
    ylabel('Current Peak (p.u.)');
    grid on;
    
    % Add colorbar for reactive power
    colormap(gca, winter);
    cb = colorbar;
    cb.Label.String = 'Reactive Power Support (p.u.)';
end

function create_performance_metrics()
    % Calculate comprehensive metrics
    metrics = calculate_comprehensive_metrics();
    
    % Create performance radar chart
    theta = [0 2*pi/6 4*pi/6 6*pi/6 8*pi/6 10*pi/6];
    rho = [metrics.voltage_recovery, metrics.current_limiting, ...
           metrics.reactive_support, metrics.active_support, ...
           metrics.lstm_accuracy, metrics.response_speed];
    
    polarplot(theta, rho, '-o', 'LineWidth', 2, 'Color', colors.power);
    title('Performance Metrics', 'FontWeight', 'bold');
    
    % Add metric labels
    labels = {'Voltage Recovery', 'Current Limiting', 'Reactive Support', ...
              'Active Support', 'LSTM Accuracy', 'Response Speed'};
    thetaticks(0:60:300);
    thetaticklabels(labels);
    rticks(0:0.2:1);
    grid on;
end

function metrics = calculate_comprehensive_metrics()
    % Calculate normalized performance metrics
    metrics = struct();
    
    % Voltage recovery metric
    metrics.voltage_recovery = mean(voltage_data > 0.9);
    
    % Current limiting effectiveness
    metrics.current_limiting = 1 - mean(current_data > params.current_limit);
    
    % Reactive power support
    metrics.reactive_support = mean(abs(reactive_power_data)) / params.rated_power;
    
    % Active power support
    metrics.active_support = mean(abs(power_data)) / params.rated_power;
    
    % LSTM prediction accuracy
    metrics.lstm_accuracy = 1 - mean(abs(power_data - lstm_prediction_data)) / params.rated_power;
    
    % Response speed
    fault_starts = find(diff(voltage_data < 0.9) == 1);
    response_times = zeros(size(fault_starts));
    for i = 1:length(fault_starts)
        response_times(i) = find(current_data(fault_starts(i):end) > 0.1, 1) * Ts;
    end
    metrics.response_speed = 1 - mean(response_times) / 0.02; % Normalized to 20ms
end

function create_fault_analysis()
    % Create fault severity timeline
    hold on;
    
    % Plot voltage profile with gradient coloring
    voltage_severity = 1 - voltage_data;
    patch([t fliplr(t)], [voltage_severity' zeros(size(voltage_severity'))], ...
          'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    
    % Add recovery markers
    recovery_points = find(diff(voltage_data > 0.9) == 1);
    plot(t(recovery_points), zeros(size(recovery_points)), '^', ...
         'Color', colors.recovery, 'MarkerFaceColor', colors.recovery);
    
    % Add current violation markers
    violation_points = find(current_data > params.current_limit);
    if ~isempty(violation_points)
        plot(t(violation_points), ones(size(violation_points)), 'v', ...
             'Color', colors.fault, 'MarkerFaceColor', colors.fault);
    end
    
    % Add LSTM prediction error bands
    prediction_error = abs(power_data - lstm_prediction_data);
    patch([t fliplr(t)], [prediction_error' zeros(size(prediction_error'))], ...
          'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    
    hold off;
    title('Fault Analysis Timeline', 'FontWeight', 'bold');
    ylabel('Severity / Error');
    ylim([-0.1 1.1]);
    grid on;
    
    % Add legend
    legend('Voltage Dip', 'Recovery Point', 'Current Violation', 'LSTM Error');
end

function create_fault_comparison_plot()
    % Compare different fault scenarios
    subplot(3,1,1);
    plot_voltage_comparison();
    
    subplot(3,1,2);
    plot_current_comparison();
    
    subplot(3,1,3);
    plot_power_comparison();
end

function plot_voltage_comparison()
    % Plot voltage profiles for different scenarios
    hold on;
    plot(t, voltage_data, 'Color', colors.voltage, 'LineWidth', 1.5);
    yline(0.9, '--k', 'Recovery Threshold');
    hold off;
    title('Voltage Comparison', 'FontWeight', 'bold');
    ylabel('Voltage (p.u.)');
    grid on;
end

function plot_current_comparison()
    % Plot current responses
    hold on;
    plot(t, current_data, 'Color', colors.current, 'LineWidth', 1.5);
    yline(params.current_limit, '--r', 'Current Limit');
    hold off;
    title('Current Response', 'FontWeight', 'bold');
    ylabel('Current (p.u.)');
    grid on;
end

function plot_power_comparison()
    % Plot power support comparison
    hold on;
    plot(t, power_data, 'Color', colors.power, 'LineWidth', 1.5);
    plot(t, reactive_power_data, '--', 'Color', colors.reactive, 'LineWidth', 1.5);
    hold off;
    title('Power Support', 'FontWeight', 'bold');
    ylabel('Power (p.u.)');
    legend('Active Power', 'Reactive Power');
    grid on;
end

function create_response_strategy_plot()
    % Create visualization of control strategy
    subplot(2,1,1);
    plot_control_priorities();
    
    subplot(2,1,2);
    plot_support_distribution();
end

function plot_control_priorities()
    % Visualize control priority changes
    priorities = calculate_control_priorities();
    area(t, priorities, 'FaceAlpha', 0.5);
    title('Control Priorities', 'FontWeight', 'bold');
    ylabel('Priority Level');
    legend('Voltage Support', 'Current Limiting', 'Power Balance');
    grid on;
end

function priorities = calculate_control_priorities()
    % Calculate dynamic control priorities
    voltage_priority = 1 - voltage_data;
    current_priority = current_data / params.current_limit;
    power_priority = abs(power_data) / params.rated_power;
    
    priorities = [voltage_priority current_priority power_priority];
end

function plot_support_distribution()
    % Visualize distribution of support mechanisms
    support_dist = calculate_support_distribution();
    area(t, support_dist, 'FaceAlpha', 0.5);
    title('Support Distribution', 'FontWeight', 'bold');
    ylabel('Contribution');
    legend('DFIG', 'ESS', 'Grid');
    grid on;
end

function support_dist = calculate_support_distribution()
    % Calculate support distribution among components
    dfig_support = abs(current_data) .* voltage_data;
    ess_support = sqrt(power_data.^2 + reactive_power_data.^2);
    grid_support = 1 - dfig_support - ess_support;
    
    support_dist = [dfig_support ess_support grid_support];
end

function create_lstm_performance_plot()
    % Create LSTM performance analysis
    subplot(2,1,1);
    plot_prediction_accuracy();
    
    subplot(2,1,2);
    plot_error_distribution();
end

function plot_prediction_accuracy()
    % Plot LSTM prediction accuracy
    hold on;
    plot(t, power_data, 'Color', colors.power, 'LineWidth', 1.5);
    plot(t, lstm_prediction_data, '--', 'Color', colors.prediction, 'LineWidth', 1.5);
    hold off;
    title('LSTM Prediction Accuracy', 'FontWeight', 'bold');
    ylabel('Power (p.u.)');
    legend('Actual', 'Predicted');
    grid on;
end

function plot_error_distribution()
    % Plot error distribution
    prediction_error = power_data - lstm_prediction_data;
    histogram(prediction_error, 20, 'Normalization', 'probability', ...
             'FaceColor', colors.prediction, 'EdgeColor', 'none');
    title('Prediction Error Distribution', 'FontWeight', 'bold');
    xlabel('Error (p.u.)');
    ylabel('Probability');
    grid on;
end

function create_interactive_analysis()
    % Create interactive analysis panel
    subplot(2,2,1);
    create_interactive_timeline();
    
    subplot(2,2,2);
    create_interactive_scatter();
    
    subplot(2,2,3);
    create_interactive_histogram();
    
    subplot(2,2,4);
    create_interactive_correlation();
end

function create_interactive_timeline()
    % Create interactive timeline with selectable regions
    plot(t, voltage_data, 'Color', colors.voltage);
    title('Interactive Timeline', 'FontWeight', 'bold');
    ylabel('Voltage (p.u.)');
    grid on;
    
    % Add interactive region selection
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', @timeline_cursor);
end

function create_interactive_scatter()
    % Create interactive scatter plot
    scatter(voltage_data, current_data, 20, t, 'filled');
    title('V-I Relationship', 'FontWeight', 'bold');
    xlabel('Voltage (p.u.)');
    ylabel('Current (p.u.)');
    colorbar('Title', 'Time (s)');
    grid on;
end

function create_interactive_histogram()
    % Create interactive histogram
    histogram2(voltage_data, current_data, [20 20], 'DisplayStyle', 'tile');
    title('Response Distribution', 'FontWeight', 'bold');
    xlabel('Voltage (p.u.)');
    ylabel('Current (p.u.)');
    colorbar('Title', 'Count');
end

function create_interactive_correlation()
    % Create interactive correlation plot
    variables = [voltage_data current_data power_data reactive_power_data];
    labels = {'Voltage', 'Current', 'P', 'Q'};
    imagesc(corrcoef(variables));
    title('Parameter Correlation', 'FontWeight', 'bold');
    xticks(1:4);
    yticks(1:4);
    xticklabels(labels);
    yticklabels(labels);
    colorbar;
end

function txt = timeline_cursor(~, event_obj)
    % Custom data cursor update function
    pos = get(event_obj, 'Position');
    idx = find(t >= pos(1), 1);
    
    txt = sprintf('Time: %.3fs\nVoltage: %.2f p.u.\nCurrent: %.2f p.u.\nP: %.2f p.u.\nQ: %.2f p.u.', ...
        pos(1), voltage_data(idx), current_data(idx), power_data(idx), reactive_power_data(idx));
end 