classdef data_processing < handle
    % DATA_PROCESSING Data processing utilities for DFIG wind power system
    %   Implements data collection, processing, and analysis functions
    
    properties (Access = private)
        % Data storage
        data_buffer
        
        % Configuration
        config
        
        % Statistics
        statistics
    end
    
    methods
        function obj = data_processing(config)
            % Constructor
            obj.config = config;
            obj.initialize_buffer();
            obj.initialize_statistics();
        end
        
        function log_data(obj, state, mode, refs)
            % Log system data
            
            % Create data point
            data_point = obj.create_data_point(state, mode, refs);
            
            % Add to buffer
            obj.add_to_buffer(data_point);
            
            % Update statistics
            obj.update_statistics(data_point);
        end
        
        function stats = get_statistics(obj)
            % Get current statistics
            stats = obj.statistics;
        end
        
        function data = get_recent_data(obj, duration)
            % Get recent data for specified duration
            if nargin < 2
                duration = 60;  % Default 60 seconds
            end
            
            % Calculate number of samples
            n_samples = round(duration / obj.config.sampling_time);
            
            % Get recent data
            data = obj.data_buffer(max(1, end-n_samples+1):end, :);
        end
        
        function export_data(obj, filename)
            % Export data to file
            data_table = array2table(obj.data_buffer, 'VariableNames', ...
                obj.config.data_fields);
            writetable(data_table, filename);
        end
    end
    
    methods (Access = private)
        function initialize_buffer(obj)
            % Initialize data buffer
            buffer_size = round(obj.config.buffer_duration / ...
                obj.config.sampling_time);
            n_fields = length(obj.config.data_fields);
            
            obj.data_buffer = zeros(buffer_size, n_fields);
        end
        
        function initialize_statistics(obj)
            % Initialize statistics structure
            obj.statistics = struct(...
                'voltage_mean', 0,...
                'voltage_std', 0,...
                'frequency_mean', 0,...
                'frequency_std', 0,...
                'power_mean', 0,...
                'power_std', 0,...
                'soc_mean', 0,...
                'mode_transitions', 0,...
                'fault_count', 0...
            );
        end
        
        function data_point = create_data_point(obj, state, mode, refs)
            % Create data point from current system state
            data_point = [
                state.time,...
                state.grid_voltage,...
                state.grid_frequency,...
                state.wind_speed,...
                state.power_output,...
                state.soc,...
                obj.mode_to_number(mode),...
                refs.P_ref,...
                refs.Q_ref
            ];
        end
        
        function add_to_buffer(obj, data_point)
            % Add data point to buffer
            obj.data_buffer = [obj.data_buffer(2:end,:); data_point];
        end
        
        function update_statistics(obj, data_point)
            % Update running statistics
            
            % Update means using exponential moving average
            alpha = 0.01;  % Smoothing factor
            
            obj.statistics.voltage_mean = (1-alpha) * ...
                obj.statistics.voltage_mean + alpha * data_point(2);
            obj.statistics.frequency_mean = (1-alpha) * ...
                obj.statistics.frequency_mean + alpha * data_point(3);
            obj.statistics.power_mean = (1-alpha) * ...
                obj.statistics.power_mean + alpha * data_point(5);
            obj.statistics.soc_mean = (1-alpha) * ...
                obj.statistics.soc_mean + alpha * data_point(6);
            
            % Update standard deviations
            obj.statistics.voltage_std = sqrt((1-alpha) * ...
                obj.statistics.voltage_std^2 + alpha * ...
                (data_point(2) - obj.statistics.voltage_mean)^2);
            
            obj.statistics.frequency_std = sqrt((1-alpha) * ...
                obj.statistics.frequency_std^2 + alpha * ...
                (data_point(3) - obj.statistics.frequency_mean)^2);
            
            obj.statistics.power_std = sqrt((1-alpha) * ...
                obj.statistics.power_std^2 + alpha * ...
                (data_point(5) - obj.statistics.power_mean)^2);
            
            % Update mode transitions
            if obj.data_buffer(end-1,7) ~= data_point(7)
                obj.statistics.mode_transitions = ...
                    obj.statistics.mode_transitions + 1;
            end
            
            % Update fault count
            if data_point(2) < obj.config.fault_threshold
                obj.statistics.fault_count = ...
                    obj.statistics.fault_count + 1;
            end
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
        function analyze_performance(data)
            % Analyze system performance
            
            % Calculate performance metrics
            metrics = struct(...
                'voltage_quality', calculate_voltage_quality(data),...
                'frequency_quality', calculate_frequency_quality(data),...
                'power_quality', calculate_power_quality(data),...
                'mode_stability', calculate_mode_stability(data)...
            );
            
            % Display results
            disp('Performance Analysis:');
            disp(['Voltage Quality: ', num2str(metrics.voltage_quality)]);
            disp(['Frequency Quality: ', num2str(metrics.frequency_quality)]);
            disp(['Power Quality: ', num2str(metrics.power_quality)]);
            disp(['Mode Stability: ', num2str(metrics.mode_stability)]);
        end
    end
end

%% Utility Functions
function vq = calculate_voltage_quality(data)
    % Calculate voltage quality index
    voltage = data(:,2);
    vq = 1 - std(voltage) / mean(voltage);
end

function fq = calculate_frequency_quality(data)
    % Calculate frequency quality index
    frequency = data(:,3);
    fq = 1 - std(frequency) / 50;
end

function pq = calculate_power_quality(data)
    % Calculate power quality index
    power = data(:,5);
    pq = 1 - std(power) / mean(abs(power));
end

function ms = calculate_mode_stability(data)
    % Calculate mode stability index
    modes = data(:,7);
    transitions = sum(diff(modes) ~= 0);
    ms = 1 - transitions / length(modes);
end 