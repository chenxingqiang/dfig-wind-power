function [sys,x0,str,ts] = sfun_controller(t,x,u,flag,params)
%SFUN_CONTROLLER S-Function for Control System
% This S-function implements the control system including FRT, frequency
% control, and mode switching with enhanced support for asymmetrical faults

switch flag
    case 0 % Initialization
        [sys,x0,str,ts] = mdlInitializeSizes(params);
        
    case 2 % Discrete states
        sys = mdlUpdate(t,x,u,params);
        
    case 3 % Outputs
        sys = mdlOutputs(t,x,u,params);
        
    case {1, 4, 9} % Unused flags
        sys = [];
        
    otherwise % Unexpected flags
        error(['Unhandled flag = ',num2str(flag)]);
end

%% Function to initialize system
function [sys,x0,str,ts] = mdlInitializeSizes(params)
% Call simsizes for a sizes structure
sizes = simsizes;

sizes.NumContStates  = 0;
sizes.NumDiscStates  = 15;    % [mode PI_states predictions sequence_components]
sizes.NumOutputs     = 11;    % [P_ref Q_ref vdr vqr mode v_dc_ref P_ess Q_ess Va_comp Vb_comp Vc_comp]
sizes.NumInputs      = 17;    % [v_grid f_grid ids iqs idr iqr wr soc P_wind Te Ps Qs v_dc i_dc Va Vb Vc]
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);

% Initialize state vector
x0 = zeros(15,1);
x0(1) = 1;  % Initial mode: GRID_FOLLOWING

str = [];                    % Set str to an empty matrix
ts  = [params.Ts 0];        % Sample time

%% Function to update discrete states
function sys = mdlUpdate(t,x,u,params)
% State variables
mode = x(1);
pi_states = x(2:6);
predictions = x(7:12);
seq_comp = x(13:15);  % Sequence components states

% Input variables
v_grid = u(1); f_grid = u(2);
ids = u(3); iqs = u(4);
idr = u(5); iqr = u(6);
wr = u(7); soc = u(8);
P_wind = u(9); Te = u(10);
Ps = u(11); Qs = u(12);
v_dc = u(13); i_dc = u(14);
Va = u(15); Vb = u(16); Vc = u(17);

% Calculate sequence components
[V0, V1, V2] = calc_sequence_components(Va, Vb, Vc);
seq_comp_new = [V0; V1; V2];

% Mode switching logic with enhanced unbalance detection
next_mode = mode_switch(v_grid, f_grid, soc, V2/V1, params);

% Update PI controller states with sequence compensation
pi_states_new = update_pi_states(pi_states, mode, u, seq_comp_new, params);

% Update predictions with enhanced estimation
predictions_new = update_predictions(predictions, u, seq_comp_new, params);

sys = [next_mode; pi_states_new; predictions_new; seq_comp_new];

%% Function to compute outputs
function sys = mdlOutputs(t,x,u,params)
% State variables
mode = x(1);
pi_states = x(2:6);
predictions = x(7:12);
seq_comp = x(13:15);

% Input variables
v_grid = u(1); f_grid = u(2);
ids = u(3); iqs = u(4);
idr = u(5); iqr = u(6);
wr = u(7); soc = u(8);
P_wind = u(9); Te = u(10);
Ps = u(11); Qs = u(12);
v_dc = u(13); i_dc = u(14);
Va = u(15); Vb = u(16); Vc = u(17);

% Execute control based on mode
switch mode
    case 1 % GRID_FOLLOWING
        [P_ref, Q_ref, vdr, vqr, v_dc_ref, P_ess, Q_ess, Va_comp, Vb_comp, Vc_comp] = ...
            grid_following_control(u, pi_states, predictions, seq_comp, params);
        
    case 2 % GRID_FORMING
        [P_ref, Q_ref, vdr, vqr, v_dc_ref, P_ess, Q_ess, Va_comp, Vb_comp, Vc_comp] = ...
            grid_forming_control(u, pi_states, predictions, seq_comp, params);
        
    case 3 % EMERGENCY
        [P_ref, Q_ref, vdr, vqr, v_dc_ref, P_ess, Q_ess, Va_comp, Vb_comp, Vc_comp] = ...
            emergency_control(u, pi_states, predictions, seq_comp, params);
