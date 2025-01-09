%% Test Frequency Control
% Test script for frequency control functionality

clear;
clc;

%% Test Setup
% Load configuration
config;

% Initialize components
dfig = dfig_model(dfig_params);
ess = ess_model(ess_params);
grid = grid_model(grid_params);
drl_agent = drl_agent(drl_config);

% Initialize test parameters
test_duration = 10;  % seconds
Ts = 0.001;         % sampling time
t = 0:Ts:test_duration;
n_samples = length(t);

% Initialize data storage
frequency_data = zeros(n_samples, 1);
power_dfig_data = zeros(n_samples, 1);
power_ess_data = zeros(n_samples, 1);
inertia_response_data = zeros(n_samples, 1);
soc_data = zeros(n_samples, 1);
drl_action_data = zeros(n_samples, 2);

%% Test Cases

% Test Case 1: Step Frequency Drop
fprintf('\nTest Case 1: Step Frequency Drop Response\n');
run_frequency_step_test(-0.5);  % -0.5 Hz step

% Test Case 2: Frequency Oscillation
fprintf('\nTest Case 2: Frequency Oscillation Response\n');
run_frequency_oscillation_test(0.3, 1.0);  % 0.3 Hz amplitude, 1.0 Hz frequency

% Test Case 3: Wind Power Variation
fprintf('\nTest Case 3: Wind Power Variation Response\n');
run_wind_variation_test();

%% Test Functions
function run_frequency_step_test(step_size)
    % Apply frequency step
    fault_params = struct(...
        'type', 'frequency_deviation',...
        'deviation', step_size,...
        'duration', 0.5...
    );
    
    % Run simulation
    for i = 1:n_samples
        % Apply frequency step
        if t(i) >= 2.0 && t(i) < 2.5
            grid_state = grid.apply_fault(fault_params);
        else
            grid_state = grid.get_states();
        end
        
        % Run control loop
        run_control_loop(i, grid_state, 12);  % Constant wind speed
    end
    
    % Analyze results
    analyze_step_response(step_size);
end

function run_frequency_oscillation_test(amplitude, freq)
    % Run simulation with oscillating frequency
    for i = 1:n_samples
        % Generate oscillating frequency
        f_deviation = amplitude * sin(2*pi*freq*t(i));
        grid_state = struct(...
            'frequency', 50 + f_deviation,...
            'voltage', 1.0,...
            'phase', 0...
        );
        
        % Run control loop
        run_control_loop(i, grid_state, 12);  % Constant wind speed
    end
    
    % Analyze results
    analyze_oscillation_response(amplitude, freq);
end

function run_wind_variation_test()
    % Run simulation with varying wind speed
    for i = 1:n_samples
        % Generate varying wind speed
        wind_speed = 12 + 3*sin(2*pi*0.2*t(i)) + ...
                    1*sin(2*pi*0.5*t(i));
        
        % Set nominal frequency with small random variations
        grid_state = struct(...
            'frequency', 50 + 0.1*randn(),...
            'voltage', 1.0,...
            'phase', 0...
        );
        
        % Run control loop
        run_control_loop(i, grid_state, wind_speed);
    end
    
    % Analyze results
    analyze_wind_variation_response();
end

function run_control_loop(idx, grid_state, wind_speed)
    % Calculate frequency derivative
    if idx > 1
        df_dt = (grid_state.frequency - frequency_data(idx-1)) / Ts;
    else
        df_dt = 0;
    end
    
    % Get system state
    state = struct(...
        'grid_frequency', grid_state.frequency,...
        'df_dt', df_dt,...
        'wind_speed', wind_speed,...
        'soc', ess.get_states().soc,...
        'time', t(idx)...
    );
    
    % Get DRL action
    drl_state = prepare_drl_state(state);
    drl_action = drl_agent.get_action(drl_state);
    
    % Execute frequency control with DRL optimization
    [dfig_refs, ess_refs] = freq_control(state, ...
        struct('drl_action', drl_action), params);
    
    % Store data
    store_data(idx, state, dfig_refs, ess_refs, drl_action);
end

function drl_state = prepare_drl_state(state)
    % Prepare state for DRL agent
    drl_state = struct(...
        'frequency_error', state.grid_frequency - 50,...
        'roc_of', state.df_dt,...
        'wind_speed', state.wind_speed,...
        'soc', state.soc,...
        'power_available', calculate_available_power(state.wind_speed)...
    );
