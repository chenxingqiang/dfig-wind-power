%% System Parameters Initialization
% Initialize parameters for DFIG wind power system with energy storage

%% DFIG Parameters
dfig = struct();
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

%% Power Converter Parameters
conv = struct();
conv.Vdc = 1200;    % DC-link voltage (V)
conv.C = 0.1;       % DC-link capacitance (F)
conv.fsw = 2500;    % Switching frequency (Hz)
conv.Imax = 1.2;    % Maximum current (pu)

%% Energy Storage System Parameters
ess = struct();
ess.Pn = 0.5e6;     % Rated power (W)
ess.En = 1e6;       % Rated energy capacity (Wh)
ess.SOCmin = 0.1;   % Minimum SOC
ess.SOCmax = 0.9;   % Maximum SOC
ess.eta = 0.95;     % Round-trip efficiency

%% Control Parameters
ctrl = struct();
% FRT Control
ctrl.frt.Vmin = 0.2;     % Minimum voltage for FRT (pu)
ctrl.frt.Tmax = 0.15;    % Maximum FRT duration (s)
ctrl.frt.Kp_i = 0.5;     % Current controller P gain
ctrl.frt.Ki_i = 50;      % Current controller I gain

% Frequency Control
ctrl.freq.db = 0.0002;   % Frequency deadband (pu)
ctrl.freq.Kdroop = 0.05; % Droop coefficient
ctrl.freq.Tg = 0.1;      % Governor time constant (s)

% Mode Switching
ctrl.mode.Vth = 0.9;     % Voltage threshold for mode switching
ctrl.mode.fth = 0.02;    % Frequency threshold
ctrl.mode.Tdelay = 0.05; % Mode switching delay (s)

%% Deep Learning Parameters
dl = struct();
% LSTM Configuration
dl.lstm.input_size = 5;
dl.lstm.hidden_size = 64;
dl.lstm.num_layers = 2;
dl.lstm.sequence_length = 100;

% DRL Configuration
dl.drl.state_dim = 8;
dl.drl.action_dim = 2;
dl.drl.hidden_dim = 128;
dl.drl.gamma = 0.99;     % Discount factor

%% Initialize Controllers
% Current Controllers
init_current_controllers();

% Voltage Controllers
init_voltage_controllers();

% Frequency Controllers
init_frequency_controllers();

% Deep Learning Models
init_dl_models(); 