end

sys = [P_ref; Q_ref; vdr; vqr; mode; v_dc_ref; P_ess; Q_ess; Va_comp; Vb_comp; Vc_comp];

%% Helper Functions
function [V0, V1, V2] = calc_sequence_components(Va, Vb, Vc)
% Calculate symmetrical components
a = exp(1j*2*pi/3);
A = [1 1 1; 1 a a^2; 1 a^2 a]/3;
V = A * [Va; Vb; Vc];
V0 = abs(V(1));  % Zero sequence
V1 = abs(V(2));  % Positive sequence
V2 = abs(V(3));  % Negative sequence

function next_mode = mode_switch(v_grid, f_grid, soc, VUF, params)
% Enhanced mode switching with unbalance factor
v_normal = v_grid >= params.ctrl.mode.Vth;
f_dev = abs(f_grid - params.dfig.fn)/params.dfig.fn;
f_normal = f_dev <= params.ctrl.mode.fth;
soc_normal = (soc >= 0.2) && (soc <= 0.8);
unbalance_normal = VUF <= 0.02;  % 2% unbalance threshold

% Mode selection logic
if v_normal && f_normal && unbalance_normal
    if soc_normal
        next_mode = 1; % GRID_FOLLOWING
    else
        next_mode = 2; % GRID_FORMING
    end
else
    if (~v_normal && ~f_normal) || ~unbalance_normal
        next_mode = 3; % EMERGENCY
    elseif ~v_normal || ~unbalance_normal
        if soc_normal
            next_mode = 2; % GRID_FORMING
        else
            next_mode = 3; % EMERGENCY
        end
    else % ~f_normal
        if soc_normal
            next_mode = 2; % GRID_FORMING
        else
            next_mode = 3; % EMERGENCY
        end
    end
end

function pi_states_new = update_pi_states(pi_states, mode, u, seq_comp, params)
% Update PI controller states with sequence compensation
Ts = params.Ts;

% Extract sequence components
V0 = seq_comp(1);
V1 = seq_comp(2);
V2 = seq_comp(3);

% Calculate voltage unbalance factor
VUF = V2/V1;

% Extract current values
ids_err = pi_states(1);
iqs_err = pi_states(2);
vdc_err = pi_states(3);
P_err = pi_states(4);
Q_err = pi_states(5);

% Update based on current errors and sequence components
switch mode
    case 1 % GRID_FOLLOWING
        % Add negative sequence compensation
        ids_err = ids_err + Ts * (u(3) - u(9)/u(1) + V2*0.1);
        iqs_err = iqs_err + Ts * (u(4) - u(12)/u(1) - V2*0.1);
        
    case 2 % GRID_FORMING
        % Add voltage unbalance compensation
        vdc_err = vdc_err + Ts * (u(13) - params.conv.Vdc*(1 + 0.1*VUF));
        P_err = P_err + Ts * (u(11) - u(9));
        Q_err = Q_err + Ts * (u(12) - V2*params.conv.Imax);
        
    case 3 % EMERGENCY
        % Reset integrators in emergency mode
        ids_err = 0;
        iqs_err = 0;
        vdc_err = 0;
        P_err = 0;
        Q_err = 0;
end

pi_states_new = [ids_err; iqs_err; vdc_err; P_err; Q_err];

function predictions_new = update_predictions(predictions, u, seq_comp, params)
% Update predictions with sequence component information
predictions_new = predictions;
predictions_new(1) = u(9);  % Use current wind power as prediction
predictions_new(2) = u(11); % Use current active power as prediction
predictions_new(3) = seq_comp(2); % Store positive sequence magnitude
predictions_new(4) = seq_comp(3); % Store negative sequence magnitude 