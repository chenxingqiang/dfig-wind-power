classdef lstm_predictor < handle
    % LSTM_PREDICTOR LSTM-based power demand predictor
    %   Implements LSTM network for predicting power demand during grid events
    
    properties (Access = private)
        % LSTM Network
        net
        
        % Configuration
        config
        
        % Data buffers
        input_buffer
        time_buffer
        
        % Normalization parameters
        norm_params
    end
    
    methods
        function obj = lstm_predictor(config)
            % Constructor
            obj.config = config;
            
            % Initialize buffers
            obj.input_buffer = zeros(config.sequence_length, config.input_size);
            obj.time_buffer = zeros(config.sequence_length, 1);
            
            % Initialize network
            obj.initialize_network();
        end
        
        function [prediction, confidence] = predict(obj, state)
            % Update buffers
            obj.update_buffers(state);
            
            % Normalize input
            input_normalized = obj.normalize_input(obj.input_buffer);
            
            % Make prediction
            prediction_normalized = predict(obj.net, input_normalized);
            
            % Denormalize prediction
            prediction = obj.denormalize_output(prediction_normalized);
            
            % Calculate prediction confidence
            confidence = obj.calculate_confidence(prediction_normalized);
        end
        
        function train(obj, training_data)
            % Train LSTM network
            
            % Prepare training data
            X = obj.prepare_training_data(training_data.input);
            Y = obj.prepare_training_data(training_data.output);
            
            % Train network
            options = trainingOptions('adam', ...
                'MaxEpochs', obj.config.max_epochs, ...
                'GradientThreshold', 1, ...
                'InitialLearnRate', 0.005, ...
                'LearnRateSchedule', 'piecewise', ...
                'LearnRateDropPeriod', 125, ...
                'LearnRateDropFactor', 0.2, ...
                'Verbose', 0, ...
                'Plots', 'training-progress');
            
            obj.net = trainNetwork(X, Y, obj.net.Layers, options);
        end
    end
    
    methods (Access = private)
        function initialize_network(obj)
            % Define LSTM network architecture
            layers = [ ...
                sequenceInputLayer(obj.config.input_size)
                lstmLayer(obj.config.hidden_layers(1), 'OutputMode', 'sequence')
                dropoutLayer(0.2)
                lstmLayer(obj.config.hidden_layers(2), 'OutputMode', 'last')
                dropoutLayer(0.2)
                fullyConnectedLayer(obj.config.output_size)
                regressionLayer];
            
            obj.net = assembleNetwork(layers);
        end
        
        function update_buffers(obj, state)
            % Update input and time buffers with new state
            
            % Shift buffers
            obj.input_buffer(2:end,:) = obj.input_buffer(1:end-1,:);
            obj.time_buffer(2:end) = obj.time_buffer(1:end-1);
            
            % Add new data
            obj.input_buffer(1,:) = [...
                state.grid_voltage,...
                state.grid_frequency,...
                state.wind_speed,...
                state.power_output,...
                state.soc];
            
            obj.time_buffer(1) = state.time;
        end
        
        function input_normalized = normalize_input(obj, input)
            % Normalize input data
            if isempty(obj.norm_params)
                % Calculate normalization parameters if not exists
                obj.norm_params.mean = mean(input);
                obj.norm_params.std = std(input);
            end
            
            % Apply normalization
            input_normalized = (input - obj.norm_params.mean) ./ obj.norm_params.std;
        end
        
        function output = denormalize_output(obj, output_normalized)
            % Denormalize output data
            output = output_normalized * obj.norm_params.std(end) + ...
                    obj.norm_params.mean(end);
        end
        
        function confidence = calculate_confidence(obj, prediction)
            % Calculate prediction confidence based on historical accuracy
            persistent prediction_errors
            
            if isempty(prediction_errors)
                prediction_errors = zeros(100, 1);
            end
            
            % Update prediction errors
            prediction_errors(2:end) = prediction_errors(1:end-1);
            prediction_errors(1) = abs(prediction - obj.input_buffer(1,4));
            
            % Calculate confidence based on recent prediction errors
            mean_error = mean(prediction_errors);
            confidence = 1 / (1 + mean_error);
        end
        
        function data = prepare_training_data(obj, raw_data)
            % Prepare data for LSTM training
            
            % Normalize data
            data_normalized = obj.normalize_input(raw_data);
            
            % Reshape for LSTM
            numObservations = size(data_normalized, 1) - obj.config.sequence_length + 1;
            numFeatures = size(data_normalized, 2);
            
            data = zeros(obj.config.sequence_length, numFeatures, numObservations);
            
            for i = 1:numObservations
                data(:,:,i) = data_normalized(i:i+obj.config.sequence_length-1,:);
            end
        end
    end
end 