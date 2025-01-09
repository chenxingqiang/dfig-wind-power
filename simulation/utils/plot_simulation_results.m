function plot_simulation_results(t, v_grid, f_grid, i_rsc, i_gsc, soc, mode)
%% Plot Simulation Results
% Creates comprehensive plots of simulation results
% Inputs:
%   t - Time vector
%   v_grid - Grid voltage
%   f_grid - Grid frequency
%   i_rsc - RSC currents
%   i_gsc - GSC currents
%   soc - Energy storage SOC
%   mode - Operation mode

%% Figure Setup
% Create figure window
fig = figure('Position', [100 100 1200 800]);

%% Grid Conditions
subplot(3,2,1)
% Plot voltage
yyaxis left
plot(t, v_grid, 'LineWidth', 1.5)
ylabel('Grid Voltage (pu)')
ylim([0 1.2])

% Plot frequency
yyaxis right
plot(t, f_grid, 'LineWidth', 1.5)
ylabel('Grid Frequency (Hz)')
ylim([49 51])

title('Grid Conditions')
grid on
xlabel('Time (s)')

%% Converter Currents
subplot(3,2,2)
% Plot RSC currents
plot(t, i_rsc(:,1), 'LineWidth', 1.5)
hold on
plot(t, i_rsc(:,2), 'LineWidth', 1.5)
% Plot GSC currents
plot(t, i_gsc(:,1), '--', 'LineWidth', 1.5)
plot(t, i_gsc(:,2), '--', 'LineWidth', 1.5)
hold off

title('Converter Currents')
ylabel('Current (pu)')
xlabel('Time (s)')
legend('RSC-d', 'RSC-q', 'GSC-d', 'GSC-q')
grid on

%% Power Output
subplot(3,2,3)
% Calculate powers
P_dfig = v_grid .* i_rsc(:,1);
Q_dfig = v_grid .* i_rsc(:,2);

plot(t, P_dfig, 'LineWidth', 1.5)
hold on
plot(t, Q_dfig, 'LineWidth', 1.5)
hold off

title('DFIG Power Output')
ylabel('Power (pu)')
xlabel('Time (s)')
legend('Active Power', 'Reactive Power')
grid on

%% Energy Storage
subplot(3,2,4)
plot(t, soc, 'LineWidth', 1.5)
hold on
yline(0.9, 'r--', 'SOC_{max}')
yline(0.1, 'r--', 'SOC_{min}')
hold off

title('Energy Storage')
ylabel('State of Charge')
xlabel('Time (s)')
ylim([0 1])
grid on

%% Operation Mode
subplot(3,2,5)
plot(t, mode, 'LineWidth', 1.5, 'Marker', '.')
yticks([1 2 3])
yticklabels({'Grid Following', 'Grid Forming', 'Emergency'})

title('Operation Mode')
xlabel('Time (s)')
grid on

%% System Performance Metrics
subplot(3,2,6)
% Calculate performance metrics
voltage_quality = mean(abs(v_grid - 1));
freq_quality = mean(abs(f_grid - 50));
mode_switches = sum(diff(mode) ~= 0);

% Create text box with metrics
text_str = {
    ['Voltage Quality: ' num2str(voltage_quality, '%.3f')],
    ['Frequency Quality: ' num2str(freq_quality, '%.3f')],
    ['Mode Switches: ' num2str(mode_switches)],
    ['Final SOC: ' num2str(soc(end), '%.2f')]
};

text(0.1, 0.5, text_str, 'Units', 'normalized', 'FontSize', 12)
axis off
title('Performance Metrics')

%% Save Results
saveas(fig, 'simulation_results.png')
end 