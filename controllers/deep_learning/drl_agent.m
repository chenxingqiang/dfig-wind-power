classdef drl_agent < handle
    % DRL_AGENT Deep Reinforcement Learning agent for SOC optimization
    %   Implements DRL for optimizing power distribution between DFIG and ESS
    
    properties (Access = private)
        % DRL Networks
        actor_network
        critic_network
        
        % Configuration
        config
        
        % Experience replay buffer
        replay_buffer
        
        % Training parameters
        gamma = 0.99  % Discount factor
        tau = 0.001   % Target network update rate
        
        % Target networks
        target_actor
        target_critic
    end
    
    methods
        function obj = drl_agent(config)
            % Constructor
            obj.config = config;
            
            % Initialize networks
            obj.initialize_networks();
            
            % Initialize replay buffer
            obj.replay_buffer = struct(...
                'states', [], ...
                'actions', [], ...
                'rewards', [], ...
                'next_states', [], ...
                'terminals', []);
        end
        
        function action = get_action(obj, state)
            % Get action from actor network
            
            % Normalize state
            state_normalized = obj.normalize_state(state);
            
            % Get action from actor network
            action_normalized = predict(obj.actor_network, state_normalized);
            
            % Add exploration noise during training
            if obj.config.training_mode
                noise = obj.generate_exploration_noise();
                action_normalized = action_normalized + noise;
            end
            
            % Clip action to valid range
            action_normalized = min(max(action_normalized, -1), 1);
            
            % Denormalize action
            action = obj.denormalize_action(action_normalized);
        end
        
        function train(obj, experience)
            % Train DRL agent using experience replay
            
            % Add experience to replay buffer
            obj.add_to_replay_buffer(experience);
            
            % Check if enough samples for training
            if size(obj.replay_buffer.states, 1) < obj.config.batch_size
                return;
            end
            
            % Sample mini-batch
            batch = obj.sample_batch();
            
            % Update critic
            obj.update_critic(batch);
            
            % Update actor
            obj.update_actor(batch);
            
            % Update target networks
            obj.update_target_networks();
        end
    end
    
    methods (Access = private)
        function initialize_networks(obj)
            % Initialize actor network
            actor_layers = [
                featureInputLayer(obj.config.state_dim)
                fullyConnectedLayer(64)
                reluLayer
                fullyConnectedLayer(32)
                reluLayer
                fullyConnectedLayer(obj.config.action_dim)
                tanhLayer
            ];
            
            obj.actor_network = assembleNetwork(actor_layers);
            obj.target_actor = assembleNetwork(actor_layers);
            
            % Initialize critic network
            critic_layers = [
                featureInputLayer(obj.config.state_dim + obj.config.action_dim)
                fullyConnectedLayer(64)
                reluLayer
                fullyConnectedLayer(32)
                reluLayer
                fullyConnectedLayer(1)
            ];
            
            obj.critic_network = assembleNetwork(critic_layers);
            obj.target_critic = assembleNetwork(critic_layers);
        end
        
        function add_to_replay_buffer(obj, experience)
            % Add experience to replay buffer
            obj.replay_buffer.states = [obj.replay_buffer.states; experience.state];
            obj.replay_buffer.actions = [obj.replay_buffer.actions; experience.action];
            obj.replay_buffer.rewards = [obj.replay_buffer.rewards; experience.reward];
            obj.replay_buffer.next_states = [obj.replay_buffer.next_states; experience.next_state];
            obj.replay_buffer.terminals = [obj.replay_buffer.terminals; experience.terminal];
            
            % Limit buffer size
            if size(obj.replay_buffer.states, 1) > obj.config.buffer_size
                obj.replay_buffer.states(1,:) = [];
                obj.replay_buffer.actions(1,:) = [];
                obj.replay_buffer.rewards(1) = [];
                obj.replay_buffer.next_states(1,:) = [];
                obj.replay_buffer.terminals(1) = [];
            end
        end
        
        function batch = sample_batch(obj)
            % Sample random batch from replay buffer
            buffer_size = size(obj.replay_buffer.states, 1);
            indices = randperm(buffer_size, obj.config.batch_size);
            
            batch.states = obj.replay_buffer.states(indices,:);
            batch.actions = obj.replay_buffer.actions(indices,:);
            batch.rewards = obj.replay_buffer.rewards(indices);
            batch.next_states = obj.replay_buffer.next_states(indices,:);
            batch.terminals = obj.replay_buffer.terminals(indices);
        end
        
        function update_critic(obj, batch)
            % Update critic network
            
            % Get target actions
            next_actions = predict(obj.target_actor, batch.next_states);
            
            % Get target Q-values
            target_q = predict(obj.target_critic, [batch.next_states, next_actions]);
            
            % Calculate target values
            targets = batch.rewards + obj.gamma * (1 - batch.terminals) .* target_q;
            
            % Update critic
            options = trainingOptions('adam', ...
                'MaxEpochs', 1, ...
                'MiniBatchSize', obj.config.batch_size, ...
                'InitialLearnRate', 0.001);
            
            obj.critic_network = trainNetwork([batch.states, batch.actions], ...
                targets, obj.critic_network.Layers, options);
        end
        
        function update_actor(obj, batch)
            % Update actor network
            
            % Calculate policy gradient
            actions = predict(obj.actor_network, batch.states);
            q_values = predict(obj.critic_network, [batch.states, actions]);
            
            policy_gradient = obj.calculate_policy_gradient(batch.states, q_values);
            
            % Update actor
            options = trainingOptions('adam', ...
                'MaxEpochs', 1, ...
                'MiniBatchSize', obj.config.batch_size, ...
                'InitialLearnRate', 0.0001);
            
            obj.actor_network = trainNetwork(batch.states, ...
                actions + policy_gradient, obj.actor_network.Layers, options);
        end
        
        function update_target_networks(obj)
            % Soft update of target networks
            obj.target_actor = obj.soft_update(obj.actor_network, obj.target_actor);
            obj.target_critic = obj.soft_update(obj.critic_network, obj.target_critic);
        end
        
        function target = soft_update(obj, network, target)
            % Soft update target network
            for i = 1:numel(network.Layers)
                if isprop(network.Layers{i}, 'Weights')
                    target.Layers{i}.Weights = (1 - obj.tau) * target.Layers{i}.Weights + ...
                        obj.tau * network.Layers{i}.Weights;
                end
                if isprop(network.Layers{i}, 'Bias')
                    target.Layers{i}.Bias = (1 - obj.tau) * target.Layers{i}.Bias + ...
                        obj.tau * network.Layers{i}.Bias;
                end
            end
        end
        
        function noise = generate_exploration_noise(obj)
            % Generate Ornstein-Uhlenbeck noise for exploration
            persistent state
            
            if isempty(state)
                state = zeros(1, obj.config.action_dim);
            end
            
            theta = 0.15;
            sigma = 0.2;
            
            state = state + theta * (0 - state) + ...
                sigma * randn(1, obj.config.action_dim);
            
            noise = state;
        end
        
        function state_norm = normalize_state(obj, state)
            % Normalize state
            state_norm = (state - obj.config.state_mean) ./ obj.config.state_std;
        end
        
        function action = denormalize_action(obj, action_norm)
            % Denormalize action
            action.dfig_factor = (action_norm(1) + 1) / 2;  % Scale to [0,1]
            action.ess_factor = (action_norm(2) + 1) / 2;   % Scale to [0,1]
        end
        
        function gradient = calculate_policy_gradient(obj, states, q_values)
            % Calculate policy gradient for actor update
            gradient = zeros(size(states));
            
            for i = 1:size(states, 1)
                % Approximate gradient using finite differences
                epsilon = 1e-6;
                for j = 1:size(states, 2)
                    states_plus = states;
                    states_plus(i,j) = states_plus(i,j) + epsilon;
                    states_minus = states;
                    states_minus(i,j) = states_minus(i,j) - epsilon;
                    
                    q_plus = predict(obj.critic_network, [states_plus(i,:), ...
                        predict(obj.actor_network, states_plus(i,:))]);
                    q_minus = predict(obj.critic_network, [states_minus(i,:), ...
                        predict(obj.actor_network, states_minus(i,:))]);
                    
                    gradient(i,j) = (q_plus - q_minus) / (2 * epsilon);
                end
            end
        end
    end
end 