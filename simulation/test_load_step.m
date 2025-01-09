%% Test Script for Load Step Change Scenario
% This script simulates load step change and analyzes ESS support capability

%% Load base parameters
init_simulink;

%% Configure Load Step Parameters
% Time points for load step
load.time = [0 5 5.1 10];   
% Load power in p.u. (40% step increase)
load.values = [0.6 0.6 1.0 1.0];  

% Enable ESS support
ess.enabled = 1;
ess.Pn = 0.5e6;     % Rated power 0.5MW
ess.soc_init = 0.8; % Initial SOC

%% Run Simulation
sim('dfig_wind_system.slx');

%% Analyze Results
figure('Position', [100 100 1200 800]);

% Plot 1: Load Power and ESS Response
subplot(3,1,1)
plot(tout, P_load/1e6, 'b', 'LineWidth', 2)
hold on
plot(tout, P_ess/1e6, 'r', 'LineWidth', 2)
grid on
title('Load Power and ESS Response')
xlabel('Time (s)')
ylabel('Power (MW)')
legend('Load Power', 'ESS Power')

% Plot 2: PCC Frequency
subplot(3,1,2)
plot(tout, f_pcc, 'b', 'LineWidth', 2)
grid on
title('PCC Frequency')
xlabel('Time (s)')
ylabel('Frequency (Hz)')
yline(50, 'k--')
ylim([49.5 50.5])

% Plot 3: ESS State of Charge
subplot(3,1,3)
plot(tout, soc, 'b', 'LineWidth', 2)
grid on
title('ESS State of Charge')
xlabel('Time (s)')
ylabel('SOC')
ylim([0 1])

%% Calculate Performance Metrics
% Frequency metrics
f_nadir = min(f_pcc);
f_settling_time = find(abs(f_pcc - 50) < 0.1, 1, 'last') * mean(diff(tout));
f_deviation = max(abs(f_pcc - 50));

% ESS response metrics
P_ess_max = max(abs(P_ess));
soc_variation = max(soc) - min(soc);
response_time = find(abs(P_ess) > 0.1*ess.Pn, 1) * mean(diff(tout));

%% Display Results
fprintf('\nLoad Step Response Analysis\n')
fprintf('==========================\n')
fprintf('Frequency Performance:\n')
fprintf('  - Nadir: %.3f Hz\n', f_nadir)
fprintf('  - Settling Time: %.2f s\n', f_settling_time)
fprintf('  - Maximum Deviation: %.3f Hz\n', f_deviation)
fprintf('\nESS Performance:\n')
fprintf('  - Maximum Power: %.2f MW\n', P_ess_max/1e6)
fprintf('  - SOC Variation: %.3f\n', soc_variation)
fprintf('  - Response Time: %.3f s\n', response_time)

saveas(gcf, 'load_step_analysis.png') 