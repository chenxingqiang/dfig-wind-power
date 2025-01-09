%% Test Mode Switching
% Test script for mode switching functionality

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
test_duration = 5;  % seconds
Ts = 0.001;        % sampling time
t = 0:Ts:test_duration;
n_samples = length(t);

% Initialize data storage
voltage_data = zeros(n_samples, 1);
frequency_data = zeros(n_samples, 1);
mode_data = zeros(n_samples, 1);
soc_data = zeros(n_samples, 1);
power_data = zeros(n_samples, 1);
transition_metrics = struct('time', [], 'from', [], 'to', []);

%% Test Cases

% Test Case 1: Basic Mode Transitions
fprintf('\nTest Case 1: Basic Mode Transitions\n');
run_basic_transition_test();

% Test Case 2: Rapid Mode Changes
fprintf('\nTest Case 2: Rapid Mode Changes\n');
run_rapid_transition_test();

% Test Case 3: SOC-Driven Transitions
fprintf('\nTest Case 3: SOC-Driven Transitions\n');
run_soc_transition_test();

%% Test Functions
function run_basic_transition_test()
    % Define basic transition sequence
    scenarios = [...
        % time, voltage, frequency, soc
        0.0, 1.00, 50.0, 0.60;  % Normal operation
        1.0, 0.60, 50.0, 0.60;  % Voltage fault -> Grid forming
        2.0, 1.00, 50.0, 0.60;  % Recovery -> Grid following
        3.0, 0.70, 50.0, 0.15;  % Low SOC + Fault -> Emergency
        4.0, 1.00, 50.0, 0.60   % Recovery
    ];
    
    % Run simulation
    run_scenario_simulation(scenarios);
    
    % Analyze results
    analyze_transition_sequence('Basic');
end

function run_rapid_transition_test()
    % Define rapid transition sequence
    scenarios = [];
    t_current = 0;
    
    % Generate oscillating voltage condition
    while t_current < test_duration
        scenarios = [scenarios; ...
            t_current, 0.85 + 0.1*sin(2*pi*2*t_current), 50.0, 0.6];
        t_current = t_current + 0.1;
    end
    
    % Run simulation
    run_scenario_simulation(scenarios);
    
    % Analyze results
    analyze_transition_sequence('Rapid');
end

function run_soc_transition_test()
    % Define SOC-driven transition sequence
    scenarios = [];
    t_current = 0;
    
    % Generate declining SOC scenario
    base_soc = 0.8;
    discharge_rate = 0.1;  % SOC/s
    
    while t_current < test_duration
        soc = max(0.1, base_soc - discharge_rate * t_current);
        scenarios = [scenarios; ...
            t_current, 0.7, 50.0, soc];
        t_current = t_current + 0.1;
    end
    
    % Run simulation
    run_scenario_simulation(scenarios);
    
    % Analyze results
    analyze_transition_sequence('SOC');
end

function run_scenario_simulation(scenarios)
    % Clear transition metrics
    transition_metrics = struct('time', [], 'from', [], 'to', []);
    
    % Run simulation
    for i = 1:n_samples
        % Interpolate scenario values
        current_scenario = interpolate_scenario(scenarios, t(i));
        
        % Create grid state
        grid_state = struct(...
            'voltage', current_scenario.voltage,...
            'frequency', current_scenario.frequency...
        );
        
        % Get LSTM prediction
        [prediction, confidence] = lstm_predictor.predict(...
            create_lstm_input(grid_state, current_scenario.soc));
        
        % Get system state
        state = struct(...
            'grid_voltage', grid_state.voltage,...
            'grid_frequency', grid_state.frequency,...
            'soc', current_scenario.soc,...
            'time', t(i),...
            'previous_mode', mode_to_number(mode_data(max(1,i-1))),...
            'power_prediction', prediction,...
            'prediction_confidence', confidence...
        );
        
        % Execute mode switching
        [mode, control_params] = mode_switch(state);
        
        % Store data
        store_data(i, state, mode, control_params);
        
        % Track transitions
        if i > 1 && mode_data(i) ~= mode_data(i-1)
            transition_metrics.time(end+1) = t(i);
            transition_metrics.from(end+1) = mode_data(i-1);
            transition_metrics.to(end+1) = mode_data(i);
        end
    end
