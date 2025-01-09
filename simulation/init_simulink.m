%% Initialize Simulink Model Parameters
% Initialization script for DFIG wind power system with energy storage

%% Simulation Parameters
Ts = 1e-4;          % Sample time (s)
Tend = 10;          % End time (s)
powerunit = 1e6;    % Power base unit (W)

%% DFIG Parameters
dfig.Pn = 2e6;      % Rated power (W)
dfig.Vn = 690;      % Rated voltage (V)
dfig.fn = 50;       % Rated frequency (Hz)
dfig.poles = 4;     % Number of poles
dfig.H = 3.5;       % Inertia constant (s)
dfig.Rs = 0.00706;  % Stator resistance (pu)
dfig.Rr = 0.005;    % Rotor resistance (pu)
dfig.Ls = 3.07;     % Stator inductance (pu)
dfig.Lr = 3.056;    % Rotor inductance (pu)
dfig.Lm = 2.9;      % Mutual inductance (pu)
dfig.wr_rated = 2*pi*50*(1-0.3);  % Rated rotor speed (rad/s)

%% Power Converter Parameters
conv.Vdc = 1200;    % DC-link voltage (V)
conv.C = 0.1;       % DC-link capacitance (F)
conv.fsw = 2500;    % Switching frequency (Hz)
conv.Imax = 1.2;    % Maximum current (pu)

% Current controller parameters
conv.Kp_i = 0.3;    % Current controller P gain
conv.Ki_i = 8;      % Current controller I gain
conv.Kp_v = 0.1;    % Voltage controller P gain
conv.Ki_v = 5;      % Voltage controller I gain

%% Energy Storage System Parameters
ess.Pn = 0.5e6;     % Rated power (W)
ess.En = 1e6;       % Rated energy capacity (Wh)
ess.SOCmin = 0.1;   % Minimum SOC
ess.SOCmax = 0.9;   % Maximum SOC
ess.eta = 0.95;     % Round-trip efficiency
ess.tau = 0.1;      % Time constant (s)
ess.enabled = 1;    % ESS enable flag
ess.soc_init = 0.8; % Initial SOC

%% Grid Parameters
grid.Vn = 690;      % Rated voltage (V)
grid.fn = 50;       % Rated frequency (Hz)
grid.SCR = 10;      % Short circuit ratio
grid.X_R = 10;      % X/R ratio
grid.Zbase = grid.Vn^2/dfig.Pn;  % Base impedance

% Grid sequence impedances for asymmetrical fault
grid.Z1 = grid.Zbase/grid.SCR;  % Positive sequence impedance
grid.Z2 = grid.Z1;              % Negative sequence impedance
grid.Z0 = 3*grid.Z1;            % Zero sequence impedance

%% Control Parameters
% FRT Control
ctrl.frt.Vmin = 0.2;     % Minimum voltage for FRT (pu)
ctrl.frt.Tmax = 0.15;    % Maximum FRT duration (s)
ctrl.frt.Kp_i = 0.5;     % Current controller P gain
ctrl.frt.Ki_i = 50;      % Current controller I gain
ctrl.frt.Kp_v = 2.0;     % Voltage controller P gain
ctrl.frt.Ki_v = 100;     % Voltage controller I gain
ctrl.frt.max_Q = 1.2;    % Maximum reactive power in pu

% Frequency Control
ctrl.freq.db = 0.0002;   % Frequency deadband (pu)
ctrl.freq.Kdroop = 0.05; % Droop coefficient
ctrl.freq.Tg = 0.1;      % Governor time constant (s)
ctrl.freq.Ki_f = 20;     % Frequency integral gain
ctrl.freq.max_P = 1.0;   % Maximum active power support in pu

% Mode Switching
ctrl.mode.Vth = 0.9;     % Voltage threshold for mode switching
ctrl.mode.fth = 0.02;    % Frequency threshold
ctrl.mode.Tdelay = 0.05; % Mode switching delay (s)

%% Load Parameters
load.Pn = dfig.Pn;    % Rated load power same as DFIG
load.Qn = 0.2*dfig.Pn;% Rated reactive power 20% of active
load.time = [0 5 5.1 10];   % Time points for load change
load.values = [0.6 0.6 1.0 1.0];  % Load profile in pu

%% Fault Parameters
fault.time = [0 3 3.15 10];  % Fault timing
% Single phase to ground fault
fault.Va = [1.0 0.2 1.0 1.0];  % Faulted phase
fault.Vb = [1.0 1.0 1.0 1.0];  % Healthy phase
fault.Vc = [1.0 1.0 1.0 1.0];  % Healthy phase
fault.type = 1;  % 1: Single phase to ground

%% Save Parameters
save('model_params.mat', 'dfig', 'conv', 'ess', 'grid', 'ctrl', 'load', 'fault'); 