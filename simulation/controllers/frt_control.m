function [P_ref, Q_ref] = frt_control(state, lstm_pred)
%% Fault Ride-Through Control
% Implements coordinated control of RSC, GSC and ESS during grid faults
% Inputs:
%   state - Current system state
%   lstm_pred - LSTM predictions for next time step
% Outputs:
%   P_ref - Active power reference
%   Q_ref - Reactive power reference

global dfig conv ess ctrl

%% Fault Detection
v_grid = state.v_grid;
is_fault = v_grid < ctrl.frt.Vmin;

%% RSC Control
if is_fault
    % Limit rotor current during fault
    i_r_max = min(conv.Imax, 1.2/v_grid);
    i_r_d_ref = min(state.i_rsc(1), i_r_max);
    i_r_q_ref = min(state.i_rsc(2), i_r_max);
    
    % Calculate required reactive current
    i_q_req = (ctrl.frt.Vmin - v_grid) * ctrl.frt.Ki_i;
    i_r_q_ref = min(i_r_q_ref, i_q_req);
else
    % Normal operation
    i_r_d_ref = state.i_rsc(1);
    i_r_q_ref = state.i_rsc(2);
end

%% GSC Control
if is_fault
    % Enhance voltage support
    Q_gsc = (ctrl.frt.Vmin - v_grid) * conv.Imax;
    v_dc_ref = conv.Vdc * 1.1; % Increase DC voltage reference
else
    % Normal operation
    Q_gsc = state.Q_gsc;
    v_dc_ref = conv.Vdc;
end

%% ESS Support Control
if is_fault
    % Check SOC limits
    if state.soc > ess.SOCmin
        % Calculate required support based on LSTM prediction
        P_support = lstm_pred.P * 0.2; % 20% power support
        P_ess = min(P_support, ess.Pn);
    else
        P_ess = 0;
    end
    
    % Calculate reactive power support
    Q_ess = (ctrl.frt.Vmin - v_grid) * ess.Pn/dfig.Pn;
else
    % Normal operation
    P_ess = 0;
    Q_ess = 0;
end

%% Coordinate Control References
% Total active power reference
P_ref = i_r_d_ref * v_grid + P_ess;

% Total reactive power reference
Q_ref = i_r_q_ref * v_grid + Q_gsc + Q_ess;

% Apply power limits
P_ref = min(max(P_ref, -dfig.Pn), dfig.Pn);
Q_ref = min(max(Q_ref, -dfig.Pn), dfig.Pn);

end 