end

function store_data(idx, state, dfig_refs, ess_refs, drl_action)
    % Store simulation data
    frequency_data(idx) = state.grid_frequency;
    power_dfig_data(idx) = dfig_refs.P_ref;
    power_ess_data(idx) = ess_refs.P_ref;
    inertia_response_data(idx) = dfig_refs.P_ref - ...
        power_dfig_data(max(1,idx-1));
    soc_data(idx) = state.soc;
    drl_action_data(idx,:) = [drl_action.dfig_factor, drl_action.ess_factor];
end

function analyze_step_response(step_size)
    % Analyze step response results
    
    % Frequency metrics
    freq_nadir = min(frequency_data);
    fprintf('Frequency nadir: %.2f Hz\n', freq_nadir);
    assert(freq_nadir >= 49.5, 'Frequency nadir below limit');
    
    % Recovery time
    recovery_idx = find(frequency_data(n_samples/2:end) >= 49.8, 1);
    recovery_time = recovery_idx * Ts;
    fprintf('Recovery time: %.2f s\n', recovery_time);
    assert(recovery_time <= 3, 'Recovery time too long');
    
    % Inertial response
    max_inertia = max(abs(inertia_response_data));
    fprintf('Maximum inertial response: %.2f p.u.\n', max_inertia);
    
    % ESS contribution
    ess_energy = trapz(t, power_ess_data) * Ts;
    fprintf('Total ESS energy contribution: %.2f p.u.*s\n', ess_energy);
end

function analyze_oscillation_response(amplitude, freq)
    % Analyze oscillation response
    
    % Calculate damping ratio
    peaks = findpeaks(frequency_data);
    if length(peaks) >= 2
        damping_ratio = log(peaks(1)/peaks(2)) / ...
            (2*pi*sqrt(1/(1-(log(peaks(1)/peaks(2))/(2*pi))^2)));
        fprintf('Damping ratio: %.3f\n', damping_ratio);
    end
    
    % Power sharing analysis
    dfig_contribution = rms(power_dfig_data);
    ess_contribution = rms(power_ess_data);
    fprintf('DFIG RMS contribution: %.2f p.u.\n', dfig_contribution);
    fprintf('ESS RMS contribution: %.2f p.u.\n', ess_contribution);
end

function analyze_wind_variation_response()
    % Analyze response to wind variations
    
    % Frequency quality
    freq_std = std(frequency_data);
    fprintf('Frequency standard deviation: %.3f Hz\n', freq_std);
    
    % DRL performance
    avg_dfig_factor = mean(drl_action_data(:,1));
    avg_ess_factor = mean(drl_action_data(:,2));
    fprintf('Average DRL factors - DFIG: %.2f, ESS: %.2f\n', ...
        avg_dfig_factor, avg_ess_factor);
    
    % SOC management
    soc_variation = max(soc_data) - min(soc_data);
    fprintf('SOC variation: %.2f%%\n', soc_variation * 100);
end

%% Advanced Analysis and Visualization
% Create multiple figures for different analysis aspects
figure_main = figure('Position', [100, 100, 1200, 1400], 'Name', 'Frequency Control Analysis');
figure_comparison = figure('Position', [1300, 100, 800, 1200], 'Name', 'Response Comparison Analysis');
figure_interactive = figure('Position', [100, 100, 1000, 800], 'Name', 'Interactive Analysis');

