%% Load Step Test Runner
% This script runs only the load step tests

%% Initialize
if ~exist('test_config', 'var')
    % Test Configuration
    test_config.save_plots = true;
    test_config.generate_report = true;
    test_config.output_dir = 'test_results';
    
    % Create output directory if it doesn't exist
    if ~exist(test_config.output_dir, 'dir')
        mkdir(test_config.output_dir);
    end
end

%% Run Load Step Tests
fprintf('\nRunning Load Step Tests...\n');
fprintf('=======================\n');

% TC1.1: Load Increase
fprintf('TC1.1: Load Increase Test\n');
load.time = [0 5 5.1 10];
load.values = [0.6 0.6 1.0 1.0];
[tc1_1_results, tc1_1_metrics] = run_load_step_test(load, test_config);

% TC1.2: Load Decrease
fprintf('\nTC1.2: Load Decrease Test\n');
load.time = [0 5 5.1 10];
load.values = [1.0 1.0 0.6 0.6];
[tc1_2_results, tc1_2_metrics] = run_load_step_test(load, test_config);

%% Generate Report
if test_config.generate_report
    % Create dummy metrics for fault tests (not run)
    tc2_1_metrics = struct('v_min', 1, 'v_unbalance_max', 0, ...
        'v_recovery_time', 0, 'response_time', 0);
    tc2_2_metrics = struct('v_recovery', 1, 'recovery_time', 0, ...
        'final_VUF', 0, 'P_ess_final', 0, 'Q_ess_final', 0);
    
    generate_test_report(test_config.output_dir, ...
        tc1_1_metrics, tc1_2_metrics, ...
        tc2_1_metrics, tc2_2_metrics);
end

%% Display Summary
fprintf('\nLoad Step Test Summary:\n');
fprintf('=====================\n');
fprintf('TC1.1 Frequency Nadir: %.3f Hz\n', tc1_1_metrics.f_nadir);
fprintf('TC1.1 Settling Time: %.2f s\n', tc1_1_metrics.settling_time);
fprintf('TC1.2 Frequency Peak: %.3f Hz\n', tc1_2_metrics.f_peak);
fprintf('TC1.2 Settling Time: %.2f s\n', tc1_2_metrics.settling_time); 