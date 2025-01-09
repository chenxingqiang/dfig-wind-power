%% Analyze Simulation Results
% Analysis script for DFIG wind power system simulation results

%% Load Simulation Data
load('sim_results.mat');
load('model_params.mat');

%% Create Figure Window
figure('Position', [100 100 1200 800]);

%% Plot Grid Conditions
subplot(3,2,1)
% Plot voltage
yyaxis left
plot(tout, v_grid, 'LineWidth', 1.5)
ylabel('Grid Voltage (pu)')
ylim([0 1.2])

% Plot frequency
yyaxis right
plot(tout, f_grid, 'LineWidth', 1.5)
ylabel('Grid Frequency (Hz)')
ylim([49 51])

title('Grid Conditions')
grid on
xlabel('Time (s)')

%% Plot DFIG Currents
subplot(3,2,2)
% Plot stator currents
plot(tout, ids, 'LineWidth', 1.5)
hold on
plot(tout, iqs, 'LineWidth', 1.5)
% Plot rotor currents
plot(tout, idr, '--', 'LineWidth', 1.5)
plot(tout, iqr, '--', 'LineWidth', 1.5)
hold off

title('DFIG Currents')
ylabel('Current (pu)')
xlabel('Time (s)')
legend('i_{ds}', 'i_{qs}', 'i_{dr}', 'i_{qr}')
grid on

%% Plot Power Output
subplot(3,2,3)
% Plot active and reactive power
plot(tout, P_dfig/1e6, 'LineWidth', 1.5)
hold on
plot(tout, Q_dfig/1e6, 'LineWidth', 1.5)
plot(tout, P_ess/1e6, '--', 'LineWidth', 1.5)
hold off

title('Power Output')
ylabel('Power (MW/MVAr)')
xlabel('Time (s)')
legend('P_{DFIG}', 'Q_{DFIG}', 'P_{ESS}')
grid on

%% Plot Energy Storage
subplot(3,2,4)
% Plot SOC and power
yyaxis left
plot(tout, soc, 'LineWidth', 1.5)
ylabel('State of Charge')
ylim([0 1])

yyaxis right
plot(tout, P_ess/1e6, '--', 'LineWidth', 1.5)
ylabel('ESS Power (MW)')

title('Energy Storage System')
xlabel('Time (s)')
grid on

%% Plot Operation Mode
subplot(3,2,5)
plot(tout, mode, 'LineWidth', 1.5, 'Marker', '.')
yticks([1 2 3])
yticklabels({'Grid Following', 'Grid Forming', 'Emergency'})

title('Operation Mode')
xlabel('Time (s)')
grid on

%% Calculate Performance Metrics
% Voltage quality
v_quality = mean(abs(v_grid - 1));
v_max_dev = max(abs(v_grid - 1));

% Frequency quality
f_quality = mean(abs(f_grid - 50));
f_max_dev = max(abs(f_grid - 50));

% Mode transitions
mode_changes = sum(diff(mode) ~= 0);
avg_mode_duration = mean(diff(find([1; diff(mode) ~= 0; 1]))) * mean(diff(tout));

% Power quality
P_quality = std(P_dfig)/mean(abs(P_dfig));
Q_quality = mean(abs(Q_dfig))/dfig.Pn;

% ESS utilization
ess_cycles = trapz(tout, abs(P_ess))/(2*ess.En);
soc_variation = max(soc) - min(soc);

%% Display Performance Metrics
subplot(3,2,6)
metrics = {
    sprintf('Voltage Quality: %.3f pu', v_quality)
    sprintf('Max Voltage Dev: %.3f pu', v_max_dev)
    sprintf('Frequency Quality: %.3f Hz', f_quality)
    sprintf('Max Freq Dev: %.3f Hz', f_max_dev)
    sprintf('Mode Changes: %d', mode_changes)
    sprintf('Avg Mode Duration: %.2f s', avg_mode_duration)
    sprintf('Power Quality: %.3f', P_quality)
    sprintf('ESS Cycles: %.2f', ess_cycles)
};

text(0.1, 0.9, metrics, 'Units', 'normalized', 'VerticalAlignment', 'top')
axis off
title('Performance Metrics')

%% Save Results
saveas(gcf, 'simulation_analysis.png')

%% Additional Analysis

% Create mode transition analysis
figure('Position', [100 100 800 400]);

% Plot mode transitions with events
subplot(2,1,1)
plot(tout, mode, 'LineWidth', 1.5)
hold on
% Mark voltage events
voltage_events = find(abs(diff(v_grid)) > 0.1);
plot(tout(voltage_events), mode(voltage_events), 'ro', 'MarkerFaceColor', 'r')
% Mark frequency events
freq_events = find(abs(diff(f_grid)) > 0.2);
plot(tout(freq_events), mode(freq_events), 'bs', 'MarkerFaceColor', 'b')
hold off

title('Mode Transitions')
ylabel('Mode')
yticks([1 2 3])
yticklabels({'Grid Following', 'Grid Forming', 'Emergency'})
grid on

% Plot transition statistics
subplot(2,1,2)
transition_matrix = zeros(3,3);
for i = 1:length(mode)-1
    if mode(i) ~= mode(i+1)
        transition_matrix(mode(i), mode(i+1)) = ...
            transition_matrix(mode(i), mode(i+1)) + 1;
    end
end

imagesc(transition_matrix)
colorbar
title('Transition Matrix')
xlabel('To Mode')
ylabel('From Mode')
xticks(1:3)
yticks(1:3)
xticklabels({'GF', 'GM', 'EM'})
yticklabels({'GF', 'GM', 'EM'})

saveas(gcf, 'mode_transition_analysis.png')

%% Print Summary Report
fprintf('\nSimulation Analysis Summary\n')
fprintf('========================\n')
fprintf('Voltage Performance:\n')
fprintf('  - Average quality: %.3f pu\n', v_quality)
fprintf('  - Maximum deviation: %.3f pu\n', v_max_dev)
fprintf('\nFrequency Performance:\n')
fprintf('  - Average quality: %.3f Hz\n', f_quality)
fprintf('  - Maximum deviation: %.3f Hz\n', f_max_dev)
fprintf('\nMode Switching Performance:\n')
fprintf('  - Number of transitions: %d\n', mode_changes)
fprintf('  - Average mode duration: %.2f s\n', avg_mode_duration)
fprintf('\nPower Quality:\n')
fprintf('  - Active power variation: %.3f\n', P_quality)
fprintf('  - Average reactive power: %.3f pu\n', Q_quality)
fprintf('\nEnergy Storage Performance:\n')
fprintf('  - Equivalent cycles: %.2f\n', ess_cycles)
fprintf('  - SOC variation: %.3f\n', soc_variation); 