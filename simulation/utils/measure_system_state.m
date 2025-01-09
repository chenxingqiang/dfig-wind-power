function state = measure_system_state(v_grid, f_grid, i_rsc, i_gsc, soc)
%% System State Measurement
% Measures and processes system state variables
% Inputs:
%   v_grid - Grid voltage
%   f_grid - Grid frequency
%   i_rsc - RSC currents [d,q]
%   i_gsc - GSC currents [d,q]
%   soc - Energy storage SOC
% Outputs:
%   state - Structure containing processed system state

global dfig conv ess

%% Process Measurements
% Grid measurements
state.v_grid = v_grid;
state.f_grid = f_grid;

% Calculate frequency derivative
persistent f_prev t_prev
if isempty(f_prev)
    state.df_dt = 0;
else
    dt = 1e-4; % Sample time
    state.df_dt = (f_grid - f_prev) / dt;
end
f_prev = f_grid;

% Current measurements
state.i_rsc = i_rsc;
state.i_gsc = i_gsc;

% Power calculations
state.P_rsc = v_grid * i_rsc(1);
state.Q_rsc = v_grid * i_rsc(2);
state.P_gsc = v_grid * i_gsc(1);
state.Q_gsc = v_grid * i_gsc(2);

% Energy storage
state.soc = soc;
state.P_ess_avail = calculate_available_power(soc);

% Wind power
state.P_wind = estimate_wind_power();

%% Store Historical Data
% Update historical data buffer for LSTM
update_history_buffer(state);

end

%% Helper Functions
function P_avail = calculate_available_power(soc)
    % Calculate available power based on SOC
    global ess
    
    if soc > ess.SOCmax
        % Discharge only
        P_avail = -ess.Pn;
    elseif soc < ess.SOCmin
        % Charge only
        P_avail = ess.Pn;
    else
        % Both charge and discharge available
        P_avail = ess.Pn * (2 * (soc - 0.5));
    end
end

function P_wind = estimate_wind_power()
    % Estimate available wind power
    % This is a simplified model - in practice, use wind speed measurements
    global dfig
    
    % Example: Sinusoidal variation + noise
    t = now * 86400; % Convert to seconds
    base_power = 0.8 * dfig.Pn; % Base power level
    variation = 0.2 * dfig.Pn * sin(2*pi*t/3600); % Hourly variation
    noise = 0.05 * dfig.Pn * randn(); % Random fluctuations
    
    P_wind = base_power + variation + noise;
    P_wind = max(0, min(P_wind, dfig.Pn)); % Limit to rated power
end

function update_history_buffer(state)
    % Update historical data buffer for LSTM predictions
    persistent history
    if isempty(history)
        history = zeros(100, 5); % [v_grid, f_grid, P_wind, P_ess, soc]
    end
    
    % Shift buffer
    history(1:end-1,:) = history(2:end,:);
    
    % Add new data
    history(end,:) = [state.v_grid, state.f_grid, state.P_wind/1e6, ...
                      state.P_ess_avail/1e6, state.soc];
    
    % Store in state
    state.history = history;
end 