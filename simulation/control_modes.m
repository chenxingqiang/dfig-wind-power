%% Control Mode Functions for DFIG Wind Power System with Enhanced Fault Support

function [P_ref, Q_ref, vdr, vqr, v_dc_ref, P_ess, Q_ess, Va_comp, Vb_comp, Vc_comp] = ...
    grid_following_control(u, pi_states, predictions, seq_comp, params)
% Grid Following Mode Control
% Normal operation with grid connection

% Input variables
v_grid = u(1); f_grid = u(2);
ids = u(3); iqs = u(4);
idr = u(5); iqr = u(6);
wr = u(7); soc = u(8);
P_wind = u(9); Te = u(10);
Ps = u(11); Qs = u(12);
v_dc = u(13); i_dc = u(14);
Va = u(15); Vb = u(16); Vc = u(17);

% Extract sequence components
V0 = seq_comp(1);
V1 = seq_comp(2);
V2 = seq_comp(3);

% Controller gains
Kp_i = params.ctrl.frt.Kp_i;
Ki_i = params.ctrl.frt.Ki_i;

% Current control with sequence compensation
ids_ref = P_wind / v_grid;
iqs_ref = 0;  % Unity power factor

% Add negative sequence compensation
ids_ref = ids_ref + V2 * 0.1;  % Compensate negative sequence
iqs_ref = iqs_ref - V2 * 0.1;  % Reactive support for unbalance

% PI control for currents
vdr = Kp_i * (ids_ref - ids) + Ki_i * pi_states(1);
vqr = Kp_i * (iqs_ref - iqs) + Ki_i * pi_states(2);

% Power references with frequency support
f_error = 50 - f_grid;
P_ref = P_wind + params.ctrl.freq.Kdroop * f_error;
Q_ref = V2 * params.conv.Imax;  % Reactive power for unbalance

% DC-link and ESS control
v_dc_ref = params.conv.Vdc;

% ESS support for frequency
P_ess = params.ctrl.freq.Kdroop * f_error;
Q_ess = V2 * params.ess.Pn/params.dfig.Pn;  % Normalized reactive support

% Voltage compensation
[Va_comp, Vb_comp, Vc_comp] = calculate_voltage_compensation(Va, Vb, Vc, V1, V2);

function [P_ref, Q_ref, vdr, vqr, v_dc_ref, P_ess, Q_ess, Va_comp, Vb_comp, Vc_comp] = ...
    grid_forming_control(u, pi_states, predictions, seq_comp, params)
% Grid Forming Mode Control
% Voltage and frequency regulation

% Input variables
v_grid = u(1); f_grid = u(2);
ids = u(3); iqs = u(4);
idr = u(5); iqr = u(6);
wr = u(7); soc = u(8);
P_wind = u(9); Te = u(10);
Ps = u(11); Qs = u(12);
v_dc = u(13); i_dc = u(14);
Va = u(15); Vb = u(16); Vc = u(17);

% Extract sequence components
V0 = seq_comp(1);
V1 = seq_comp(2);
V2 = seq_comp(3);

% Voltage control with unbalance compensation
v_error = 1 - V1;
Q_ref = params.ctrl.frt.Ki_v * v_error + V2 * params.conv.Imax;

% Frequency control with enhanced response
f_error = 50 - f_grid;
P_ref = params.ctrl.freq.Kdroop * f_error + ...
        params.ctrl.freq.Ki_f * pi_states(4);  % Add integral action

% Current control with sequence compensation
Kp_i = params.ctrl.frt.Kp_i;
Ki_i = params.ctrl.frt.Ki_i;

ids_ref = P_ref / v_grid + V2 * 0.2;  % Enhanced unbalance support
iqs_ref = -Q_ref / v_grid - V2 * 0.2;

vdr = Kp_i * (ids_ref - ids) + Ki_i * pi_states(1);
vqr = Kp_i * (iqs_ref - iqs) + Ki_i * pi_states(2);

% DC-link and ESS control with enhanced support
v_dc_ref = params.conv.Vdc * (1 + 0.1*(V2/V1));  % Increase for unbalance
P_ess = min(P_ref - P_wind, params.ess.Pn);
Q_ess = min(Q_ref, params.ess.Pn);

% Voltage compensation
[Va_comp, Vb_comp, Vc_comp] = calculate_voltage_compensation(Va, Vb, Vc, V1, V2);

function [P_ref, Q_ref, vdr, vqr, v_dc_ref, P_ess, Q_ess, Va_comp, Vb_comp, Vc_comp] = ...
    emergency_control(u, pi_states, predictions, seq_comp, params)
% Emergency Mode Control
% Safe operation during severe grid faults

% Input variables
v_grid = u(1); f_grid = u(2);
ids = u(3); iqs = u(4);
idr = u(5); iqr = u(6);
wr = u(7); soc = u(8);
P_wind = u(9); Te = u(10);
Ps = u(11); Qs = u(12);
v_dc = u(13); i_dc = u(14);
Va = u(15); Vb = u(16); Vc = u(17);

% Extract sequence components
V0 = seq_comp(1);
V1 = seq_comp(2);
V2 = seq_comp(3);

% Current limiting with sequence consideration
i_max = min(params.conv.Imax, 1.2/V1);  % Based on positive sequence
ids_ref = min(abs(ids), i_max) * sign(ids);
iqs_ref = min(abs(iqs), i_max) * sign(iqs);

% Add negative sequence compensation
ids_ref = ids_ref + V2 * 0.3;  % Strong unbalance compensation
iqs_ref = iqs_ref - V2 * 0.3;

% Current control with reduced gains
Kp_i = params.ctrl.frt.Kp_i * 0.5;  % Reduce gains
Ki_i = params.ctrl.frt.Ki_i * 0.5;

vdr = Kp_i * (ids_ref - ids);  % No integral action
vqr = Kp_i * (iqs_ref - iqs);

% Minimum power references with enhanced support
P_ref = 0.1 * params.dfig.Pn;  % Minimum power
Q_ref = V1 * i_max + V2 * params.conv.Imax;  % Enhanced reactive support

% DC-link and ESS control with maximum support
v_dc_ref = params.conv.Vdc * 1.2;  % Further increase DC voltage
P_ess = 0;  % No active power from ESS
Q_ess = params.ess.Pn;  % Maximum reactive support from ESS

% Enhanced voltage compensation
[Va_comp, Vb_comp, Vc_comp] = calculate_voltage_compensation(Va, Vb, Vc, V1, V2);

function [Va_comp, Vb_comp, Vc_comp] = calculate_voltage_compensation(Va, Vb, Vc, V1, V2)
% Calculate voltage compensation for unbalanced conditions
a = exp(1j*2*pi/3);
a2 = a^2;

% Calculate positive and negative sequence phasors
theta_pos = angle(Va + a*Vb + a2*Vc);
theta_neg = angle(Va + a2*Vb + a*Vc);

% Construct compensation voltages
Va_comp = V1*cos(theta_pos) - V2*cos(theta_neg);
Vb_comp = V1*cos(theta_pos - 2*pi/3) - V2*cos(theta_neg + 2*pi/3);
Vc_comp = V1*cos(theta_pos + 2*pi/3) - V2*cos(theta_neg - 2*pi/3); 