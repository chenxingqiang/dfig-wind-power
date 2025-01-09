classdef dfig_model < handle
    % DFIG_MODEL Double-fed induction generator model
    %   Implements DFIG dynamics and control interfaces
    
    properties (Access = private)
        % Machine parameters
        params
        
        % State variables
        rotor_speed
        rotor_angle
        stator_current
        rotor_current
        
        % Control interfaces
        rsc  % Rotor-side converter
        gsc  % Grid-side converter
    end
    
    methods
        function obj = dfig_model(params)
            % Constructor
            obj.params = params;
            obj.initialize_states();
        end
        
        function set_converters(obj, rsc, gsc)
            % Set converter interfaces
            obj.rsc = rsc;
            obj.gsc = gsc;
        end
        
        function [states] = update(obj, inputs)
            % Update DFIG states
            % inputs: grid voltage, wind speed, control references
            
            % 1. Update mechanical system
            obj.update_mechanical(inputs.wind_speed);
            
            % 2. Update electrical system
            obj.update_electrical(inputs.grid_voltage);
            
            % 3. Get current states
            states = obj.get_states();
        end
    end
    
    methods (Access = private)
        function initialize_states(obj)
            % Initialize state variables
            obj.rotor_speed = obj.params.rated_speed;
            obj.rotor_angle = 0;
            obj.stator_current = zeros(2,1);
            obj.rotor_current = zeros(2,1);
        end
        
        function update_mechanical(obj, wind_speed)
            % Update mechanical system states
            % Implement wind turbine aerodynamics
            Tm = obj.calculate_wind_torque(wind_speed);
            
            % Mechanical dynamics
            dwr = (Tm - obj.calculate_electrical_torque()) / obj.params.inertia;
            obj.rotor_speed = obj.rotor_speed + dwr * obj.params.Ts;
            obj.rotor_angle = obj.rotor_angle + obj.rotor_speed * obj.params.Ts;
        end
        
        function update_electrical(obj, grid_voltage)
            % Update electrical system states
            % Implement DFIG electrical equations
            
            % Get converter references
            [Vr_ref, Vs_ref] = obj.get_converter_refs();
            
            % Update currents
            obj.update_currents(Vr_ref, Vs_ref, grid_voltage);
        end
        
        function Te = calculate_electrical_torque(obj)
            % Calculate electrical torque
            Te = 1.5 * obj.params.poles/2 * obj.params.Lm * ...
                 (obj.stator_current(2)*obj.rotor_current(1) - ...
                  obj.stator_current(1)*obj.rotor_current(2));
        end
        
        function Tm = calculate_wind_torque(obj, wind_speed)
            % Calculate wind turbine torque
            if wind_speed < obj.params.cut_in_speed || ...
               wind_speed > obj.params.cut_out_speed
                Tm = 0;
                return;
            end
            
            % Power coefficient calculation
            lambda = obj.rotor_speed * obj.params.rotor_radius / wind_speed;
            Cp = obj.calculate_power_coefficient(lambda);
            
            % Torque calculation
            Pm = 0.5 * obj.params.air_density * pi * ...
                 obj.params.rotor_radius^2 * wind_speed^3 * Cp;
            Tm = Pm / obj.rotor_speed;
        end
        
        function [Vr_ref, Vs_ref] = get_converter_refs(obj)
            % Get voltage references from converters
            Vr_ref = obj.rsc.get_voltage_ref(obj.get_states());
            Vs_ref = obj.gsc.get_voltage_ref(obj.get_states());
        end
        
        function update_currents(obj, Vr_ref, Vs_ref, grid_voltage)
            % Update stator and rotor currents
            % Implement DFIG electrical equations in dq frame
            
            % Stator voltage equations
            Vs_dq = grid_voltage * exp(1j * obj.rotor_angle);
            Is_dq = obj.calculate_stator_current(Vs_dq, Vr_ref);
            
            % Rotor voltage equations
            Vr_dq = Vr_ref * exp(-1j * obj.params.slip * obj.rotor_angle);
            Ir_dq = obj.calculate_rotor_current(Vr_dq, Is_dq);
            
            % Update current states
            obj.stator_current = [real(Is_dq); imag(Is_dq)];
            obj.rotor_current = [real(Ir_dq); imag(Ir_dq)];
        end
        
        function states = get_states(obj)
            % Get current states
            states = struct(...
                'rotor_speed', obj.rotor_speed,...
                'rotor_angle', obj.rotor_angle,...
                'stator_current', obj.stator_current,...
                'rotor_current', obj.rotor_current...
            );
        end
    end
end 