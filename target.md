# DFIG Wind Power System Control Strategies

## 1. Fault Ride-Through (FRT) Control Strategy

### Converter Response:
- **Rotor-Side Converter (RSC)**: Rapid overcurrent limiting to prevent DFIG disconnection from the grid
- **Grid-Side Converter (GSC)**: Provides reactive power support for grid voltage recovery

### Energy Storage System (ESS) Integration:
- ESS provides additional reactive power through the grid-side converter to alleviate converter capacity limitations
- ESS utilizes LSTM prediction for power demand during voltage recovery process to optimize power release

## 2. Primary Frequency Control Strategy

### Inertial Response:
- Wind turbine rotational reserves provide short-term inertial response to mitigate frequency fluctuations

### Coordinated Converter-ESS Frequency Control:
- ESS provides continuous active power support through the grid-side converter, compensating for insufficient wind turbine inertial response capability
- Deep Reinforcement Learning (DRL) optimizes ESS SOC allocation and dynamically adjusts converter output targets

## 3. Dynamic Mode Switching Mechanism

- **Grid Fault Conditions**: ESS switches to grid-forming control mode, actively providing frequency and voltage references through the grid-side converter
- **Post-Fault Recovery**: ESS returns to grid-following control mode, coordinating with converters to optimize power output

## 4. Deep Learning-Assisted SOC Optimization

### LSTM Prediction:
- Predicts power demand variations due to grid disturbances

### DRL Optimization:
- Utilizes reward mechanisms to optimize SOC allocation strategies, ensuring efficient ESS utilization during fault ride-through and frequency regulation processes

---
**Implementation**: MATLAB/Simulink