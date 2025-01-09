classdef ess_model < handle
    % ESS_MODEL Energy Storage System model
    %   Implements battery dynamics and power conversion
    
    properties (Access = private)
        % System parameters
        params
        
        % State variables
        soc           % State of charge
        voltage       % Battery voltage
        current       % Battery current
        temperature   % Battery temperature
        
        % Power converter
        converter
        
        % Thermal model parameters
        thermal_resistance
        thermal_capacitance
        ambient_temp = 25  % °C
    end
    
    methods
        function obj = ess_model(params)
            % Constructor
            obj.params = params;
            obj.initialize_states();
            obj.initialize_thermal_model();
        end
        
        function set_converter(obj, converter)
            % Set power converter interface
            obj.converter = converter;
        end
        
        function [states] = update(obj, power_ref)
            % Update ESS states
            % power_ref: reference power from control system
            
            % 1. Update power conversion
            [v_conv, i_conv] = obj.converter.update(power_ref, obj.voltage);
            
            % 2. Update battery states
            obj.update_electrical(v_conv, i_conv);
            
            % 3. Update thermal model
            obj.update_thermal();
            
            % 4. Get current states
            states = obj.get_states();
        end
        
        function available = check_power_availability(obj, power_request)
            % Check if requested power is available
            if power_request > 0  % Discharge
                available = obj.soc > obj.params.min_soc && ...
                          abs(power_request) <= obj.params.rated_power;
            else  % Charge
                available = obj.soc < obj.params.max_soc && ...
                          abs(power_request) <= obj.params.rated_power;
            end
        end
    end
    
    methods (Access = private)
        function initialize_states(obj)
            % Initialize state variables
            obj.soc = 0.5;  % Start at 50% SOC
            obj.voltage = obj.params.rated_voltage;
            obj.current = 0;
            obj.temperature = obj.ambient_temp;
        end
        
        function initialize_thermal_model(obj)
            % Initialize thermal model parameters
            obj.thermal_resistance = 0.1;    % K/W
            obj.thermal_capacitance = 1000;  % J/K
        end
        
        function update_electrical(obj, v_conv, i_conv)
            % Update electrical states
            
            % Current calculation
            obj.current = i_conv;
            
            % Voltage calculation (including internal resistance)
            obj.voltage = obj.calculate_ocv(obj.soc) - ...
                         obj.current * obj.params.internal_resistance;
            
            % SOC update
            dsoc = -obj.current * obj.params.Ts / obj.params.capacity;
            obj.soc = obj.soc + dsoc;
            
            % Limit SOC
            obj.soc = min(max(obj.soc, obj.params.min_soc), ...
                         obj.params.max_soc);
        end
        
        function update_thermal(obj)
            % Update thermal model
            
            % Power loss calculation
            P_loss = obj.current^2 * obj.params.internal_resistance;
            
            % Temperature dynamics
            dT = (P_loss - (obj.temperature - obj.ambient_temp) / ...
                  obj.thermal_resistance) / obj.thermal_capacitance;
            
            obj.temperature = obj.temperature + dT * obj.params.Ts;
        end
        
        function ocv = calculate_ocv(obj, soc)
            % Calculate open circuit voltage based on SOC
            % Simplified linear relationship
            ocv = obj.params.rated_voltage * (0.8 + 0.2 * soc);
        end
        
        function states = get_states(obj)
            % Get current states
            states = struct(...
                'soc', obj.soc,...
                'voltage', obj.voltage,...
                'current', obj.current,...
                'temperature', obj.temperature,...
                'power_available', obj.params.rated_power * ...
                    (obj.soc - obj.params.min_soc) / ...
                    (obj.params.max_soc - obj.params.min_soc)...
            );
        end
    end
end 