%% Asymmetrical Fault Test Runner
% This script runs only the fault tests

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

%% Run Asymmetrical Fault Tests
fprintf('\nRunning Asymmetrical Fault Tests...\n');
fprintf('================================\n');

% TC2.1: Single-Phase Fault
fprintf('TC2.1: Single-Phase Fault Test\n');
fault.time = [0 3 3.15 10];
fault.Va = [1.0 0.2 1.0 1.0];
fault.Vb = [1.0 1.0 1.0 1.0];
fault.Vc = [1.0 1.0 1.0 1.0];
[tc2_1_results, tc2_1_metrics] = run_asymm_fault_test(fault, test_config);

% TC2.2: Fault Recovery
fprintf('\nTC2.2: Fault Recovery Test\n');
fault.time = [0 3 3.15 10];
fault.Va = [1.0 0.2 1.0 1.0];
fault.Vb = [1.0 1.0 1.0 1.0];
fault.Vc = [1.0 1.0 1.0 1.0];
[tc2_2_results, tc2_2_metrics] = run_fault_recovery_test(fault, test_config);

%% Generate Report
if test_config.generate_report
    % Create dummy metrics for load tests (not run)
    tc1_1_metrics = struct('f_nadir', 50, 'f_peak', 50, ...
        'settling_time', 0, 'response_time', 0);
    tc1_2_metrics = struct('f_nadir', 50, 'f_peak', 50, ...
        'settling_time', 0, 'response_time', 0);
    
    generate_test_report(test_config.output_dir, ...
        tc1_1_metrics, tc1_2_metrics, ...
        tc2_1_metrics, tc2_2_metrics);
end

%% Display Summary
fprintf('\nFault Test Summary:\n');
fprintf('=================\n');
fprintf('TC2.1 Minimum Voltage: %.3f pu\n', tc2_1_metrics.v_min);
fprintf('TC2.1 Maximum Unbalance: %.2f %%\n', tc2_1_metrics.v_unbalance_max);
fprintf('TC2.2 Recovery Time: %.3f s\n', tc2_2_metrics.recovery_time);
fprintf('TC2.2 Final Voltage: %.3f pu\n', tc2_2_metrics.v_recovery); 