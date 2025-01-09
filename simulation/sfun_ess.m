function [sys,x0,str,ts] = sfun_ess(t,x,u,flag,params)
%SFUN_ESS S-Function for Energy Storage System model
% This S-function implements the dynamic model of the energy storage system

switch flag
    case 0 % Initialization
        [sys,x0,str,ts] = mdlInitializeSizes(params);
        
    case 1 % Derivatives
        sys = mdlDerivatives(t,x,u,params);
        
    case 3 % Outputs
        sys = mdlOutputs(t,x,u,params);
        
    case {2, 4, 9} % Unused flags
        sys = [];
        
    otherwise % Unexpected flags
        error(['Unhandled flag = ',num2str(flag)]);
end

%% Function to initialize system
function [sys,x0,str,ts] = mdlInitializeSizes(params)
% Call simsizes for a sizes structure
sizes = simsizes;

sizes.NumContStates  = 2;     % [soc idc]
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 4;     % [soc P_ess Q_ess v_dc]
sizes.NumInputs      = 3;     % [P_ref Q_ref v_dc_ref]
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);

% Initialize state vector
x0 = [0.8;           % Initial SOC
      0];            % Initial DC current

str = [];            % Set str to an empty matrix
ts  = [0 0];        % Inherited sample time

%% Function to compute derivatives
function sys = mdlDerivatives(t,x,u,params)
% State variables
soc = x(1);     % State of charge
idc = x(2);     % DC current

% Input variables
P_ref = u(1);   % Active power reference
Q_ref = u(2);   % Reactive power reference
v_dc_ref = u(3);% DC voltage reference

% Parameters
C = params.C;           % DC-link capacitance
En = params.En;         % Rated energy capacity
eta = params.eta;       % Efficiency
tau = params.tau;       % Time constant

% Compute power losses
P_loss = (1-eta) * abs(P_ref);

% Compute DC current derivative
didc = (P_ref + P_loss) / (v_dc_ref * tau);

% Compute SOC derivative
dsoc = -P_ref / (3600 * En);  % Convert Wh to W

% Apply SOC limits
if (soc >= params.SOCmax && dsoc > 0) || ...
   (soc <= params.SOCmin && dsoc < 0)
    dsoc = 0;
end

sys = [dsoc; didc];

%% Function to compute outputs
function sys = mdlOutputs(t,x,u,params)
% State variables
soc = x(1);
idc = x(2);

% Input variables
P_ref = u(1);
Q_ref = u(2);
v_dc_ref = u(3);

% Compute actual power
if soc > params.SOCmin && soc < params.SOCmax
    P_ess = P_ref;
    Q_ess = Q_ref;
else
    P_ess = 0;
    Q_ess = 0;
end

% Compute DC voltage
v_dc = v_dc_ref + idc * params.tau;

sys = [soc; P_ess; Q_ess; v_dc]; 