function [mode, params] = mode_switch(state)
% MODE_SWITCH Mode switching control for DFIG wind power system
%   Implements dynamic mode switching between grid-following and grid-forming

%% Input Validation
validateattributes(state.grid_voltage, {'numeric'}, {'scalar', '>=', 0, '<=', 1.5});
validateattributes(state.grid_frequency, {'numeric'}, {'scalar', '>=', 45, '<=', 55});

%% Mode Detection
% Check grid conditions
is_voltage_fault = state.grid_voltage < params.voltage_threshold;
is_freq_fault = abs(state.grid_frequency - params.nominal_frequency) > ...
    params.freq_threshold;
is_soc_critical = state.soc < params.min_soc || state.soc > params.max_soc;

%% Mode Selection
if is_voltage_fault || is_freq_fault
    if is_soc_critical
        mode = 'EMERGENCY';
        params = get_emergency_params();
    else
        mode = 'GRID_FORMING';
        params = get_grid_forming_params(state);
    end
else
    mode = 'GRID_FOLLOWING';
    params = get_grid_following_params(state);
end

%% Smooth Transition
params = apply_transition_ramp(params, state.previous_mode, mode);

end

%% Parameter Generation Functions
function params = get_emergency_params()
    % Parameters for emergency operation
    params = struct(...
        'current_limit', 1.0,...        % Reduced current limit
        'power_limit', 0.5,...          % Reduced power limit
        'ramp_rate', 0.05,...           % Slower ramp rate
        'control_mode', 'protective'...  % Protective control mode
    );
end

function params = get_grid_forming_params(state)
    % Parameters for grid-forming mode
    params = struct(...
        'voltage_ref', 1.0,...          % Nominal voltage reference
        'frequency_ref', 50,...         % Nominal frequency reference
        'droop_gain_v', 0.05,...        % Voltage droop gain
        'droop_gain_f', 0.02,...        % Frequency droop gain
        'virtual_inertia', 5.0,...      % Virtual inertia constant
        'current_limit', 1.2,...        % Maximum current limit
        'control_mode', 'voltage'...    % Voltage control mode
    );
end

function params = get_grid_following_params(state)
    % Parameters for grid-following mode
    params = struct(...
        'power_ref', calculate_power_reference(state),...
        'reactive_power_ref', calculate_reactive_reference(state),...
        'current_limit', 1.2,...        % Normal current limit
        'ramp_rate', 0.1,...           % Normal ramp rate
        'control_mode', 'power'...     % Power control mode
    );
end

%% Utility Functions
function params = apply_transition_ramp(params, old_mode, new_mode)
    % Apply ramping for smooth transition between modes
    if ~strcmp(old_mode, new_mode)
        % Calculate ramping coefficients
        ramp_time = 0.1;  % seconds
        ramp_steps = round(ramp_time / params.Ts);
        ramp_factor = (1:ramp_steps) / ramp_steps;
        
        % Store ramping information
        params.transition = struct(...
            'from_mode', old_mode,...
            'to_mode', new_mode,...
            'ramp_factor', ramp_factor,...
            'step', 1 ...
        );
    end
end

function P_ref = calculate_power_reference(state)
    % Calculate power reference based on wind speed and grid conditions
    
    % Available wind power
    P_available = 0.5 * params.air_density * params.rotor_area * ...
                 state.wind_speed^3 * params.power_coefficient;
    
    % Grid capacity limit
    P_grid_max = params.rated_power * state.grid_voltage;
    
    % Select minimum of available and grid capacity
    P_ref = min(P_available, P_grid_max);
end

function Q_ref = calculate_reactive_reference(state)
    % Calculate reactive power reference based on grid voltage
    
    % Voltage error
    delta_v = 1.0 - state.grid_voltage;
    
    % Reactive power support
    Q_ref = params.reactive_gain * delta_v * params.rated_power;
    
    % Limit reactive power
    Q_ref = min(max(Q_ref, -params.rated_power), params.rated_power);
end 