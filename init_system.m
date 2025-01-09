% System Initialization
% Initialize DFIG wind power system with energy storage

%% Load Configuration
config;  % Load system configuration parameters

%% System Parameters
% DFIG Parameters
dfig_params = struct(...
    'rated_power', 2e6,  % 2MW
    'rated_voltage', 690,  % 690V
    'rated_speed', 1500,  % 1500rpm
    'poles', 4,  % 4 poles
    'inertia', 100  % kg*m^2
);

% Converter Parameters
converter_params = struct(...
    'rated_power', 0.3 * dfig_params.rated_power,  % 30% of DFIG power
    'dc_link_voltage', 1200,  % 1200V
    'switching_freq', 2500  % 2.5kHz
);

% Energy Storage Parameters
ess_params = struct(...
    'capacity', 0.25 * dfig_params.rated_power,  % 25% of DFIG power
    'rated_voltage', 800,  % 800V
    'min_soc', 0.2,  % 20%
    'max_soc', 0.9,  % 90%
    'response_time', 0.1  % 100ms
);

%% Control Parameters
% FRT Control
frt_params = struct(...
    'current_limit', 1.2,  % 1.2 p.u.
    'voltage_threshold', 0.85,  % 0.85 p.u.
    'reactive_gain', 2.0  % Kq
);

% Frequency Control
freq_params = struct(...
    'virtual_inertia', 5.0,  % H
    'droop_gain_dfig', 20,  % Kd_dfig
    'droop_gain_ess', 15,  % Kd_ess
    'freq_threshold', 0.5  % Hz
);

% Mode Switching
mode_params = struct(...
    'voltage_threshold', 0.85,  % p.u.
    'freq_threshold', 0.5,  % Hz
    'ramp_rate', 0.1  % p.u./s
);

%% Deep Learning Configuration
% LSTM Configuration
lstm_config = struct(...
    'input_size', 5,  % Number of input features
    'hidden_layers', [64, 32],
    'output_size', 1,
    'sequence_length', 100,
    'sample_time', 0.01  % 10ms
);

% DRL Configuration
drl_config = struct(...
    'state_dim', 5,
    'action_dim', 2,
    'reward_weights', struct(...
        'soc_optimization', 0.4,...
        'grid_support', 0.3,...
        'power_smoothing', 0.3...
    )
);

%% Initialize Components
% Initialize DFIG Model
dfig = init_dfig_model(dfig_params);

% Initialize Converters
[rsc, gsc] = init_converters(converter_params);

% Initialize Energy Storage
ess = init_ess_model(ess_params);

% Initialize Deep Learning Models
if enable_deep_learning
    lstm_model = init_lstm_model(lstm_config);
    drl_agent = init_drl_agent(drl_config);
end

% Initialize Data Logging
init_data_logging();

fprintf('System initialization completed.\n'); 