function [dfig_refs, ess_refs] = freq_control(state, predictions, params)
% FREQ_CONTROL Frequency control for DFIG wind power system
%   Implements coordinated frequency control with virtual inertia and ESS support

%% Input Validation
validateattributes(state.grid_frequency, {'numeric'}, {'scalar', '>=', 45, '<=', 55});

%% Calculate Frequency Deviation and Rate of Change
delta_f = state.grid_frequency - params.nominal_frequency;
df_dt = calculate_frequency_derivative(state);

%% Virtual Inertia Response
P_inertia = virtual_inertia_response(df_dt, params);

%% Primary Frequency Control
[P_dfig, P_ess] = primary_freq_control(delta_f, state, params);

%% DRL-based Power Optimization
if params.enable_deep_learning
    [P_dfig, P_ess] = optimize_power_distribution(...
        P_dfig, P_ess, state, predictions);
end

%% Prepare Output References
dfig_refs = struct(...
    'P_ref', P_dfig + P_inertia,...
    'operation_mode', 'FREQUENCY_CONTROL'...
);

ess_refs = struct(...
    'P_ref', P_ess,...
    'operation_mode', 'FREQUENCY_SUPPORT'...
);

end

%% Virtual Inertia Response
function P_inertia = virtual_inertia_response(df_dt, params)
    % Calculate inertial power response
    P_inertia = 2 * params.virtual_inertia * params.rated_power * df_dt;
    
    % Apply power limits
    P_inertia = min(max(-params.max_inertia_power, P_inertia), ...
                    params.max_inertia_power);
end

%% Primary Frequency Control
function [P_dfig, P_ess] = primary_freq_control(delta_f, state, params)
    % Calculate DFIG droop response
    P_dfig_droop = -params.droop_gain_dfig * delta_f * params.rated_power;
    
    % Calculate available wind power
    P_available = calculate_available_power(state.wind_speed);
    
    % Limit DFIG power
    P_dfig = min(P_dfig_droop, P_available);
    
    % Calculate ESS droop response
    P_ess = -params.droop_gain_ess * delta_f * params.ess_rated_power;
    
    % Check ESS limits
    if state.soc < params.min_soc && P_ess < 0
        P_ess = 0;
    elseif state.soc > params.max_soc && P_ess > 0
        P_ess = 0;
    end
    
    % Apply ESS power limits
    P_ess = min(max(-params.ess_rated_power, P_ess), params.ess_rated_power);
end

%% DRL-based Power Optimization
function [P_dfig_opt, P_ess_opt] = optimize_power_distribution(...
    P_dfig, P_ess, state, predictions)
    
    % Prepare state for DRL agent
    drl_state = struct(...
        'delta_f', state.grid_frequency - params.nominal_frequency,...
        'df_dt', calculate_frequency_derivative(state),...
        'soc', state.soc,...
        'wind_speed', state.wind_speed,...
        'power_prediction', predictions.power_demand...
    );
    
    % Get optimal power distribution from DRL agent
    action = drl_agent.get_action(drl_state);
    
    % Apply DRL agent's decision
    P_dfig_opt = P_dfig * action.dfig_factor;
    P_ess_opt = P_ess * action.ess_factor;
    
    % Ensure power balance
    total_power = P_dfig + P_ess;
    total_power_opt = P_dfig_opt + P_ess_opt;
    
    if abs(total_power_opt - total_power) > params.power_tolerance
        % Adjust to maintain power balance
        scale_factor = total_power / total_power_opt;
        P_dfig_opt = P_dfig_opt * scale_factor;
        P_ess_opt = P_ess_opt * scale_factor;
    end
end

%% Utility Functions
function df_dt = calculate_frequency_derivative(state)
    % Calculate frequency derivative using moving average filter
    persistent freq_buffer time_buffer
    
    if isempty(freq_buffer)
        freq_buffer = zeros(1, params.freq_buffer_size);
        time_buffer = zeros(1, params.freq_buffer_size);
    end
    
    % Update buffers
    freq_buffer = [state.grid_frequency, freq_buffer(1:end-1)];
    time_buffer = [state.time, time_buffer(1:end-1)];
    
    % Calculate derivative
    df_dt = (freq_buffer(1) - freq_buffer(end)) / ...
            (time_buffer(1) - time_buffer(end));
end

function P_available = calculate_available_power(wind_speed)
    % Calculate available wind power using power curve
    if wind_speed < params.cut_in_speed || wind_speed > params.cut_out_speed
        P_available = 0;
    else
        P_available = 0.5 * params.air_density * params.rotor_area * ...
                     wind_speed^3 * params.power_coefficient;
    end
end 