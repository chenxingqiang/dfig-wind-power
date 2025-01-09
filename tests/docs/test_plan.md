# Test Plan for DFIG Wind Power System with Energy Storage

## 1. Overview

This document outlines the test plan for the DFIG wind power system with energy storage, focusing on system response to load changes and grid faults. The test plan covers both normal operation and fault conditions, with particular emphasis on the energy storage system's support capabilities.

## 2. Test Environment

### 2.1 System Configuration
- DFIG Rated Power: 2 MW
- Energy Storage: 0.5 MW / 1 MWh
- Grid Voltage: 690 V
- Nominal Frequency: 50 Hz

### 2.2 Test Tools
- MATLAB/Simulink R2021b or later
- Custom S-Functions for:
  - DFIG Control
  - Energy Storage System
  - Grid Interface
  - Fault Simulation

## 3. Test Scenarios

### 3.1 Load Step Change Test
#### Purpose
Validate the system's frequency support capability during sudden load changes.

#### Test Cases
1. **TC1.1: Moderate Load Increase**
   - Initial Load: 60% of rated power
   - Step Change: +40% (to 100%)
   - Duration: 5s steady state, step at t=5s
   - Expected Response:
     - Frequency nadir > 49.5 Hz
     - Settling time < 2s
     - ESS power support < 0.5 MW

2. **TC1.2: Load Decrease**
   - Initial Load: 100% of rated power
   - Step Change: -40% (to 60%)
   - Duration: 5s steady state, step at t=5s
   - Expected Response:
     - Frequency peak < 50.5 Hz
     - Settling time < 2s
     - ESS power absorption < 0.5 MW

### 3.2 Asymmetrical Fault Test
#### Purpose
Validate the system's voltage support capability during single-phase-to-ground faults.

#### Test Cases
1. **TC2.1: Single-Phase Fault**
   - Fault Type: Phase A to ground
   - Fault Duration: 150ms
   - Voltage Dip: 0.2 pu on faulted phase
   - Expected Response:
     - Healthy phase voltages > 0.9 pu
     - VUF < 2% post-fault
     - ESS reactive power support > 0.3 MVAr

2. **TC2.2: Fault Recovery**
   - Post-fault voltage recovery
   - Recovery time: < 100ms
   - Expected Response:
     - All phase voltages > 0.9 pu
     - System returns to normal operation
     - ESS power gradual reduction

## 4. Test Procedures

### 4.1 Load Step Change Test Procedure
1. Initialize system with base parameters
2. Run simulation with load step profile
3. Monitor and record:
   - Frequency response
   - ESS power output
   - System mode transitions
4. Analyze results against performance metrics

### 4.2 Asymmetrical Fault Test Procedure
1. Initialize system with fault parameters
2. Run simulation with fault profile
3. Monitor and record:
   - Phase voltages
   - Sequence components
   - ESS reactive power support
4. Analyze voltage unbalance and recovery

## 5. Performance Metrics

### 5.1 Frequency Control Metrics
- Frequency Nadir: > 49.5 Hz
- Frequency Peak: < 50.5 Hz
- Settling Time: < 2s
- ESS Response Time: < 100ms

### 5.2 Voltage Support Metrics
- Minimum Voltage: > 0.2 pu during fault
- Voltage Recovery: > 0.9 pu post-fault
- Maximum VUF: < 2%
- ESS Response Time: < 50ms

## 6. Test Results Documentation

### 6.1 Required Plots
1. Load Step Test:
   - Load power and ESS response
   - PCC frequency
   - ESS state of charge

2. Asymmetrical Fault Test:
   - Three-phase voltages
   - ESS power response (P & Q)
   - Voltage unbalance factor

### 6.2 Performance Metrics Report
- Automated generation of test reports
- Key performance indicators
- Pass/fail criteria evaluation
- Recommendations for system improvement

## 7. Test Automation

### 7.1 Test Scripts
- `test_load_step.m`: Load change scenarios
- `test_asymm_fault.m`: Fault scenarios
- `run_all_tests.m`: Complete test suite

### 7.2 Analysis Scripts
- Automated data processing
- Performance metrics calculation
- Report generation
- Plot generation 