end

function scenario = interpolate_scenario(scenarios, current_time)
    % Find surrounding scenario points
    idx = find(scenarios(:,1) <= current_time, 1, 'last');
    if isempty(idx)
        idx = 1;
    end
    if idx == size(scenarios, 1)
        next_idx = idx;
    else
        next_idx = idx + 1;
    end
    
    % Interpolate values
    if idx == next_idx
        alpha = 0;
    else
        alpha = (current_time - scenarios(idx,1)) / ...
                (scenarios(next_idx,1) - scenarios(idx,1));
    end
    
    % Create interpolated scenario
    scenario = struct(...
        'voltage', interp1([0,1], [scenarios(idx,2), scenarios(next_idx,2)], alpha),...
        'frequency', interp1([0,1], [scenarios(idx,3), scenarios(next_idx,3)], alpha),...
        'soc', interp1([0,1], [scenarios(idx,4), scenarios(next_idx,4)], alpha)...
    );
end

function lstm_input = create_lstm_input(grid_state, soc)
    % Create input for LSTM predictor
    lstm_input = struct(...
        'grid_voltage', grid_state.voltage,...
        'grid_frequency', grid_state.frequency,...
        'power_output', dfig.get_states().power_output,...
        'wind_speed', 12,...  % Example wind speed
        'soc', soc...
    );
end

function store_data(idx, state, mode, params)
    % Store simulation data
    voltage_data(idx) = state.grid_voltage;
    frequency_data(idx) = state.grid_frequency;
    mode_data(idx) = mode_to_number(mode);
    soc_data(idx) = state.soc;
    power_data(idx) = state.power_prediction;
end

function analyze_transition_sequence(test_type)
    % Analyze mode transition sequence
    
    % Calculate transition metrics
    n_transitions = length(transition_metrics.time);
    avg_transition_time = mean(diff(transition_metrics.time));
    mode_durations = histcounts(mode_data, 1:4);
    
    % Print analysis
    fprintf('\n%s Transition Analysis:\n', test_type);
    fprintf('Number of transitions: %d\n', n_transitions);
    fprintf('Average time between transitions: %.3f s\n', avg_transition_time);
    fprintf('Mode durations (GF/GM/EM): %.2f/%.2f/%.2f s\n', ...
        mode_durations(1)*Ts, mode_durations(2)*Ts, mode_durations(3)*Ts);
    
    % Analyze transition stability
    if n_transitions > 0
        transition_matrix = zeros(3,3);
        for i = 1:n_transitions
            from_idx = transition_metrics.from(i);
            to_idx = transition_metrics.to(i);
            transition_matrix(from_idx,to_idx) = ...
                transition_matrix(from_idx,to_idx) + 1;
        end
        
        fprintf('\nTransition Matrix:\n');
        disp(transition_matrix);
    end
    
    % Check transition requirements
    check_transition_requirements(test_type);
end

function check_transition_requirements(test_type)
    % Check specific requirements based on test type
    switch test_type
        case 'Basic'
            % Check basic transition sequence
            assert(all(mode_data(1:1000) == 1), 'Incorrect initial mode');
            assert(any(mode_data(1000:1500) == 2), ...
                'Failed to enter grid-forming mode');
            assert(any(mode_data(3000:end) == 3), ...
                'Failed to enter emergency mode');
            
        case 'Rapid'
            % Check stability under rapid changes
            transitions = diff(mode_data);
            rapid_changes = sum(abs(transitions)) / test_duration;
            fprintf('Transition rate: %.2f Hz\n', rapid_changes);
            assert(rapid_changes < 10, 'Excessive mode switching');
            
        case 'SOC'
            % Check SOC-driven transitions
            low_soc_modes = mode_data(soc_data < params.min_soc);
            assert(all(low_soc_modes == 3), ...
                'Failed to maintain emergency mode at low SOC');
    end
end

