function [P_pred, Q_pred] = lstm_predict(state)
%% LSTM-based Power Prediction
% Predicts future power demand using LSTM network
% Inputs:
%   state - Current system state
% Outputs:
%   P_pred - Predicted active power
%   Q_pred - Predicted reactive power

global dl

%% Prepare Input Sequence
% Get historical data from state
hist_data = state.history;

% Normalize input data
norm_data = normalize_data(hist_data);

% Reshape for LSTM input [samples, timesteps, features]
sequence = reshape(norm_data, [1, dl.lstm.sequence_length, dl.lstm.input_size]);

%% LSTM Prediction
% Forward pass through LSTM network
hidden_state = zeros(dl.lstm.num_layers, dl.lstm.hidden_size);
cell_state = zeros(dl.lstm.num_layers, dl.lstm.hidden_size);

for t = 1:dl.lstm.sequence_length
    % Get current timestep
    x_t = sequence(1, t, :);
    
    % LSTM layer forward pass
    for l = 1:dl.lstm.num_layers
        [hidden_state(l,:), cell_state(l,:)] = lstm_forward(...
            x_t, hidden_state(l,:), cell_state(l,:), dl.lstm.weights{l});
        x_t = hidden_state(l,:);
    end
end

% Output layer
output = hidden_state(end,:) * dl.lstm.output_weights + dl.lstm.output_bias;

%% Post-process Predictions
% Denormalize predictions
P_pred = denormalize_power(output(1));
Q_pred = denormalize_power(output(2));

end

%% Helper Functions
function norm_data = normalize_data(data)
    % Normalize input data to [-1, 1] range
    norm_data = 2 * (data - min(data)) / (max(data) - min(data)) - 1;
end

function power = denormalize_power(norm_power)
    % Denormalize power prediction
    global dfig
    power = (norm_power + 1) * dfig.Pn / 2;
end

function [h_next, c_next] = lstm_forward(x, h_prev, c_prev, weights)
    % LSTM cell forward pass
    % Unpack weights
    W_ih = weights.input_hidden;
    W_hh = weights.hidden_hidden;
    b_ih = weights.input_bias;
    b_hh = weights.hidden_bias;
    
    % Gates
    gates = sigmoid(x * W_ih + h_prev * W_hh + b_ih + b_hh);
    
    % Input, forget, output gates and cell input
    i = gates(1:end/4);
    f = gates(end/4+1:end/2);
    o = gates(end/2+1:3*end/4);
    g = tanh(gates(3*end/4+1:end));
    
    % Cell and hidden states
    c_next = f .* c_prev + i .* g;
    h_next = o .* tanh(c_next);
end

function y = sigmoid(x)
    % Sigmoid activation function
    y = 1 ./ (1 + exp(-x));
end 