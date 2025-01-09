classdef drl_agent < handle
    %% DRL Agent for Power Optimization
    % Implements deep reinforcement learning for optimal power distribution
    
    properties
        % Network architecture
        state_dim
        action_dim
        hidden_dim
        
        % Network parameters
        actor_network
        critic_network
        
        % Training parameters
        gamma
        tau
        batch_size
        
        % Experience replay
        memory_capacity
        memory
        memory_counter
        
        % Noise process for exploration
        noise_std
    end
    
    methods
        function obj = drl_agent(config)
            % Constructor
            obj.state_dim = config.state_dim;
            obj.action_dim = config.action_dim;
            obj.hidden_dim = config.hidden_dim;
            obj.gamma = config.gamma;
            obj.tau = 0.001;
            obj.batch_size = 64;
            obj.memory_capacity = 10000;
            obj.noise_std = 0.1;
            
            % Initialize networks
            obj.init_networks();
            
            % Initialize experience replay memory
            obj.memory = zeros(obj.memory_capacity, obj.state_dim + obj.action_dim + 1 + obj.state_dim);
            obj.memory_counter = 0;
        end
        
        function [P_dfig, P_ess] = get_action(obj, state)
            % Get optimal action from actor network
            
            % Forward pass through actor network
            action = obj.forward(obj.actor_network, state);
            
            % Add exploration noise
            noise = obj.noise_std * randn(size(action));
            action = action + noise;
            
            % Clip actions to [-1, 1]
            action = max(min(action, 1), -1);
            
            % Extract power references
            P_dfig = action(1);
            P_ess = action(2);
        end
        
        function update(obj, state, action, reward, next_state)
            % Store transition in replay memory
            transition = [state; action; reward; next_state];
            index = mod(obj.memory_counter, obj.memory_capacity) + 1;
            obj.memory(index, :) = transition;
            obj.memory_counter = obj.memory_counter + 1;
            
            % Update networks if enough samples
            if obj.memory_counter >= obj.batch_size
                obj.train();
            end
        end
        
        function train(obj)
            % Train actor and critic networks
            
            % Sample batch from memory
            indices = randi(min(obj.memory_counter, obj.memory_capacity), obj.batch_size, 1);
            batch = obj.memory(indices, :);
            
            % Extract batch data
            states = batch(:, 1:obj.state_dim);
            actions = batch(:, obj.state_dim+1:obj.state_dim+obj.action_dim);
            rewards = batch(:, obj.state_dim+obj.action_dim+1);
            next_states = batch(:, end-obj.state_dim+1:end);
            
            % Update critic
            target_actions = obj.forward(obj.actor_network, next_states);
            target_q = rewards + obj.gamma * obj.forward(obj.critic_network, [next_states, target_actions]);
            current_q = obj.forward(obj.critic_network, [states, actions]);
            critic_loss = mean((target_q - current_q).^2);
            
            % Update critic network weights
            obj.backward(obj.critic_network, critic_loss);
            
            % Update actor
            actor_loss = -mean(obj.forward(obj.critic_network, [states, obj.forward(obj.actor_network, states)]));
            
            % Update actor network weights
            obj.backward(obj.actor_network, actor_loss);
            
            % Soft update target networks
            obj.soft_update();
        end
    end
    
    methods (Access = private)
        function init_networks(obj)
            % Initialize actor and critic networks
            
            % Actor network
            obj.actor_network.W1 = 0.1 * randn(obj.hidden_dim, obj.state_dim);
            obj.actor_network.b1 = zeros(obj.hidden_dim, 1);
            obj.actor_network.W2 = 0.1 * randn(obj.action_dim, obj.hidden_dim);
            obj.actor_network.b2 = zeros(obj.action_dim, 1);
            
            % Critic network
            input_dim = obj.state_dim + obj.action_dim;
            obj.critic_network.W1 = 0.1 * randn(obj.hidden_dim, input_dim);
            obj.critic_network.b1 = zeros(obj.hidden_dim, 1);
            obj.critic_network.W2 = 0.1 * randn(1, obj.hidden_dim);
            obj.critic_network.b2 = 0;
        end
        
        function output = forward(obj, network, input)
            % Forward pass through network
            h1 = tanh(network.W1 * input' + network.b1);
            output = network.W2 * h1 + network.b2;
            output = output';
        end
        
        function backward(obj, network, loss)
            % Backward pass through network
            % Note: This is a simplified implementation
            % In practice, use automatic differentiation
            learning_rate = 0.001;
            network.W1 = network.W1 - learning_rate * loss;
            network.W2 = network.W2 - learning_rate * loss;
        end
        
        function soft_update(obj)
            % Soft update target networks
            for field = fieldnames(obj.actor_network)'
                obj.actor_network.(field{1}) = (1 - obj.tau) * obj.actor_network.(field{1}) + ...
                    obj.tau * obj.actor_network.(field{1});
            end
            
            for field = fieldnames(obj.critic_network)'
                obj.critic_network.(field{1}) = (1 - obj.tau) * obj.critic_network.(field{1}) + ...
                    obj.tau * obj.critic_network.(field{1});
            end
        end
    end
end 