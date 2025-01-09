classdef visualization < handle
    % VISUALIZATION Visualization utilities for DFIG wind power system
    %   Implements real-time plotting and data visualization functions
    
    properties (Access = private)
        % Figure handles
        main_figure
        subplot_handles
        
        % Plot configuration
        config
        
        % Data buffers
        time_buffer
        data_buffers
        
        % Update parameters
        last_update
        update_interval
    end
    
    methods
        function obj = visualization(config)
            % Constructor
            obj.config = config;
            obj.initialize_figure();
            obj.initialize_buffers();
            obj.update_interval = 0.1;  % 100ms update interval
        end
        
        function update(obj, state, mode, refs)
            % Update visualization
            
            % Check if update is needed
            if toc(obj.last_update) < obj.update_interval
                return;
            end
            
            % Update data buffers
            obj.update_buffers(state, mode, refs);
            
            % Update plots
            obj.update_plots();
            
            % Update timestamp
            obj.last_update = tic;
        end
        
        function save_plots(obj, filename)
            % Save current plots to file
            savefig(obj.main_figure, [filename, '.fig']);
            saveas(obj.main_figure, [filename, '.png']);
        end
    end
    
    methods (Access = private)
        function initialize_figure(obj)
            % Initialize main figure and subplots
            obj.main_figure = figure('Name', 'DFIG Wind Power System Monitor', ...
                'NumberTitle', 'off', ...
                'Position', [100, 100, 1200, 800]);
            
            % Create subplots
            obj.subplot_handles.voltage = subplot(3,2,1);
            title('Grid Voltage');
            ylabel('Voltage (p.u.)');
            grid on;
            
            obj.subplot_handles.frequency = subplot(3,2,2);
            title('Grid Frequency');
            ylabel('Frequency (Hz)');
            grid on;
            
            obj.subplot_handles.power = subplot(3,2,3);
            title('Power Output');
            ylabel('Power (MW)');
            grid on;
            
            obj.subplot_handles.soc = subplot(3,2,4);
            title('Battery SOC');
            ylabel('SOC (%)');
            grid on;
            
            obj.subplot_handles.mode = subplot(3,2,5);
            title('Operation Mode');
            ylabel('Mode');
            grid on;
            
            obj.subplot_handles.wind = subplot(3,2,6);
            title('Wind Speed');
            ylabel('Speed (m/s)');
            grid on;
        end
        
        function initialize_buffers(obj)
            % Initialize data buffers
            buffer_size = round(obj.config.plot_duration / ...
                obj.config.sampling_time);
            
            obj.time_buffer = zeros(buffer_size, 1);
            
            obj.data_buffers = struct(...
                'voltage', zeros(buffer_size, 1),...
                'frequency', zeros(buffer_size, 1),...
                'power', zeros(buffer_size, 1),...
                'soc', zeros(buffer_size, 1),...
                'mode', zeros(buffer_size, 1),...
                'wind_speed', zeros(buffer_size, 1)...
            );
            
            obj.last_update = tic;
        end
        
        function update_buffers(obj, state, mode, refs)
            % Update data buffers with new data
            
            % Shift buffers
            obj.time_buffer = [obj.time_buffer(2:end); state.time];
            
            % Update individual buffers
            obj.data_buffers.voltage = [obj.data_buffers.voltage(2:end); ...
                state.grid_voltage];
            obj.data_buffers.frequency = [obj.data_buffers.frequency(2:end); ...
                state.grid_frequency];
            obj.data_buffers.power = [obj.data_buffers.power(2:end); ...
                state.power_output];
            obj.data_buffers.soc = [obj.data_buffers.soc(2:end); ...
                state.soc * 100];
            obj.data_buffers.mode = [obj.data_buffers.mode(2:end); ...
                obj.mode_to_number(mode)];
            obj.data_buffers.wind_speed = [obj.data_buffers.wind_speed(2:end); ...
                state.wind_speed];
        end
        
        function update_plots(obj)
            % Update all plots
            
            % Voltage plot
            plot(obj.subplot_handles.voltage, obj.time_buffer, ...
                obj.data_buffers.voltage, 'b-', ...
                'LineWidth', 1.5);
            ylim(obj.subplot_handles.voltage, [0.8, 1.2]);
            
            % Frequency plot
            plot(obj.subplot_handles.frequency, obj.time_buffer, ...
                obj.data_buffers.frequency, 'r-', ...
                'LineWidth', 1.5);
            ylim(obj.subplot_handles.frequency, [49, 51]);
            
            % Power plot
            plot(obj.subplot_handles.power, obj.time_buffer, ...
                obj.data_buffers.power, 'g-', ...
                'LineWidth', 1.5);
            
            % SOC plot
            plot(obj.subplot_handles.soc, obj.time_buffer, ...
                obj.data_buffers.soc, 'm-', ...
                'LineWidth', 1.5);
            ylim(obj.subplot_handles.soc, [0, 100]);
            
            % Mode plot
            stairs(obj.subplot_handles.mode, obj.time_buffer, ...
                obj.data_buffers.mode, 'k-', ...
                'LineWidth', 1.5);
            ylim(obj.subplot_handles.mode, [0.5, 3.5]);
            yticks(obj.subplot_handles.mode, 1:3);
            yticklabels(obj.subplot_handles.mode, ...
                {'Grid Following', 'Grid Forming', 'Emergency'});
            
            % Wind speed plot
            plot(obj.subplot_handles.wind, obj.time_buffer, ...
                obj.data_buffers.wind_speed, 'c-', ...
                'LineWidth', 1.5);
            
            % Update figure
            drawnow;
        end
        
        function mode_num = mode_to_number(obj, mode)
            % Convert mode string to number
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
    end
    
    methods (Static)
        function create_performance_plots(data, filename)
            % Create performance analysis plots
            
            figure('Name', 'Performance Analysis', ...
                'NumberTitle', 'off', ...
                'Position', [200, 200, 1000, 600]);
            
            % Voltage and frequency quality
            subplot(2,2,1);
            plot(data.time, data.voltage_quality, 'b-', ...
                data.time, data.frequency_quality, 'r--', ...
                'LineWidth', 1.5);
            title('Quality Indices');
            legend('Voltage', 'Frequency');
            grid on;
            
            % Power quality
            subplot(2,2,2);
            plot(data.time, data.power_quality, 'g-', ...
                'LineWidth', 1.5);
            title('Power Quality');
            grid on;
            
            % Mode transitions
            subplot(2,2,3);
            plot(data.time, data.mode_transitions, 'k-', ...
                'LineWidth', 1.5);
            title('Mode Transitions');
            grid on;
            
            % System efficiency
            subplot(2,2,4);
            plot(data.time, data.efficiency, 'b-', ...
                'LineWidth', 1.5);
            title('System Efficiency');
            grid on;
            
            % Save plots
            if nargin > 1
                savefig(gcf, [filename, '_performance.fig']);
                saveas(gcf, [filename, '_performance.png']);
            end
        end
    end
end 