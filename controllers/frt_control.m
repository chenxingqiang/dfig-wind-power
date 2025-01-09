function [dfig_refs, ess_refs] = frt_control(state, predictions, params)
% FRT_CONTROL Fault ride-through control for DFIG wind power system
%   Implements coordinated control of RSC, GSC and ESS during grid faults

%% Input Validation
validateattributes(state.grid_voltage, {'numeric'}, {'scalar', '>=', 0, '<=', 1.5});

%% RSC Current Control
[Id_ref, Iq_ref] = rsc_current_control(state, params);

%% GSC Reactive Power Control
[Pgsc_ref, Qgsc_ref] = gsc_voltage_support(state, params);

%% ESS Support Control
[Pess_ref, Qess_ref] = ess_frt_support(state, predictions, params);

%% Prepare Output References
dfig_refs = struct(...
    'Id_ref', Id_ref,...
    'Iq_ref', Iq_ref,...
    'Pgsc_ref', Pgsc_ref,...
    'Qgsc_ref', Qgsc_ref...
);

ess_refs = struct(...
    'P_ref', Pess_ref,...
    'Q_ref', Qess_ref...
);

end

%% RSC Current Control
function [Id_ref, Iq_ref] = rsc_current_control(state, params)
    % Current limiting during fault
    if state.grid_voltage < params.voltage_threshold
        % Calculate maximum allowable current
        Id_max = params.current_limit * params.rated_current;
        Iq_max = params.current_limit * params.rated_current;
        
        % Calculate required currents
        Id_required = calculate_active_current(state);
        Iq_required = calculate_reactive_current(state);
        
        % Apply current limits
        Id_ref = min(max(-Id_max, Id_required), Id_max);
        Iq_ref = min(max(-Iq_max, Iq_required), Iq_max);
    else
        % Normal operation
        Id_ref = calculate_active_current(state);
        Iq_ref = calculate_reactive_current(state);
    end
end

%% GSC Voltage Support
function [Pgsc_ref, Qgsc_ref] = gsc_voltage_support(state, params)
    % Calculate voltage deviation
    delta_v = params.voltage_threshold - state.grid_voltage;
    
    if delta_v > 0
        % Calculate reactive power reference
        Qgsc_ref = params.reactive_gain * delta_v * params.rated_power;
        % Limit reactive power
        Qgsc_ref = min(Qgsc_ref, params.rated_power);
        
        % Calculate active power considering DC-link stability
        Pgsc_ref = calculate_dc_link_power(state);
    else
        % Normal operation
        Qgsc_ref = 0;
        Pgsc_ref = calculate_dc_link_power(state);
    end
end

%% ESS FRT Support
function [Pess_ref, Qess_ref] = ess_frt_support(state, predictions, params)
    % Check SOC limits
    if state.soc < params.min_soc || state.soc > params.max_soc
        Pess_ref = 0;
        Qess_ref = 0;
        return;
    end
    
    % Calculate required support based on LSTM predictions
    P_required = predictions.power_demand * predictions.confidence;
    
    % Calculate reactive power support
    delta_v = params.voltage_threshold - state.grid_voltage;
    if delta_v > 0
        Qess_ref = params.ess_reactive_gain * delta_v * params.ess_rated_power;
        % Limit reactive power
        Qess_ref = min(Qess_ref, params.ess_rated_power);
    else
        Qess_ref = 0;
    end
    
    % Calculate active power support
    Pess_ref = min(P_required, params.ess_rated_power);
end

%% Utility Functions
function Id = calculate_active_current(state)
    % Calculate active current based on power reference and voltage
    Id = state.power_ref / (state.grid_voltage * params.base_voltage);
end

function Iq = calculate_reactive_current(state)
    % Calculate reactive current based on reactive power reference and voltage
    Iq = state.reactive_power_ref / (state.grid_voltage * params.base_voltage);
end

function Pdc = calculate_dc_link_power(state)
    % Calculate power needed to maintain DC-link voltage
    Pdc = state.dc_power_ref;
end 