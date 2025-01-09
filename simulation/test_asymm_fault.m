%% Test Script for Asymmetrical Fault Scenario
% This script simulates single-phase-to-ground fault and analyzes ESS voltage support

%% Load base parameters
init_simulink;

%% Configure Fault Parameters
% Time points for fault
fault.time = [0 3 3.15 10];
% Voltage profile for phases (pu) [Va Vb Vc]
fault.Va = [1.0 0.2 1.0 1.0];    % Faulted phase
fault.Vb = [1.0 1.0 1.0 1.0];    % Healthy phase
fault.Vc = [1.0 1.0 1.0 1.0];    % Healthy phase

% Enable ESS support
ess.enabled = 1;
ess.Pn = 0.5e6;     % Rated power 0.5MW
ess.soc_init = 0.8; % Initial SOC

% Enhanced FRT parameters
ctrl.frt.Kp_v = 2.0;  % Voltage controller P gain
ctrl.frt.Ki_v = 100;  % Voltage controller I gain
ctrl.frt.max_Q = 1.2; % Maximum reactive power in pu

%% Run Simulation
sim('dfig_wind_system.slx');

%% Analyze Results
figure('Position', [100 100 1200 800]);

% Plot 1: Three-Phase Voltages at PCC
subplot(3,1,1)
plot(tout, Va_pcc, 'r', 'LineWidth', 2)
hold on
plot(tout, Vb_pcc, 'g', 'LineWidth', 2)
plot(tout, Vc_pcc, 'b', 'LineWidth', 2)
grid on
title('PCC Voltages')
xlabel('Time (s)')
ylabel('Voltage (pu)')
legend('Va', 'Vb', 'Vc')
ylim([0 1.2])

% Plot 2: ESS Response
subplot(3,1,2)
yyaxis left
plot(tout, P_ess/1e6, 'b', 'LineWidth', 2)
ylabel('Active Power (MW)')
yyaxis right
plot(tout, Q_ess/1e6, 'r', 'LineWidth', 2)
ylabel('Reactive Power (MVAr)')
grid on
title('ESS Power Response')
xlabel('Time (s)')
legend('P_{ESS}', 'Q_{ESS}')

% Plot 3: Voltage Unbalance and ESS State
subplot(3,1,3)
yyaxis left
plot(tout, VUF, 'b', 'LineWidth', 2)
ylabel('Voltage Unbalance Factor (%)')
yyaxis right
plot(tout, soc, 'r', 'LineWidth', 2)
ylabel('SOC')
grid on
title('Voltage Unbalance and ESS State')
xlabel('Time (s)')
legend('VUF', 'SOC')

%% Calculate Performance Metrics
% Voltage metrics
v_min = min([min(Va_pcc) min(Vb_pcc) min(Vc_pcc)]);
v_unbalance_max = max(VUF);
v_recovery_time = find(min([Va_pcc Vb_pcc Vc_pcc], [], 2) > 0.9, 1, 'last') * mean(diff(tout));

% ESS response metrics
Q_ess_max = max(abs(Q_ess));
P_ess_max = max(abs(P_ess));
soc_variation = max(soc) - min(soc);
response_time = find(abs(Q_ess) > 0.1*ess.Pn, 1) * mean(diff(tout));

%% Display Results
fprintf('\nAsymmetrical Fault Response Analysis\n')
fprintf('==================================\n')
fprintf('Voltage Performance:\n')
fprintf('  - Minimum Voltage: %.3f pu\n', v_min)
fprintf('  - Maximum Unbalance: %.2f %%\n', v_unbalance_max)
fprintf('  - Recovery Time: %.3f s\n', v_recovery_time)
fprintf('\nESS Performance:\n')
fprintf('  - Maximum Reactive Power: %.2f MVAr\n', Q_ess_max/1e6)
fprintf('  - Maximum Active Power: %.2f MW\n', P_ess_max/1e6)
fprintf('  - SOC Variation: %.3f\n', soc_variation)
fprintf('  - Response Time: %.3f s\n', response_time)

saveas(gcf, 'asymm_fault_analysis.png') 