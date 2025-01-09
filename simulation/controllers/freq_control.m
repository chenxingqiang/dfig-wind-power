function [P_ref, Q_ref] = freq_control(state, drl_agent)
%% Frequency Control
% Implements virtual inertia and primary frequency control with DRL optimization
% Inputs:
%   state - Current system state
%   drl_agent - Deep reinforcement learning agent
% Outputs:
%   P_ref - Active power reference
%   Q_ref - Reactive power reference

global dfig ess ctrl

%% Frequency Measurement
f_grid = state.f_grid;
f_dev = f_grid - dfig.fn;
df_dt = state.df_dt;

%% Virtual Inertia Response
if abs(df_dt) > ctrl.freq.db
    % Calculate inertial power
    P_inertia = -2 * dfig.H * dfig.Pn * df_dt;
    
    % Apply power limits
    P_inertia = min(max(P_inertia, -0.1*dfig.Pn), 0.1*dfig.Pn);
else
    P_inertia = 0;
end

%% Primary Frequency Control
if abs(f_dev) > ctrl.freq.db
    % Calculate droop response
    P_droop = -(f_dev/dfig.fn) * ctrl.freq.Kdroop * dfig.Pn;
    
    % Apply power limits
    P_droop = min(max(P_droop, -0.2*dfig.Pn), 0.2*dfig.Pn);
else
    P_droop = 0;
end

%% DRL-based Power Optimization
% Prepare state for DRL agent
drl_state = [f_dev; df_dt; state.soc; state.P_wind/dfig.Pn];

% Get optimal power distribution
[P_dfig_opt, P_ess_opt] = drl_agent.get_action(drl_state);

% Apply DRL optimization
P_dfig = P_dfig_opt * dfig.Pn;
P_ess = P_ess_opt * ess.Pn;

%% Coordinate Power References
% Total active power reference
P_ref = P_dfig + P_inertia + P_droop;

% Check available wind power
P_avail = state.P_wind;
P_ref = min(P_ref, P_avail);

% ESS power reference
if state.soc > ess.SOCmin && state.soc < ess.SOCmax
    P_ess = min(max(P_ess, -ess.Pn), ess.Pn);
else
    P_ess = 0;
end

% Update total power reference
P_ref = P_ref + P_ess;

% Reactive power reference (maintain unity power factor)
Q_ref = 0;

end 