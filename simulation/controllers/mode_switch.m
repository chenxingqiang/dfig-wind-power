function [mode, transition_params] = mode_switch(state)
%% Mode Switching Control
% Implements dynamic mode switching based on grid conditions and system states
% Inputs:
%   state - Current system state
% Outputs:
%   mode - Selected operation mode
%   transition_params - Parameters for smooth mode transition

global ctrl

%% Mode Definitions
MODE_GRID_FOLLOWING = 1;
MODE_GRID_FORMING = 2;
MODE_EMERGENCY = 3;

%% Grid Condition Assessment
v_grid = state.v_grid;
f_grid = state.f_grid;
soc = state.soc;

% Check voltage condition
v_normal = v_grid >= ctrl.mode.Vth;

% Check frequency condition
f_dev = abs(f_grid - 50)/50;
f_normal = f_dev <= ctrl.mode.fth;

% Check SOC condition
soc_normal = (soc >= 0.2) && (soc <= 0.8);

%% Mode Selection Logic
if v_normal && f_normal
    % Normal grid conditions
    if soc_normal
        mode = MODE_GRID_FOLLOWING;
    else
        mode = MODE_GRID_FORMING;
    end
else
    % Abnormal grid conditions
    if ~v_normal && ~f_normal
        mode = MODE_EMERGENCY;
    elseif ~v_normal
        if soc_normal
            mode = MODE_GRID_FORMING;
        else
            mode = MODE_EMERGENCY;
        end
    else % ~f_normal
        if soc_normal
            mode = MODE_GRID_FORMING;
        else
            mode = MODE_EMERGENCY;
        end
    end
end

%% Transition Parameters
transition_params = struct();

switch mode
    case MODE_GRID_FOLLOWING
        transition_params.ramp_rate = 1.0;  % Full ramp rate
        transition_params.delay = 0;        % No delay
        
    case MODE_GRID_FORMING
        transition_params.ramp_rate = 0.5;  % Half ramp rate
        transition_params.delay = ctrl.mode.Tdelay;
        
    case MODE_EMERGENCY
        transition_params.ramp_rate = 0.2;  % Slow ramp rate
        transition_params.delay = 2*ctrl.mode.Tdelay;
end

% Add mode-specific control parameters
transition_params.Kp = get_mode_gains(mode, 'Kp');
transition_params.Ki = get_mode_gains(mode, 'Ki');
transition_params.voltage_ref = get_voltage_ref(mode, v_grid);
transition_params.frequency_ref = get_frequency_ref(mode, f_grid);

end

%% Helper Functions
function gain = get_mode_gains(mode, gain_type)
    % Returns control gains based on operation mode
    switch mode
        case 1 % GRID_FOLLOWING
            if strcmp(gain_type, 'Kp')
                gain = 0.5;
            else % Ki
                gain = 50;
            end
        case 2 % GRID_FORMING
            if strcmp(gain_type, 'Kp')
                gain = 0.8;
            else % Ki
                gain = 80;
            end
        case 3 % EMERGENCY
            if strcmp(gain_type, 'Kp')
                gain = 1.0;
            else % Ki
                gain = 100;
            end
    end
end

function v_ref = get_voltage_ref(mode, v_grid)
    % Returns voltage reference based on operation mode
    switch mode
        case 1 % GRID_FOLLOWING
            v_ref = v_grid;
        case 2 % GRID_FORMING
            v_ref = 1.0;
        case 3 % EMERGENCY
            v_ref = 0.9;
    end
end

function f_ref = get_frequency_ref(mode, f_grid)
    % Returns frequency reference based on operation mode
    switch mode
        case 1 % GRID_FOLLOWING
            f_ref = f_grid;
        case 2 % GRID_FORMING
            f_ref = 50.0;
        case 3 % EMERGENCY
            f_ref = 49.5;
    end
end 