%% Additional Analysis Features
function create_phase_portrait()
    % Calculate state derivatives
    voltage_derivative = [0; diff(voltage_data)] / Ts;
    frequency_derivative = [0; diff(frequency_data)] / Ts;
    
    % Create phase portrait with mode coloring
    scatter(voltage_data, voltage_derivative, 30, mode_data, 'filled', 'MarkerFaceAlpha', 0.6);
    
    title('System Phase Portrait', 'FontWeight', 'bold');
    xlabel('Voltage (p.u.)');
    ylabel('dV/dt (p.u./s)');
    grid on;
    
    % Add mode colorbar
    colormap(gca, jet);
    cb = colorbar;
    cb.Label.String = 'Operating Mode';
    cb.Ticks = [1 2 3];
    cb.TickLabels = {'GF', 'GM', 'EM'};
end

function create_statistics_panel()
    % Calculate comprehensive statistics
    stats = calculate_mode_statistics();
    
    % Create statistics visualization
    subplot(2,1,1);
    create_mode_duration_chart(stats);
    
    subplot(2,1,2);
    create_transition_matrix_plot(stats);
end

function stats = calculate_mode_statistics()
    % Calculate mode statistics
    stats = struct();
    
    % Mode durations
    stats.durations = histcounts(mode_data, 1:4) * Ts;
    
    % Transition counts
    stats.transitions = zeros(3,3);
    for i = 2:length(mode_data)
        if mode_data(i) ~= mode_data(i-1)
            stats.transitions(mode_data(i-1), mode_data(i)) = ...
                stats.transitions(mode_data(i-1), mode_data(i)) + 1;
        end
    end
    
    % Stability metrics
    stats.avg_duration = mean(diff(transition_metrics.time));
    stats.mode_changes = length(transition_metrics.time);
    stats.stability = 1 - stats.mode_changes / (length(t) * Ts);
end

function create_mode_duration_chart(stats)
    % Create bar chart of mode durations
    bar(stats.durations, 'FaceColor', colors.mode);
    title('Mode Durations', 'FontWeight', 'bold');
    xlabel('Mode');
    ylabel('Duration (s)');
    xticklabels({'GF', 'GM', 'EM'});
    grid on;
end

function create_transition_matrix_plot(stats)
    % Create transition matrix visualization
    imagesc(stats.transitions);
    title('Mode Transitions', 'FontWeight', 'bold');
    xlabel('To Mode');
    ylabel('From Mode');
    xticks(1:3);
    yticks(1:3);
    xticklabels({'GF', 'GM', 'EM'});
    yticklabels({'GF', 'GM', 'EM'});
    colorbar;
    axis square;
end

function create_transition_timeline()
    % Create enhanced transition timeline
    hold on;
    
    % Plot mode timeline with gradient coloring
    mode_changes = [0; diff(mode_data)];
    patch([t fliplr(t)], [mode_data' ones(size(mode_data'))], ...
          'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    
    % Add transition markers
    transition_points = find(mode_changes ~= 0);
    plot(t(transition_points), mode_data(transition_points), 'o', ...
         'Color', colors.event, 'MarkerFaceColor', colors.event);
    
    % Add SOC-driven transition markers
    soc_transitions = find(diff(soc_data < params.min_soc) == 1);
    if ~isempty(soc_transitions)
        plot(t(soc_transitions), mode_data(soc_transitions), 's', ...
             'Color', colors.soc, 'MarkerFaceColor', colors.soc);
    end
    
    hold off;
    title('Mode Transition Timeline', 'FontWeight', 'bold');
    ylabel('Mode');
    ylim([0.5 3.5]);
    yticks(1:3);
    yticklabels({'GF', 'GM', 'EM'});
    grid on;
    
    % Add legend
    legend('Mode', 'Transition', 'SOC Trigger');
end

function create_mode_comparison_plot()
    % Create mode comparison visualization
    subplot(3,1,1);
    plot_voltage_mode_comparison();
    
    subplot(3,1,2);
    plot_frequency_mode_comparison();
    
    subplot(3,1,3);
    plot_soc_mode_comparison();
end

function plot_voltage_mode_comparison()
    % Plot voltage profiles with mode coloring
    scatter(t, voltage_data, 20, mode_data, 'filled');
    title('Voltage Profile by Mode', 'FontWeight', 'bold');
    ylabel('Voltage (p.u.)');
    colormap(gca, jet);
    colorbar('Ticks', [1 2 3], 'TickLabels', {'GF', 'GM', 'EM'});
    grid on;
