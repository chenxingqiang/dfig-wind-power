%% DFIG Wind Power System with Energy Storage - Main Simulation
% This simulation implements fault ride-through control, primary frequency
% control, and dynamic mode switching with deep learning assistance

clear;
clc;
close all;

%% Simulation Parameters
Ts = 1e-4;  % Sample time (s)
Tend = 10;  % End time (s)
t = 0:Ts:Tend;
N = length(t);

% Initialize system parameters
init_system;

%% Simulation Variables
% State variables
v_grid = zeros(N,1);    % Grid voltage
f_grid = zeros(N,1);    % Grid frequency
i_rsc = zeros(N,2);     % RSC currents [d,q]
i_gsc = zeros(N,2);     % GSC currents [d,q]
soc = zeros(N,1);       % ESS state of charge
mode = zeros(N,1);      % System operation mode

% Control references
P_ref = zeros(N,1);     % Active power reference
Q_ref = zeros(N,1);     % Reactive power reference
v_dc_ref = zeros(N,1);  % DC-link voltage reference

%% Simulation Loop
for k = 1:N-1
    % Measure system state
    state = measure_system_state(v_grid(k), f_grid(k), i_rsc(k,:), i_gsc(k,:), soc(k));
    
    % LSTM prediction for next time step
    [P_pred, Q_pred] = lstm_predict(state);
    
    % Mode detection and switching
    mode(k+1) = mode_switch(state);
    
    % Control execution based on mode
    switch mode(k+1)
        case 1 % GRID_FOLLOWING
            [P_ref(k+1), Q_ref(k+1)] = grid_following_control(state, P_pred, Q_pred);
        case 2 % GRID_FORMING
            [P_ref(k+1), Q_ref(k+1)] = grid_forming_control(state);
        case 3 % EMERGENCY
            [P_ref(k+1), Q_ref(k+1)] = emergency_control(state);
    end
    
    % Apply control references
    [v_grid(k+1), f_grid(k+1), i_rsc(k+1,:), i_gsc(k+1,:), soc(k+1)] = ...
        system_update(P_ref(k+1), Q_ref(k+1), state);
    
    % Log data
    log_data(k, state, mode(k+1), P_ref(k+1), Q_ref(k+1));
end

%% Plot Results
plot_simulation_results(t, v_grid, f_grid, i_rsc, i_gsc, soc, mode); 