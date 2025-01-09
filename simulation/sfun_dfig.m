function [sys,x0,str,ts] = sfun_dfig(t,x,u,flag,params)
%SFUN_DFIG S-Function for DFIG model implementation
% This S-function implements the dynamic model of a DFIG

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

sizes.NumContStates  = 6;     % [ids iqs idr iqr wr theta]
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 8;     % [ids iqs idr iqr wr Te Ps Qs]
sizes.NumInputs      = 6;     % [vds vqs vdr vqr Tm beta]
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);

% Initialize state vector
x0 = zeros(6,1);
x0(5) = params.wr_rated;  % Initial rotor speed

str = [];                 % Set str to an empty matrix
ts  = [0 0];             % Inherited sample time

%% Function to compute derivatives
function sys = mdlDerivatives(t,x,u,params)
% State variables
ids = x(1); iqs = x(2);  % Stator currents
idr = x(3); iqr = x(4);  % Rotor currents
wr = x(5);               % Rotor speed
theta = x(6);            % Rotor angle

% Input variables
vds = u(1); vqs = u(2);  % Stator voltages
vdr = u(3); vqr = u(4);  % Rotor voltages
Tm = u(5);               % Mechanical torque
beta = u(6);             % Pitch angle

% Parameters
Rs = params.Rs; Rr = params.Rr;
Ls = params.Ls; Lr = params.Lr;
Lm = params.Lm;
H = params.H;
wb = 2*pi*params.fn;

% Compute flux linkages
psi_ds = Ls*ids + Lm*idr;
psi_qs = Ls*iqs + Lm*iqr;
psi_dr = Lr*idr + Lm*ids;
psi_qr = Lr*iqr + Lm*iqs;

% Compute electromagnetic torque
Te = params.poles/2 * Lm * (iqs*idr - ids*iqr);

% Compute state derivatives
% Stator current derivatives
dids = (vds - Rs*ids + wb*psi_qs) / Ls;
diqs = (vqs - Rs*iqs - wb*psi_ds) / Ls;

% Rotor current derivatives
didr = (vdr - Rr*idr + (wb-wr)*psi_qr) / Lr;
diqr = (vqr - Rr*iqr - (wb-wr)*psi_dr) / Lr;

% Mechanical equations
dwr = (Te - Tm) / (2*H);
dtheta = wr;

sys = [dids; diqs; didr; diqr; dwr; dtheta];

%% Function to compute outputs
function sys = mdlOutputs(t,x,u,params)
% State variables
ids = x(1); iqs = x(2);
idr = x(3); iqr = x(4);
wr = x(5);

% Compute electromagnetic torque
Te = params.poles/2 * params.Lm * (iqs*idr - ids*iqr);

% Compute power
vds = u(1); vqs = u(2);
Ps = vds*ids + vqs*iqs;  % Stator active power
Qs = vqs*ids - vds*iqs;  % Stator reactive power

sys = [ids; iqs; idr; iqr; wr; Te; Ps; Qs]; 