% Enhanced color scheme with gradients
colors = struct(...
    'frequency', [0.2 0.5 0.9],...
    'dfig', [0.9 0.3 0.3],...
    'ess', [0.3 0.7 0.4],...
    'inertia', [0.6 0.4 0.7],...
    'soc', [0.4 0.3 0.8],...
    'drl', [0.8 0.4 0.2],...
    'event', [0.8 0.2 0.2],...
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
    'analysis', [0.1 0.1 0.85 0.2]... % Frequency analysis
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

% Enhanced frequency analysis
axes('Position', subplot_layout.analysis);
create_frequency_analysis();

%% Comparison Analysis Figure
figure(figure_comparison);

% Create comparison subplots
subplot(3,1,1);
create_response_comparison_plot();

subplot(3,1,2);
create_control_strategy_plot();

subplot(3,1,3);
create_drl_performance_plot();

%% Interactive Analysis Figure
figure(figure_interactive);

% Create interactive elements
create_interactive_analysis();

% Save all figures
save_analysis_figures();

% Helper functions for main analysis
function create_main_plots()
    % Enhanced main plots with gradient backgrounds
    create_frequency_plot();
    create_dfig_plot();
    create_ess_plot();
    create_inertia_plot();
    create_soc_plot();
    create_drl_plot();
end

function create_frequency_plot()
    subplot(6,1,1);
    plot_with_gradient(t, frequency_data, colors.frequency, 'Grid Frequency', 'Frequency (Hz)', ...
        [50, 49.8, 50.2], {'Nominal', 'Lower Limit', 'Upper Limit'});
    add_tooltips('frequency');
end

function create_dfig_plot()
    subplot(6,1,2);
    plot_with_gradient(t, power_dfig_data, colors.dfig, 'DFIG Power Output', 'Power (p.u.)', []);
    add_tooltips('dfig');
end

function create_ess_plot()
    subplot(6,1,3);
    plot_with_gradient(t, power_ess_data, colors.ess, 'ESS Power Output', 'Power (p.u.)', []);
    add_tooltips('ess');
end

function create_inertia_plot()
    subplot(6,1,4);
    plot_with_gradient(t, inertia_response_data, colors.inertia, 'Inertial Response', 'ΔP (p.u.)', []);
    add_tooltips('inertia');
end

function create_soc_plot()
    subplot(6,1,5);
    plot_with_gradient(t, soc_data, colors.soc, 'Battery State of Charge', 'SOC', ...
        [params.min_soc, params.max_soc], {'Min SOC', 'Max SOC'});
    add_tooltips('soc');
end

function create_drl_plot()
    subplot(6,1,6);
    plot_drl_actions();
    add_tooltips('drl');
end

% Enhanced plotting functions
function plot_with_gradient(t, data, color, title_str, ylabel_str, limits, labels)
    % Create gradient background
    hold on;
    fill_gradient_background();
    
    % Plot data with enhanced styling
    plot(t, data, 'Color', color, 'LineWidth', 1.5);
    
    % Add limits if provided
    if nargin >= 6
        for i = 1:length(limits)
            if i == 1
                yline(limits(i), '--k', labels{i}, 'Alpha', 0.3);
            else
                yline(limits(i), '--r', labels{i});
            end
        end
    end
    
    % Add styling
    title(title_str, 'FontWeight', 'bold');
    ylabel(ylabel_str);
    if nargin >= 6
        ylim([min(limits) - 0.1, max(limits) + 0.1]);
    end
    grid on;
    
    % Add interactive elements
    add_data_cursor();
    add_zoom_buttons();
    add_event_highlights();
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

function add_event_highlights()
    hold on;
    % Find frequency events
    event_regions = abs(frequency_data - 50) > 0.2;
    area(t, event_regions * ylim(2), 'FaceColor', colors.event, ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none');
    
    % Find recovery periods
    recovery_regions = [0; diff(abs(frequency_data - 50) < 0.1)];
    area(t, recovery_regions * ylim(2), 'FaceColor', colors.recovery, ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none');
    
    % Add event duration labels
    event_starts = find(diff(event_regions) == 1);
    event_ends = find(diff(event_regions) == -1);
    
    if ~isempty(event_starts)
        for i = 1:length(event_starts)
            if i <= length(event_ends)
                duration_s = t(event_ends(i)) - t(event_starts(i));
                midpoint = t(event_starts(i)) + duration_s/2;
                text(midpoint, ylim(2), sprintf('%.1f s', duration_s), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'Color', colors.event);
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
        case 'frequency'
            title(sprintf('Frequency Analysis\nClick for details'), 'ButtonDownFcn', @frequency_tooltip);
        case 'dfig'
            title(sprintf('DFIG Analysis\nClick for details'), 'ButtonDownFcn', @dfig_tooltip);
        case 'ess'
            title(sprintf('ESS Analysis\nClick for details'), 'ButtonDownFcn', @ess_tooltip);
        case 'inertia'
            title(sprintf('Inertia Analysis\nClick for details'), 'ButtonDownFcn', @inertia_tooltip);
        case 'soc'
            title(sprintf('SOC Analysis\nClick for details'), 'ButtonDownFcn', @soc_tooltip);
        case 'drl'
            title(sprintf('DRL Analysis\nClick for details'), 'ButtonDownFcn', @drl_tooltip);
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
function frequency_tooltip(~, ~)
    freq_stats = calculate_frequency_statistics();
    msgbox(sprintf('Frequency Analysis\n\nNadir: %.2f Hz\nRecovery: %.1f s\nIn Band: %.1f%%', ...
        freq_stats.nadir, freq_stats.recovery_time, freq_stats.in_band));
end

function dfig_tooltip(~, ~)
    dfig_stats = calculate_dfig_statistics();
    msgbox(sprintf('DFIG Analysis\n\nMax Power: %.2f p.u.\nRMS: %.2f p.u.\nEnergy: %.2f p.u.s', ...
        dfig_stats.max_power, dfig_stats.rms, dfig_stats.energy));
end

function ess_tooltip(~, ~)
    ess_stats = calculate_ess_statistics();
    msgbox(sprintf('ESS Analysis\n\nMax Power: %.2f p.u.\nRMS: %.2f p.u.\nEnergy: %.2f p.u.s', ...
        ess_stats.max_power, ess_stats.rms, ess_stats.energy));
end

function inertia_tooltip(~, ~)
    inertia_stats = calculate_inertia_statistics();
    msgbox(sprintf('Inertia Analysis\n\nMax Response: %.2f p.u.\nAvg Response: %.2f p.u.\nEnergy: %.2f p.u.s', ...
        inertia_stats.max_response, inertia_stats.avg_response, inertia_stats.energy));
end

function soc_tooltip(~, ~)
    soc_stats = calculate_soc_statistics();
    msgbox(sprintf('SOC Analysis\n\nMin: %.2f%%\nMax: %.2f%%\nVariation: %.2f%%', ...
        soc_stats.min*100, soc_stats.max*100, soc_stats.variation*100));
end

function drl_tooltip(~, ~)
    drl_stats = calculate_drl_statistics();
    msgbox(sprintf('DRL Analysis\n\nAvg DFIG: %.2f\nAvg ESS: %.2f\nAction Rate: %.2f Hz', ...
        drl_stats.avg_dfig, drl_stats.avg_ess, drl_stats.action_rate));
end

% Save functions
function save_analysis_figures()
    % Save main analysis
    figure(figure_main);
    saveas(gcf, 'test_results/freq_control_analysis_main.png');
    
    % Save comparison analysis
    figure(figure_comparison);
    saveas(gcf, 'test_results/freq_control_comparison.png');
    
    % Save interactive analysis
    figure(figure_interactive);
    saveas(gcf, 'test_results/freq_control_interactive.png');
    
    fprintf('Enhanced analysis figures saved to test_results/\n');
end

%% Additional Analysis Features
function create_response_characteristics()
    % Calculate response characteristics
    freq_deviations = frequency_data - 50;
    power_responses = power_dfig_data + power_ess_data;
    inertial_responses = inertia_response_data;
    
    % Create scatter plot with size based on inertial response
    scatter(freq_deviations, power_responses, 50 + abs(inertial_responses)*100, ...
        colors.frequency, 'filled', 'MarkerFaceAlpha', 0.6);
    
    % Add trend line
    p = polyfit(freq_deviations, power_responses, 1);
    hold on;
    plot(freq_deviations, polyval(p, freq_deviations), '--', 'Color', colors.power);
    
    % Add droop reference line
    droop_slope = -1/params.droop_gain;
    xline(0, '--k', 'Nominal');
    plot(freq_deviations, droop_slope*freq_deviations, ':', 'Color', colors.dfig);
    
    title('Frequency Response Characteristics', 'FontWeight', 'bold');
    xlabel('Frequency Deviation (Hz)');
    ylabel('Power Response (p.u.)');
    grid on;
    
    % Add colorbar for inertial response
    colormap(gca, autumn);
    cb = colorbar;
    cb.Label.String = 'Inertial Response (p.u.)';
end

function create_performance_metrics()
    % Calculate comprehensive metrics
    metrics = calculate_comprehensive_metrics();
    
    % Create performance radar chart
    theta = [0 2*pi/6 4*pi/6 6*pi/6 8*pi/6 10*pi/6];
    rho = [metrics.frequency_regulation, metrics.inertial_response, ...
           metrics.power_sharing, metrics.soc_management, ...
           metrics.drl_optimization, metrics.stability];
    
    polarplot(theta, rho, '-o', 'LineWidth', 2, 'Color', colors.power);
    title('Performance Metrics', 'FontWeight', 'bold');
    
    % Add metric labels
    labels = {'Frequency Regulation', 'Inertial Response', 'Power Sharing', ...
              'SOC Management', 'DRL Optimization', 'Stability'};
    thetaticks(0:60:300);
    thetaticklabels(labels);
    rticks(0:0.2:1);
    grid on;
end

function metrics = calculate_comprehensive_metrics()
    % Calculate normalized performance metrics
    metrics = struct();
    
    % Frequency regulation metric
    metrics.frequency_regulation = 1 - mean(abs(frequency_data - 50)) / 0.5;
    
    % Inertial response effectiveness
    metrics.inertial_response = mean(abs(inertia_response_data)) / params.rated_power;
    
    % Power sharing coordination
    metrics.power_sharing = 1 - std(power_dfig_data ./ (power_dfig_data + power_ess_data));
    
    % SOC management
    metrics.soc_management = 1 - (max(soc_data) - min(soc_data));
    
    % DRL optimization performance
    metrics.drl_optimization = mean(drl_action_data(:,1).^2 + drl_action_data(:,2).^2);
    
    % System stability
    freq_std = std(frequency_data);
    metrics.stability = 1 - freq_std / 0.5;
end

function create_frequency_analysis()
    % Create frequency analysis timeline
    hold on;
    
    % Plot frequency profile with gradient coloring
    freq_deviation = abs(frequency_data - 50);
    patch([t fliplr(t)], [freq_deviation' zeros(size(freq_deviation'))], ...
          'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    
    % Add recovery markers
    recovery_points = find(diff(abs(frequency_data - 50) < 0.1) == 1);
    plot(t(recovery_points), zeros(size(recovery_points)), '^', ...
         'Color', colors.recovery, 'MarkerFaceColor', colors.recovery);
    
    % Add frequency limit violation markers
    violation_points = find(abs(frequency_data - 50) > 0.5);
    if ~isempty(violation_points)
        plot(t(violation_points), ones(size(violation_points)), 'v', ...
             'Color', colors.fault, 'MarkerFaceColor', colors.fault);
    end
    
    % Add DRL action intensity
    drl_intensity = sqrt(sum(drl_action_data.^2, 2));
    patch([t fliplr(t)], [drl_intensity' zeros(size(drl_intensity'))], ...
          'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    
    hold off;
    title('Frequency Analysis Timeline', 'FontWeight', 'bold');
    ylabel('Deviation / Action Intensity');
    ylim([-0.1 1.1]);
    grid on;
    
    % Add legend
    legend('Frequency Deviation', 'Recovery Point', 'Limit Violation', 'DRL Action');
end

function create_response_comparison_plot()
    % Compare different response components
    subplot(3,1,1);
    plot_frequency_comparison();
    
    subplot(3,1,2);
    plot_power_comparison();
    
    subplot(3,1,3);
    plot_drl_comparison();
end

function plot_frequency_comparison()
    % Plot frequency profiles
    hold on;
    plot(t, frequency_data, 'Color', colors.frequency, 'LineWidth', 1.5);
    yline(50, '--k', 'Nominal');
    yline(49.5, '--r', 'Lower Limit');
    yline(50.5, '--r', 'Upper Limit');
    hold off;
    title('Frequency Response', 'FontWeight', 'bold');
    ylabel('Frequency (Hz)');
    grid on;
end

function plot_power_comparison()
    % Plot power responses
    hold on;
    plot(t, power_dfig_data, 'Color', colors.dfig, 'LineWidth', 1.5);
    plot(t, power_ess_data, '--', 'Color', colors.ess, 'LineWidth', 1.5);
    plot(t, inertia_response_data, ':', 'Color', colors.inertia, 'LineWidth', 1.5);
    hold off;
    title('Power Response', 'FontWeight', 'bold');
    ylabel('Power (p.u.)');
    legend('DFIG', 'ESS', 'Inertial');
    grid on;
end

function plot_drl_comparison()
    % Plot DRL actions
    hold on;
    plot(t, drl_action_data(:,1), 'Color', colors.dfig, 'LineWidth', 1.5);
    plot(t, drl_action_data(:,2), '--', 'Color', colors.ess, 'LineWidth', 1.5);
    hold off;
    title('DRL Actions', 'FontWeight', 'bold');
    ylabel('Action Value');
    legend('DFIG Action', 'ESS Action');
    grid on;
end

function create_control_strategy_plot()
    % Create visualization of control strategy
    subplot(2,1,1);
    plot_control_distribution();
    
    subplot(2,1,2);
    plot_soc_management();
end

function plot_control_distribution()
    % Visualize control distribution
    distribution = calculate_control_distribution();
    area(t, distribution, 'FaceAlpha', 0.5);
    title('Control Distribution', 'FontWeight', 'bold');
    ylabel('Contribution');
    legend('Inertial', 'Primary', 'DRL');
    grid on;
end

function distribution = calculate_control_distribution()
    % Calculate control distribution
    inertial = abs(inertia_response_data) / params.rated_power;
    primary = abs(power_dfig_data) / params.rated_power;
    drl = sqrt(sum(drl_action_data.^2, 2));
    
    distribution = [inertial primary drl];
end

function plot_soc_management()
    % Visualize SOC management
    hold on;
    plot(t, soc_data, 'Color', colors.soc, 'LineWidth', 1.5);
    yline(params.min_soc, '--r', 'Min SOC');
    yline(params.max_soc, '--r', 'Max SOC');
    hold off;
    title('SOC Management', 'FontWeight', 'bold');
    ylabel('SOC');
    grid on;
end

function create_drl_performance_plot()
    % Create DRL performance analysis
    subplot(2,1,1);
    plot_action_space();
    
    subplot(2,1,2);
    plot_reward_distribution();
end

function plot_action_space()
    % Plot DRL action space
    scatter(drl_action_data(:,1), drl_action_data(:,2), 20, t, 'filled');
    title('DRL Action Space', 'FontWeight', 'bold');
    xlabel('DFIG Action');
    ylabel('ESS Action');
    colorbar('Title', 'Time (s)');
    grid on;
end

function plot_reward_distribution()
    % Plot reward distribution
    rewards = calculate_rewards();
    histogram(rewards, 20, 'Normalization', 'probability', ...
             'FaceColor', colors.drl, 'EdgeColor', 'none');
    title('Reward Distribution', 'FontWeight', 'bold');
    xlabel('Reward');
    ylabel('Probability');
    grid on;
end

function rewards = calculate_rewards()
    % Calculate rewards based on performance
    freq_penalty = -abs(frequency_data - 50);
    power_reward = -(power_dfig_data.^2 + power_ess_data.^2);
    soc_penalty = -abs(soc_data - 0.5);
    
    rewards = freq_penalty + power_reward + soc_penalty;
end

function create_interactive_analysis()
    % Create interactive analysis panel
    subplot(2,2,1);
    create_interactive_timeline();
    
    subplot(2,2,2);
    create_interactive_phase();
    
    subplot(2,2,3);
    create_interactive_distribution();
    
    subplot(2,2,4);
    create_interactive_correlation();
end

function create_interactive_timeline()
    % Create interactive timeline
    plot(t, frequency_data, 'Color', colors.frequency);
    title('Interactive Timeline', 'FontWeight', 'bold');
    ylabel('Frequency (Hz)');
    grid on;
    
    % Add interactive region selection
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', @timeline_cursor);
end

function create_interactive_phase()
    % Create interactive phase portrait
    scatter(frequency_data - 50, inertia_response_data, 20, t, 'filled');
    title('Phase Portrait', 'FontWeight', 'bold');
    xlabel('Frequency Deviation (Hz)');
    ylabel('Inertial Response (p.u.)');
    colorbar('Title', 'Time (s)');
    grid on;
end

function create_interactive_distribution()
    % Create interactive distribution plot
    histogram2(frequency_data, power_dfig_data + power_ess_data, [20 20], ...
              'DisplayStyle', 'tile');
    title('Response Distribution', 'FontWeight', 'bold');
    xlabel('Frequency (Hz)');
    ylabel('Total Power (p.u.)');
    colorbar('Title', 'Count');
end

function create_interactive_correlation()
    % Create interactive correlation plot
    variables = [frequency_data power_dfig_data power_ess_data inertia_response_data];
    labels = {'Freq', 'DFIG', 'ESS', 'Inertia'};
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
    
    txt = sprintf('Time: %.3fs\nFrequency: %.2f Hz\nDFIG: %.2f p.u.\nESS: %.2f p.u.\nInertia: %.2f p.u.', ...
        pos(1), frequency_data(idx), power_dfig_data(idx), power_ess_data(idx), inertia_response_data(idx));
end 