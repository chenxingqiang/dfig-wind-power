function [sys,x0,str,ts,simStateCompliance] = sfun_grid(t,x,u,flag,params)
% SFUN_GRID Grid model S-function for DFIG wind power system
%   Implements grid dynamics, fault simulation, and measurements

switch flag
    case 0
        % Initialization
        [sys,x0,str,ts,simStateCompliance] = mdlInitializeSizes(params);
    case 1
        % Derivatives
        sys = mdlDerivatives(t,x,u,params);
    case 3
        % Outputs
        sys = mdlOutputs(t,x,u,params);
    case 2, 4, 9
        % Unused flags
        sys = [];
    otherwise
        DAStudio.error('Simulink:blocks:unhandledFlag', num2str(flag));
end

function [sys,x0,str,ts,simStateCompliance] = mdlInitializeSizes(params)
% Initialize S-function sizes
sizes = simsizes;

% Number of continuous states (voltage magnitude, frequency)
sizes.NumContStates  = 2;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 6; % [V_magnitude, frequency, P_grid, Q_grid, fault_flag, phase_angle]
sizes.NumInputs      = 4; % [P_dfig, Q_dfig, P_ess, Q_ess]
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);

% Initial conditions [V_magnitude=1.0, frequency=50.0]
x0 = [1.0; 50.0];

str = [];

% Sample time: continuous
ts = [0 0];

% Compatibility
simStateCompliance = 'DefaultSimState';

function sys = mdlDerivatives(t,x,u,params)
% Calculate state derivatives

% Current states
V_mag = x(1);     % Grid voltage magnitude (pu)
freq = x(2);      % Grid frequency (Hz)

% Inputs
P_dfig = u(1);    % DFIG active power
Q_dfig = u(2);    % DFIG reactive power  
P_ess = u(3);     % ESS active power
Q_ess = u(4);     % ESS reactive power

% Grid parameters (default values)
if isempty(params)
    params = get_default_params();
end

% Total power injection
P_total = P_dfig + P_ess;
Q_total = Q_dfig + Q_ess;

% Check for fault conditions
fault_active = check_fault_condition(t, params);

% Grid dynamics
if fault_active
    % During fault: voltage drop
    dV_dt = -(V_mag - params.fault_voltage) / params.fault_time_constant;
    % Frequency disturbance
    df_dt = -params.fault_freq_dev / params.freq_time_constant;
else
    % Normal operation: voltage regulation
    V_ref = 1.0 + params.voltage_droop * Q_total;
    dV_dt = (V_ref - V_mag) / params.voltage_time_constant;
    
    % Frequency response to power imbalance
    P_load = params.nominal_load + params.load_variation * sin(2*pi*t/params.load_period);
    P_imbalance = P_total - P_load;
    df_dt = -P_imbalance / (params.system_inertia * params.rated_power);
end

% Apply limits
dV_dt = max(min(dV_dt, params.max_voltage_rate), -params.max_voltage_rate);
df_dt = max(min(df_dt, params.max_freq_rate), -params.max_freq_rate);

sys = [dV_dt; df_dt];

function sys = mdlOutputs(t,x,u,params)
% Calculate outputs

% States
V_mag = x(1);
freq = x(2);

% Inputs
P_dfig = u(1);
Q_dfig = u(2);
P_ess = u(3);
Q_ess = u(4);

% Default parameters
if isempty(params)
    params = get_default_params();
end

% Check fault status
fault_flag = check_fault_condition(t, params);

% Calculate grid power
P_grid = P_dfig + P_ess;
Q_grid = Q_dfig + Q_ess;

% Phase angle (simplified calculation)
phase_angle = 2 * pi * freq * t;

% Apply voltage limits
V_mag = max(min(V_mag, params.max_voltage), params.min_voltage);
freq = max(min(freq, params.max_frequency), params.min_frequency);

% Outputs: [V_magnitude, frequency, P_grid, Q_grid, fault_flag, phase_angle]
sys = [V_mag; freq; P_grid; Q_grid; fault_flag; phase_angle];

function fault_active = check_fault_condition(t, params)
% Check if fault is active based on time

fault_active = 0;

% Asymmetric fault at t = 2s for 0.15s
if t >= 2.0 && t <= 2.15
    fault_active = 1;
end

% Frequency disturbance at t = 5s for 1s
if t >= 5.0 && t <= 6.0
    fault_active = 2; % Different type of fault
end

function params = get_default_params()
% Default grid parameters

params = struct(...
    'rated_power', 2e6, ...           % Rated power (W)
    'nominal_voltage', 690, ...       % Nominal voltage (V)
    'nominal_frequency', 50, ...      % Nominal frequency (Hz)
    'system_inertia', 5.0, ...        % System inertia constant (s)
    'voltage_time_constant', 0.1, ... % Voltage time constant (s)
    'freq_time_constant', 0.05, ...   % Frequency time constant (s)
    'voltage_droop', 0.05, ...        % Voltage droop gain
    'fault_voltage', 0.2, ...         % Fault voltage level (pu)
    'fault_time_constant', 0.01, ...  % Fault time constant (s)
    'fault_freq_dev', -0.5, ...       % Frequency deviation during fault (Hz)
    'max_voltage', 1.2, ...           % Maximum voltage (pu)
    'min_voltage', 0.8, ...           % Minimum voltage (pu)
    'max_frequency', 52, ...          % Maximum frequency (Hz)
    'min_frequency', 48, ...          % Minimum frequency (Hz)
    'max_voltage_rate', 10, ...       % Maximum voltage change rate (pu/s)
    'max_freq_rate', 2, ...           % Maximum frequency change rate (Hz/s)
    'nominal_load', 1.8e6, ...        % Nominal load (W)
    'load_variation', 0.1e6, ...      % Load variation amplitude (W)
    'load_period', 10 ...             % Load variation period (s)
);
