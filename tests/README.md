# DFIG Wind Power System Test Suite

This directory contains the test suite for the DFIG wind power system with energy storage.

## Prerequisites

- MATLAB R2021b or later
- Simulink
- Control System Toolbox

## Directory Structure

```
tests/
├── README.md              # This file
├── startup.m             # Environment initialization
├── run_all_tests.m       # Main test runner
├── plot_test_results.m   # Visualization functions
├── generate_test_report.m # Report generation
├── docs/                 # Test documentation
│   └── test_plan.md      # Detailed test plan
└── test_results/         # Test output directory
```

## Running the Tests

1. Start MATLAB and navigate to the `tests` directory:
   ```matlab
   cd /path/to/project/tests
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

4. View test results:
   - Test results will be saved in the `test_results` directory
   - An HTML report will be generated at `test_results/test_report.html`
   - Plot images will be saved as PNG files in the same directory

## Test Cases

1. Load Step Tests (TC1.x)
   - TC1.1: Load increase from 60% to 100%
   - TC1.2: Load decrease from 100% to 60%

2. Asymmetrical Fault Tests (TC2.x)
   - TC2.1: Single-phase fault with 0.2 pu voltage dip
   - TC2.2: Fault recovery analysis

## Performance Metrics

- Frequency Control:
  - Nadir > 49.5 Hz
  - Peak < 50.5 Hz
  - Settling time < 2s
  - ESS response time < 100ms

- Voltage Support:
  - Minimum voltage > 0.2 pu during fault
  - Recovery > 0.9 pu post-fault
  - Maximum VUF < 2%
  - ESS response time < 50ms

## Troubleshooting

If you encounter any issues:

1. Ensure all required toolboxes are installed
2. Check that all paths are correctly set up
3. Verify Simulink model is in the correct location
4. Check MATLAB version compatibility 