end

function plot_frequency_mode_comparison()
    % Plot frequency profiles with mode coloring
    scatter(t, frequency_data, 20, mode_data, 'filled');
    title('Frequency Profile by Mode', 'FontWeight', 'bold');
    ylabel('Frequency (Hz)');
    colormap(gca, jet);
    colorbar('Ticks', [1 2 3], 'TickLabels', {'GF', 'GM', 'EM'});
    grid on;
end

function plot_soc_mode_comparison()
    % Plot SOC profiles with mode coloring
    scatter(t, soc_data, 20, mode_data, 'filled');
    title('SOC Profile by Mode', 'FontWeight', 'bold');
    ylabel('SOC');
    colormap(gca, jet);
    colorbar('Ticks', [1 2 3], 'TickLabels', {'GF', 'GM', 'EM'});
    grid on;
end

function create_transition_analysis_plot()
    % Create transition analysis visualization
    subplot(2,1,1);
    plot_transition_timing();
    
    subplot(2,1,2);
    plot_transition_triggers();
end

function plot_transition_timing()
    % Plot transition timing analysis
    if ~isempty(transition_metrics.time)
        transition_intervals = diff(transition_metrics.time);
        histogram(transition_intervals, 'Normalization', 'probability', ...
                 'FaceColor', colors.mode, 'EdgeColor', 'none');
        title('Transition Timing Distribution', 'FontWeight', 'bold');
        xlabel('Interval (s)');
        ylabel('Probability');
        grid on;
    end
end

function plot_transition_triggers()
    % Plot transition trigger analysis
    if ~isempty(transition_metrics.time)
        triggers = categorize_triggers();
        bar(triggers, 'FaceColor', colors.event);
        title('Transition Triggers', 'FontWeight', 'bold');
        xlabel('Trigger Type');
        ylabel('Count');
        xticklabels({'Voltage', 'Frequency', 'SOC', 'Combined'});
        grid on;
    end
end

function triggers = categorize_triggers()
    % Categorize transition triggers
    n_transitions = length(transition_metrics.time);
    triggers = zeros(1,4);  % [Voltage, Frequency, SOC, Combined]
    
    for i = 1:n_transitions
        idx = find(t >= transition_metrics.time(i), 1);
        if idx > 1
            % Check trigger conditions
            voltage_trigger = abs(voltage_data(idx) - voltage_data(idx-1)) > 0.1;
            frequency_trigger = abs(frequency_data(idx) - frequency_data(idx-1)) > 0.2;
            soc_trigger = soc_data(idx) < params.min_soc;
            
            if voltage_trigger && ~frequency_trigger && ~soc_trigger
                triggers(1) = triggers(1) + 1;
            elseif ~voltage_trigger && frequency_trigger && ~soc_trigger
                triggers(2) = triggers(2) + 1;
            elseif ~voltage_trigger && ~frequency_trigger && soc_trigger
                triggers(3) = triggers(3) + 1;
            else
                triggers(4) = triggers(4) + 1;
            end
        end
    end
end

function create_stability_analysis_plot()
    % Create stability analysis visualization
    subplot(2,1,1);
    plot_mode_stability();
    
    subplot(2,1,2);
    plot_transition_quality();
end

function plot_mode_stability()
    % Plot mode stability analysis
    mode_durations = calculate_mode_durations();
    boxplot(mode_durations, 'Labels', {'GF', 'GM', 'EM'});
    title('Mode Stability Analysis', 'FontWeight', 'bold');
    ylabel('Duration (s)');
    grid on;
end

function mode_durations = calculate_mode_durations()
    % Calculate durations for each mode
    mode_durations = cell(1,3);
    current_mode = mode_data(1);
    current_start = 1;
    
    for i = 2:length(mode_data)
        if mode_data(i) ~= current_mode
            duration = (i - current_start) * Ts;
            mode_durations{current_mode} = [mode_durations{current_mode} duration];
            current_mode = mode_data(i);
            current_start = i;
        end
    end
    
    % Add final duration
    duration = (length(mode_data) - current_start + 1) * Ts;
    mode_durations{current_mode} = [mode_durations{current_mode} duration];
