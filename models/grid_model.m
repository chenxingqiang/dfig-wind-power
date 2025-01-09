classdef grid_model < handle
    % GRID_MODEL Power grid model
    %   Implements grid dynamics for voltage and frequency
    
    properties (Access = private)
        % Grid parameters
        params
        
        % State variables
        voltage         % Grid voltage
        frequency      % Grid frequency
        phase         % Voltage phase angle
        power_flow    % Active and reactive power flow
        
        % Grid inertia and damping
        total_inertia
        damping_coefficient
    end
    
    methods
        function obj = grid_model(params)
            % Constructor
            obj.params = params;
            obj.initialize_states();
            obj.initialize_grid_parameters();
        end
        
        function [states] = update(obj, power_injection)
            % Update grid states
            % power_injection: struct with P and Q from all sources
            
            % 1. Update frequency dynamics
            obj.update_frequency(power_injection.P);
            
            % 2. Update voltage dynamics
            obj.update_voltage(power_injection.Q);
            
            % 3. Update power flow
            obj.update_power_flow(power_injection);
            
            % 4. Get current states
            states = obj.get_states();
        end
        
        function fault = apply_fault(obj, fault_params)
            % Apply grid fault
            % fault_params: struct with fault type and severity
            
            switch fault_params.type
                case 'voltage_dip'
                    obj.voltage = obj.voltage * fault_params.remaining_voltage;
                    
                case 'frequency_deviation'
                    obj.frequency = obj.params.nominal_frequency + ...
                                  fault_params.deviation;
                    
                case 'phase_jump'
                    obj.phase = obj.phase + fault_params.angle_jump;
            end
            
            fault = obj.get_states();
        end
    end
    
    methods (Access = private)
        function initialize_states(obj)
            % Initialize state variables
            obj.voltage = 1.0;  % p.u.
            obj.frequency = obj.params.nominal_frequency;
            obj.phase = 0;
            obj.power_flow = struct('P', 0, 'Q', 0);
        end
        
        function initialize_grid_parameters(obj)
            % Initialize grid dynamic parameters
            obj.total_inertia = obj.params.base_inertia;
            obj.damping_coefficient = obj.params.base_damping;
        end
        
        function update_frequency(obj, active_power)
            % Update frequency dynamics
            
            % Power imbalance
            delta_P = sum(active_power) - obj.power_flow.P;
            
            % Swing equation
            d2delta = (delta_P - obj.damping_coefficient * obj.frequency) / ...
                     obj.total_inertia;
            
            % Update frequency
            obj.frequency = obj.frequency + d2delta * obj.params.Ts;
            
            % Update phase
            obj.phase = obj.phase + 2*pi*obj.frequency * obj.params.Ts;
        end
        
        function update_voltage(obj, reactive_power)
            % Update voltage dynamics
            
            % Reactive power imbalance
            delta_Q = sum(reactive_power) - obj.power_flow.Q;
            
            % Simplified voltage dynamics
            dV = obj.params.voltage_sensitivity * delta_Q;
            
            % Update voltage
            obj.voltage = obj.voltage + dV * obj.params.Ts;
            
            % Limit voltage
            obj.voltage = min(max(obj.voltage, ...
                obj.params.min_voltage), obj.params.max_voltage);
        end
        
        function update_power_flow(obj, power_injection)
            % Update power flow
            
            % Sum all injected powers
            obj.power_flow.P = sum(power_injection.P);
            obj.power_flow.Q = sum(power_injection.Q);
            
            % Apply transmission losses
            obj.power_flow.P = obj.power_flow.P * (1 - obj.params.loss_factor);
            obj.power_flow.Q = obj.power_flow.Q * (1 - obj.params.loss_factor);
        end
        
        function states = get_states(obj)
            % Get current states
            states = struct(...
                'voltage', obj.voltage,...
                'frequency', obj.frequency,...
                'phase', obj.phase,...
                'power_flow', obj.power_flow...
            );
        end
    end
end 