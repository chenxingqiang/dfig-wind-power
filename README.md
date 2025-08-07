# DFIG Wind Power System with Energy Storage

A MATLAB/Simulink implementation of a Doubly-Fed Induction Generator (DFIG) wind power system with integrated energy storage, featuring advanced control strategies for fault ride-through, frequency support, and dynamic mode switching.

## Features

### 🎛️ **Advanced Control Strategies**
- **Fault Ride-Through Control**
  - Coordinated control of RSC and GSC during grid faults
  - ESS support for voltage stability
  - Asymmetrical fault handling

- **Frequency Support**
  - Virtual inertia response
  - Primary frequency control
  - ESS power optimization

- **Dynamic Mode Switching**
  - Grid-following mode
  - Grid-forming mode
  - Emergency mode

- **Deep Learning Integration**
  - LSTM-based power prediction
  - DRL-optimized SOC management
  - Adaptive control strategies

### 🖥️ **Professional GUI Tools** *(NEW in v2.0)*
- **Master Control Center** - Unified system launcher and monitor
- **Interactive Parameter Configuration** - Professional multi-tab GUI for system setup
- **Real-time Simulation Dashboard** - Live monitoring with fault injection capabilities
- **Advanced Performance Analyzer** - Comprehensive analysis and reporting tools
- **Seamless Simulink Integration** - Automated model setup and execution

## System Architecture

```
├── simulation/          # Simulink models and simulation files
├── controllers/         # Control system implementations
│   ├── frt_control.m   # Fault ride-through control
│   ├── freq_control.m  # Frequency control
│   ├── mode_switch.m   # Mode switching logic
│   └── deep_learning/  # Deep learning modules
├── models/             # System component models
├── utils/             # Utility functions
└── tests/             # Test suite
    ├── docs/          # Test documentation
    └── test_results/  # Test outputs
```

## Prerequisites

- MATLAB R2021b or later
- Simulink
- Control System Toolbox
- Deep Learning Toolbox (optional, for advanced features)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/chenxingqiang/dfig-wind-power.git
   cd dfig-wind-power
   ```

2. Open MATLAB and navigate to the project directory:
   ```matlab
   cd /path/to/dfig-wind-power
   ```

3. **🚀 NEW: Setup Simulink Model (REQUIRED)**
   ```matlab
   cd simulation
   setup_simulink_model  % Creates working dfig_wind_system.slx
   ```
   
   📖 **For detailed setup instructions, see**: `simulation/README_Simulink_Setup.md`

4. Add project paths (if not done automatically):
   ```matlab
   addpath(genpath(pwd));
   ```

## 🚀 Quick Start with GUI Tools

### **Option 1: Master Control Center (Recommended)**
```matlab
dfig_system_launcher  % Launch the unified control center
```
This opens the **Master Control Center** with access to all system tools:
- 🎛️ Parameter Configuration GUI
- 🖥️ Real-time Simulation Dashboard  
- 📊 Advanced Performance Analyzer
- 🎯 Simulink Model Integration
- 🧪 Test Suite Execution

### **Option 2: Individual Tools**
```matlab
gui_parameter_config      % Parameter configuration
gui_simulation_dashboard  % Real-time dashboard
performance_analyzer      % Analysis and reporting
```

## Running Tests

1. Navigate to the tests directory:
   ```matlab
   cd tests
   ```

2. Initialize the test environment:
   ```matlab
   startup
   ```

3. Run the complete test suite:
   ```matlab
   run_all_tests
   ```

   Or run specific test groups:
   ```matlab
   run_load_tests    % Run only load step tests
   run_fault_tests   % Run only fault tests
   ```

4. View test results in `tests/test_results/`:
   - HTML report: `test_report.html`
   - Performance plots: PNG files
   - Detailed metrics and analysis

## System Parameters

- DFIG Rated Power: 2.0 MW
- Energy Storage: 0.5 MW / 1.0 MWh
- Grid Voltage: 690 V
- Nominal Frequency: 50 Hz
- Control Sample Time: 100 μs

## Performance Metrics

### Frequency Control
- Nadir > 49.5 Hz
- Peak < 50.5 Hz
- Settling time < 2s
- ESS response time < 100ms

### Voltage Support
- Minimum voltage > 0.2 pu during fault
- Recovery > 0.9 pu post-fault
- Maximum VUF < 2%
- ESS response time < 50ms

## Documentation

- [Test Plan](tests/docs/test_plan.md)
- [Design Documentation](docs/design_final.md)
- [Development Plan](docs/development_plan.md)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Based on research in grid-connected DFIG wind power systems
- Incorporates modern control strategies for grid support
- Utilizes deep learning for performance optimization

## Contact

Your Name - [@ychenxingqiang](https://github.com/ychenxingqiang)

Project Link: [https://github.com/ychenxingqiang/dfig-wind-power](https://github.com/ychenxingqiang/dfig-wind-power) 