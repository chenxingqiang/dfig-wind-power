%% Plot Functions for Test Results

function plot_load_step_results(results, metrics, config)
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot 1: Load Power and ESS Response
    subplot(3,1,1)
    plot(results.time, results.P_ess/1e6, 'r', 'LineWidth', 2)
    hold on
    plot(results.time, results.P_load/1e6, 'b', 'LineWidth', 2)
    grid on
    title('Load Power and ESS Response')
    xlabel('Time (s)')
    ylabel('Power (MW)')
    legend('ESS Power', 'Load Power')
    
    % Plot 2: PCC Frequency
    subplot(3,1,2)
    plot(results.time, results.f_pcc, 'b', 'LineWidth', 2)
    hold on
    yline(50, 'k--')
    yline(49.5, 'r--')
    yline(50.5, 'r--')
    grid on
    title('PCC Frequency')
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    ylim([49.4 50.6])
    
    % Plot 3: ESS State of Charge
    subplot(3,1,3)
    plot(results.time, results.soc, 'b', 'LineWidth', 2)
    hold on
    yline(0.9, 'r--')
    yline(0.1, 'r--')
    grid on
    title('ESS State of Charge')
    xlabel('Time (s)')
    ylabel('SOC')
    ylim([0 1])
    
    % Add performance metrics text box
    dim = [.15 .15 .3 .3];
    str = sprintf(['Frequency Metrics:\n' ...
                  'Nadir: %.3f Hz\n' ...
                  'Peak: %.3f Hz\n' ...
                  'Settling Time: %.2f s\n' ...
                  'ESS Response Time: %.3f s'], ...
                  metrics.f_nadir, metrics.f_peak, ...
                  metrics.settling_time, metrics.response_time);
    annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', ...
               'BackgroundColor', 'white');
    
    % Save figure
    if config.save_plots
        saveas(gcf, fullfile(config.output_dir, 'load_step_results.png'));
        close(gcf);
    end
end

function plot_fault_test_results(results, metrics, config)
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot 1: Three-Phase Voltages
    subplot(3,1,1)
    plot(results.time, results.Va_pcc, 'r', 'LineWidth', 2)
    hold on
    plot(results.time, results.Vb_pcc, 'g', 'LineWidth', 2)
    plot(results.time, results.Vc_pcc, 'b', 'LineWidth', 2)
    yline(0.9, 'k--')
    grid on
    title('PCC Voltages')
    xlabel('Time (s)')
    ylabel('Voltage (pu)')
    legend('Va', 'Vb', 'Vc')
    ylim([0 1.2])
    
    % Plot 2: ESS Power Response
    subplot(3,1,2)
    yyaxis left
    plot(results.time, results.P_ess/1e6, 'b', 'LineWidth', 2)
    ylabel('Active Power (MW)')
    yyaxis right
    plot(results.time, results.Q_ess/1e6, 'r', 'LineWidth', 2)
    ylabel('Reactive Power (MVAr)')
    grid on
    title('ESS Power Response')
    xlabel('Time (s)')
    legend('P_{ESS}', 'Q_{ESS}')
    
    % Plot 3: Voltage Unbalance Factor
    subplot(3,1,3)
    plot(results.time, results.VUF*100, 'b', 'LineWidth', 2)
    hold on
    yline(2, 'r--')  % 2% limit
    grid on
    title('Voltage Unbalance Factor')
    xlabel('Time (s)')
    ylabel('VUF (%)')
    ylim([0 5])
    
    % Add performance metrics text box
    dim = [.15 .15 .3 .3];
    str = sprintf(['Voltage Metrics:\n' ...
                  'Min Voltage: %.3f pu\n' ...
                  'Max Unbalance: %.2f %%\n' ...
                  'Recovery Time: %.3f s\n' ...
                  'ESS Response Time: %.3f s'], ...
                  metrics.v_min, metrics.v_unbalance_max, ...
                  metrics.v_recovery_time, metrics.response_time);
    annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', ...
               'BackgroundColor', 'white');
    
    % Save figure
    if config.save_plots
        saveas(gcf, fullfile(config.output_dir, 'fault_test_results.png'));
        close(gcf);
    end
end

function plot_recovery_test_results(results, metrics, config)
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot 1: Three-Phase Voltages During Recovery
    subplot(3,1,1)
    plot(results.time, results.Va_pcc, 'r', 'LineWidth', 2)
    hold on
    plot(results.time, results.Vb_pcc, 'g', 'LineWidth', 2)
    plot(results.time, results.Vc_pcc, 'b', 'LineWidth', 2)
    yline(0.9, 'k--')
    grid on
    title('PCC Voltage Recovery')
    xlabel('Time (s)')
    ylabel('Voltage (pu)')
    legend('Va', 'Vb', 'Vc')
    ylim([0 1.2])
    
    % Plot 2: ESS Power During Recovery
    subplot(3,1,2)
    yyaxis left
    plot(results.time, results.P_ess/1e6, 'b', 'LineWidth', 2)
    ylabel('Active Power (MW)')
    yyaxis right
    plot(results.time, results.Q_ess/1e6, 'r', 'LineWidth', 2)
    ylabel('Reactive Power (MVAr)')
    grid on
    title('ESS Power During Recovery')
    xlabel('Time (s)')
    legend('P_{ESS}', 'Q_{ESS}')
    
    % Plot 3: Voltage Unbalance Recovery
    subplot(3,1,3)
    plot(results.time, results.VUF*100, 'b', 'LineWidth', 2)
    hold on
    yline(2, 'r--')  % 2% limit
    grid on
    title('Voltage Unbalance Recovery')
    xlabel('Time (s)')
    ylabel('VUF (%)')
    ylim([0 5])
    
    % Add recovery metrics text box
    dim = [.15 .15 .3 .3];
    str = sprintf(['Recovery Metrics:\n' ...
                  'Final Voltage: %.3f pu\n' ...
                  'Recovery Time: %.3f s\n' ...
                  'Final Unbalance: %.2f %%\n' ...
                  'Final ESS P: %.2f MW\n' ...
                  'Final ESS Q: %.2f MVAr'], ...
                  metrics.v_recovery, metrics.recovery_time, ...
                  metrics.final_VUF, ...
                  metrics.P_ess_final/1e6, metrics.Q_ess_final/1e6);
    annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', ...
               'BackgroundColor', 'white');
    
    % Save figure
    if config.save_plots
        saveas(gcf, fullfile(config.output_dir, 'recovery_test_results.png'));
        close(gcf);
    end
end 