end

function plot_transition_quality()
    % Plot transition quality metrics
    if ~isempty(transition_metrics.time)
        transition_qualities = calculate_transition_qualities();
        scatter(transition_metrics.time, transition_qualities, 50, ...
                transition_metrics.to, 'filled');
        title('Transition Quality', 'FontWeight', 'bold');
        xlabel('Time (s)');
        ylabel('Quality Score');
        colormap(gca, jet);
        colorbar('Ticks', [1 2 3], 'TickLabels', {'GF', 'GM', 'EM'});
        grid on;
    end
end

function qualities = calculate_transition_qualities()
    % Calculate transition quality scores
    n_transitions = length(transition_metrics.time);
    qualities = zeros(n_transitions, 1);
    
    for i = 1:n_transitions
        idx = find(t >= transition_metrics.time(i), 1);
        if idx > 1 && idx < length(t)-10
            % Calculate quality based on stability after transition
            voltage_stability = 1 - std(voltage_data(idx:idx+10));
            frequency_stability = 1 - std(frequency_data(idx:idx+10));
            soc_stability = 1 - abs(soc_data(idx+10) - soc_data(idx));
            
            qualities(i) = mean([voltage_stability frequency_stability soc_stability]);
        end
    end
end

function create_interactive_panel()
    % Create interactive mode analysis panel
    subplot(2,2,1);
    create_interactive_mode_timeline();
    
    subplot(2,2,2);
    create_interactive_state_space();
    
    subplot(2,2,3);
    create_interactive_transition_analysis();
    
    subplot(2,2,4);
    create_interactive_stability_metrics();
end

function create_interactive_mode_timeline()
    % Create interactive mode timeline
    stairs(t, mode_data, 'Color', colors.mode);
    title('Mode Timeline', 'FontWeight', 'bold');
    ylabel('Mode');
    ylim([0.5 3.5]);
    yticks(1:3);
    yticklabels({'GF', 'GM', 'EM'});
    grid on;
    
    % Add interactive elements
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', @mode_timeline_cursor);
end

function create_interactive_state_space()
    % Create interactive state space plot
    scatter(voltage_data, frequency_data, 20, mode_data, 'filled');
    title('State Space', 'FontWeight', 'bold');
    xlabel('Voltage (p.u.)');
    ylabel('Frequency (Hz)');
    colormap(gca, jet);
    colorbar('Ticks', [1 2 3], 'TickLabels', {'GF', 'GM', 'EM'});
    grid on;
end

function create_interactive_transition_analysis()
    % Create interactive transition analysis
    if ~isempty(transition_metrics.time)
        scatter(transition_metrics.time, transition_metrics.from, 50, ...
                transition_metrics.to, 'filled');
        title('Transition Analysis', 'FontWeight', 'bold');
        xlabel('Time (s)');
        ylabel('From Mode');
        ylim([0.5 3.5]);
        yticks(1:3);
        yticklabels({'GF', 'GM', 'EM'});
        colormap(gca, jet);
        colorbar('Ticks', [1 2 3], 'TickLabels', {'GF', 'GM', 'EM'});
        grid on;
    end
end

function create_interactive_stability_metrics()
    % Create interactive stability metrics
    stability_metrics = calculate_stability_metrics();
    bar(stability_metrics, 'FaceColor', colors.mode);
    title('Stability Metrics', 'FontWeight', 'bold');
    xlabel('Metric');
    ylabel('Score');
    xticklabels({'Duration', 'Transitions', 'Recovery'});
    grid on;
end

function metrics = calculate_stability_metrics()
    % Calculate stability metrics
    metrics = zeros(1,3);
    
    % Average mode duration
    mode_durations = diff([0; find(diff(mode_data) ~= 0); length(mode_data)]) * Ts;
    metrics(1) = mean(mode_durations) / test_duration;
    
    % Transition frequency
    metrics(2) = 1 - length(transition_metrics.time) / (test_duration / 0.1);
    
    % Recovery performance
    if ~isempty(transition_metrics.time)
        recovery_times = zeros(size(transition_metrics.time));
        for i = 1:length(transition_metrics.time)
            idx = find(t >= transition_metrics.time(i), 1);
            if idx < length(t)-100
                recovery_times(i) = find(abs(diff(mode_data(idx:idx+100))) > 0, 1) * Ts;
            end
        end
        metrics(3) = 1 - mean(recovery_times) / 0.1;
    else
        metrics(3) = 1;
    end
