%% Main Test Runner for DFIG Wind Power System
% This script runs all test cases and generates a comprehensive report

%% Initialize Test Environment
clear all; close all; clc;
addpath('../simulation');
init_simulink;

%% Test Configuration
test_config.save_plots = true;
test_config.generate_report = true;
test_config.output_dir = 'test_results';

% Create output directory if it doesn't exist
if ~exist(test_config.output_dir, 'dir')
    mkdir(test_config.output_dir);
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

%% Generate Comprehensive Report
if test_config.generate_report
    generate_test_report(test_config.output_dir, ...
        tc1_1_metrics, tc1_2_metrics, ...
        tc2_1_metrics, tc2_2_metrics);
end

%% Helper Functions
function [results, metrics] = run_load_step_test(load, config)
    % Run load step simulation
    sim('dfig_wind_system.slx');
    
    % Calculate metrics
    metrics.f_nadir = min(f_pcc);
    metrics.f_peak = max(f_pcc);
    metrics.settling_time = find(abs(f_pcc - 50) < 0.1, 1, 'last') * mean(diff(tout));
    metrics.P_ess_max = max(abs(P_ess));
    metrics.response_time = find(abs(P_ess) > 0.1*ess.Pn, 1) * mean(diff(tout));
    
    % Store results
    results.time = tout;
    results.f_pcc = f_pcc;
    results.P_ess = P_ess;
    results.soc = soc;
    
    % Generate plots
    if config.save_plots
        plot_load_step_results(results, metrics, config);
    end
    
    % Display results
    display_load_step_metrics(metrics);
end

function [results, metrics] = run_asymm_fault_test(fault, config)
    % Run asymmetrical fault simulation
    sim('dfig_wind_system.slx');
    
    % Calculate metrics
    metrics.v_min = min([min(Va_pcc) min(Vb_pcc) min(Vc_pcc)]);
    metrics.v_unbalance_max = max(VUF);
    metrics.v_recovery_time = find(min([Va_pcc Vb_pcc Vc_pcc], [], 2) > 0.9, 1, 'last') * mean(diff(tout));
    metrics.Q_ess_max = max(abs(Q_ess));
    metrics.response_time = find(abs(Q_ess) > 0.1*ess.Pn, 1) * mean(diff(tout));
    
    % Store results
    results.time = tout;
    results.Va_pcc = Va_pcc;
    results.Vb_pcc = Vb_pcc;
    results.Vc_pcc = Vc_pcc;
    results.P_ess = P_ess;
    results.Q_ess = Q_ess;
    results.VUF = VUF;
    
    % Generate plots
    if config.save_plots
        plot_fault_test_results(results, metrics, config);
    end
    
    % Display results
    display_fault_test_metrics(metrics);
end

function [results, metrics] = run_fault_recovery_test(fault, config)
    % Run fault recovery simulation
    sim('dfig_wind_system.slx');
    
    % Calculate recovery metrics
    metrics.v_recovery = min([Va_pcc(end) Vb_pcc(end) Vc_pcc(end)]);
    metrics.recovery_time = find(min([Va_pcc Vb_pcc Vc_pcc], [], 2) > 0.9, 1, 'last') * mean(diff(tout));
    metrics.final_VUF = VUF(end);
    metrics.P_ess_final = P_ess(end);
    metrics.Q_ess_final = Q_ess(end);
    
    % Store results
    results.time = tout;
    results.Va_pcc = Va_pcc;
    results.Vb_pcc = Vb_pcc;
    results.Vc_pcc = Vc_pcc;
    results.P_ess = P_ess;
    results.Q_ess = Q_ess;
    results.VUF = VUF;
    
    % Generate plots
    if config.save_plots
        plot_recovery_test_results(results, metrics, config);
    end
    
    % Display results
    display_recovery_test_metrics(metrics);
end

function display_load_step_metrics(metrics)
    fprintf('\nLoad Step Test Metrics:\n');
    fprintf('  Frequency Nadir: %.3f Hz\n', metrics.f_nadir);
    fprintf('  Frequency Peak: %.3f Hz\n', metrics.f_peak);
    fprintf('  Settling Time: %.3f s\n', metrics.settling_time);
    fprintf('  Maximum ESS Power: %.2f MW\n', metrics.P_ess_max/1e6);
    fprintf('  Response Time: %.3f s\n', metrics.response_time);
end

function display_fault_test_metrics(metrics)
    fprintf('\nFault Test Metrics:\n');
    fprintf('  Minimum Voltage: %.3f pu\n', metrics.v_min);
    fprintf('  Maximum Unbalance: %.2f %%\n', metrics.v_unbalance_max);
    fprintf('  Recovery Time: %.3f s\n', metrics.v_recovery_time);
    fprintf('  Maximum Reactive Power: %.2f MVAr\n', metrics.Q_ess_max/1e6);
    fprintf('  Response Time: %.3f s\n', metrics.response_time);
end

function display_recovery_test_metrics(metrics)
    fprintf('\nRecovery Test Metrics:\n');
    fprintf('  Final Voltage: %.3f pu\n', metrics.v_recovery);
    fprintf('  Recovery Time: %.3f s\n', metrics.recovery_time);
    fprintf('  Final Unbalance: %.2f %%\n', metrics.final_VUF);
    fprintf('  Final ESS Active Power: %.2f MW\n', metrics.P_ess_final/1e6);
    fprintf('  Final ESS Reactive Power: %.2f MVAr\n', metrics.Q_ess_final/1e6);
end 