end

function txt = mode_timeline_cursor(~, event_obj)
    % Custom data cursor update function
    pos = get(event_obj, 'Position');
    idx = find(t >= pos(1), 1);
    
    txt = sprintf('Time: %.3fs\nMode: %s\nVoltage: %.2f p.u.\nFrequency: %.2f Hz\nSOC: %.2f', ...
        pos(1), mode_to_string(mode_data(idx)), voltage_data(idx), ...
        frequency_data(idx), soc_data(idx));
end

%% Utility Functions
function mode_num = mode_to_number(mode)
    % Convert mode to number
    if isnumeric(mode)
        mode_num = mode;
        return;
    end
    
    switch mode
        case 'GRID_FOLLOWING'
            mode_num = 1;
        case 'GRID_FORMING'
            mode_num = 2;
        case 'EMERGENCY'
            mode_num = 3;
        otherwise
            mode_num = 0;
    end
end

function test_mode_switch()
    % Test setup
    init_system;
    
    % Test parameters
    test_duration = 10; % seconds
    dt = 0.001; % time step
    t = 0:dt:test_duration;
    
    % Run test cases
    [voltage, frequency, mode, soc] = run_mode_transition_test(t);
    
    % Visualize results
    visualize_mode_transitions(t, voltage, frequency, mode, soc);
end

function [voltage, frequency, mode, soc] = run_mode_transition_test(t)
    % Simulate system response
    voltage = ones(size(t));
    frequency = 50 * ones(size(t));
    mode = zeros(size(t));
    soc = 0.8 * ones(size(t));
    
    % Add test events
    voltage(t >= 2 & t < 3) = 0.7; % Voltage dip
    frequency(t >= 4 & t < 5) = 49.5; % Frequency drop
    soc(t >= 6) = 0.2; % Low SOC condition
    
    % Determine modes
    mode(t < 2) = 1; % GRID_FOLLOWING
    mode(t >= 2 & t < 3) = 2; % GRID_FORMING
    mode(t >= 3 & t < 6) = 1; % GRID_FOLLOWING
    mode(t >= 6) = 3; % EMERGENCY
end

function visualize_mode_transitions(t, voltage, frequency, mode, soc)
    % Create figure with subplots
    fig = figure('Position', [100 100 1200 800]);
    
    % Subplot 1: Voltage
    subplot(4,1,1);
    plot(t, voltage, 'LineWidth', 2);
    hold on;
    yline(0.9, '--r', 'V_{min}');
    grid on;
    ylabel('Voltage (p.u.)');
    title('Grid Voltage');
    
    % Subplot 2: Frequency
    subplot(4,1,2);
    plot(t, frequency, 'LineWidth', 2);
    hold on;
    yline(49.8, '--r', 'f_{min}');
    grid on;
    ylabel('Frequency (Hz)');
    title('Grid Frequency');
    
    % Subplot 3: Mode
    subplot(4,1,3);
    plot(t, mode, 'LineWidth', 2);
    hold on;
    yticks([1 2 3]);
    yticklabels({'Grid Following', 'Grid Forming', 'Emergency'});
    grid on;
    ylabel('Mode');
    title('Operating Mode');
    
    % Subplot 4: SOC
    subplot(4,1,4);
    plot(t, soc, 'LineWidth', 2);
    hold on;
    yline(0.3, '--r', 'SOC_{min}');
    grid on;
    ylabel('SOC');
    xlabel('Time (s)');
    title('State of Charge');
    
    % Add mode transition markers
    mode_changes = find(diff(mode) ~= 0);
    for i = 1:length(mode_changes)
        for j = 1:4
            subplot(4,1,j);
            xline(t(mode_changes(i)), '--k', 'Mode Change');
        end
    end
    
    % Add common title
    sgtitle('Mode Switching Test Results', 'FontSize', 14);
    
    % Save figure
    saveas(fig, 'test_results/mode_switching_test.png');
end 