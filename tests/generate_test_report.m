function generate_test_report(output_dir, tc1_1_metrics, tc1_2_metrics, tc2_1_metrics, tc2_2_metrics)
%GENERATE_TEST_REPORT Generate comprehensive HTML test report
% This function generates a detailed test report in HTML format

% Create report file
report_file = fullfile(output_dir, 'test_report.html');
fid = fopen(report_file, 'w');

% Write HTML header
fprintf(fid, '<!DOCTYPE html>\n<html>\n<head>\n');
fprintf(fid, '<title>DFIG Wind Power System Test Report</title>\n');
fprintf(fid, '<style>\n');
fprintf(fid, 'body { font-family: Arial, sans-serif; margin: 40px; }\n');
fprintf(fid, '.passed { color: green; }\n');
fprintf(fid, '.failed { color: red; }\n');
fprintf(fid, 'table { border-collapse: collapse; width: 100%%; margin: 20px 0; }\n');
fprintf(fid, 'th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }\n');
fprintf(fid, 'th { background-color: #f2f2f2; }\n');
fprintf(fid, '.metric-box { background-color: #f8f9fa; padding: 15px; margin: 10px 0; border-radius: 5px; }\n');
fprintf(fid, '.image-container { text-align: center; margin: 20px 0; }\n');
fprintf(fid, '.image-container img { max-width: 100%%; height: auto; }\n');
fprintf(fid, '</style>\n</head>\n<body>\n');

% Write report header
fprintf(fid, '<h1>DFIG Wind Power System Test Report</h1>\n');
fprintf(fid, '<p>Test executed on: %s</p>\n', datestr(now));

% Write system configuration
fprintf(fid, '<h2>System Configuration</h2>\n');
fprintf(fid, '<div class="metric-box">\n');
fprintf(fid, '<p>DFIG Rated Power: 2.0 MW</p>\n');
fprintf(fid, '<p>Energy Storage: 0.5 MW / 1.0 MWh</p>\n');
fprintf(fid, '<p>Grid Voltage: 690 V</p>\n');
fprintf(fid, '<p>Nominal Frequency: 50 Hz</p>\n');
fprintf(fid, '</div>\n');

% Write load step test results
fprintf(fid, '<h2>Load Step Test Results</h2>\n');

% TC1.1: Load Increase
fprintf(fid, '<h3>TC1.1: Load Increase Test</h3>\n');
fprintf(fid, '<div class="metric-box">\n');
fprintf(fid, '<p>Frequency Nadir: %.3f Hz %s</p>\n', ...
    tc1_1_metrics.f_nadir, get_pass_fail(tc1_1_metrics.f_nadir > 49.5));
fprintf(fid, '<p>Settling Time: %.2f s %s</p>\n', ...
    tc1_1_metrics.settling_time, get_pass_fail(tc1_1_metrics.settling_time < 2));
fprintf(fid, '<p>ESS Response Time: %.3f s %s</p>\n', ...
    tc1_1_metrics.response_time, get_pass_fail(tc1_1_metrics.response_time < 0.1));
fprintf(fid, '</div>\n');

% Add load step plot
fprintf(fid, '<div class="image-container">\n');
fprintf(fid, '<img src="load_step_results.png" alt="Load Step Test Results">\n');
fprintf(fid, '</div>\n');

% TC1.2: Load Decrease
fprintf(fid, '<h3>TC1.2: Load Decrease Test</h3>\n');
fprintf(fid, '<div class="metric-box">\n');
fprintf(fid, '<p>Frequency Peak: %.3f Hz %s</p>\n', ...
    tc1_2_metrics.f_peak, get_pass_fail(tc1_2_metrics.f_peak < 50.5));
fprintf(fid, '<p>Settling Time: %.2f s %s</p>\n', ...
    tc1_2_metrics.settling_time, get_pass_fail(tc1_2_metrics.settling_time < 2));
fprintf(fid, '<p>ESS Response Time: %.3f s %s</p>\n', ...
    tc1_2_metrics.response_time, get_pass_fail(tc1_2_metrics.response_time < 0.1));
fprintf(fid, '</div>\n');

% Write asymmetrical fault test results
fprintf(fid, '<h2>Asymmetrical Fault Test Results</h2>\n');

% TC2.1: Single-Phase Fault
fprintf(fid, '<h3>TC2.1: Single-Phase Fault Test</h3>\n');
fprintf(fid, '<div class="metric-box">\n');
fprintf(fid, '<p>Minimum Voltage: %.3f pu %s</p>\n', ...
    tc2_1_metrics.v_min, get_pass_fail(tc2_1_metrics.v_min > 0.2));
fprintf(fid, '<p>Maximum Unbalance: %.2f %% %s</p>\n', ...
    tc2_1_metrics.v_unbalance_max, get_pass_fail(tc2_1_metrics.v_unbalance_max < 2));
fprintf(fid, '<p>ESS Response Time: %.3f s %s</p>\n', ...
    tc2_1_metrics.response_time, get_pass_fail(tc2_1_metrics.response_time < 0.05));
fprintf(fid, '</div>\n');

% Add fault test plot
fprintf(fid, '<div class="image-container">\n');
fprintf(fid, '<img src="fault_test_results.png" alt="Fault Test Results">\n');
fprintf(fid, '</div>\n');

% TC2.2: Fault Recovery
fprintf(fid, '<h3>TC2.2: Fault Recovery Test</h3>\n');
fprintf(fid, '<div class="metric-box">\n');
fprintf(fid, '<p>Recovery Time: %.3f s %s</p>\n', ...
    tc2_2_metrics.recovery_time, get_pass_fail(tc2_2_metrics.recovery_time < 0.1));
fprintf(fid, '<p>Final Voltage: %.3f pu %s</p>\n', ...
    tc2_2_metrics.v_recovery, get_pass_fail(tc2_2_metrics.v_recovery > 0.9));
fprintf(fid, '<p>Final Unbalance: %.2f %% %s</p>\n', ...
    tc2_2_metrics.final_VUF, get_pass_fail(tc2_2_metrics.final_VUF < 2));
fprintf(fid, '</div>\n');

% Add recovery test plot
fprintf(fid, '<div class="image-container">\n');
fprintf(fid, '<img src="recovery_test_results.png" alt="Recovery Test Results">\n');
fprintf(fid, '</div>\n');

% Write summary
fprintf(fid, '<h2>Test Summary</h2>\n');
fprintf(fid, '<div class="metric-box">\n');
fprintf(fid, '<p>Total Test Cases: 4</p>\n');
fprintf(fid, '<p>Passed: %d</p>\n', calculate_passed_tests(tc1_1_metrics, tc1_2_metrics, tc2_1_metrics, tc2_2_metrics));
fprintf(fid, '<p>Failed: %d</p>\n', calculate_failed_tests(tc1_1_metrics, tc1_2_metrics, tc2_1_metrics, tc2_2_metrics));
fprintf(fid, '</div>\n');

% Close HTML file
fprintf(fid, '</body>\n</html>');
fclose(fid);

end

function result = get_pass_fail(condition)
    if condition
        result = '<span class="passed">[PASS]</span>';
    else
        result = '<span class="failed">[FAIL]</span>';
    end
end

function passed = calculate_passed_tests(tc1_1, tc1_2, tc2_1, tc2_2)
    passed = 0;
    
    % TC1.1 checks
    if tc1_1.f_nadir > 49.5 && tc1_1.settling_time < 2 && tc1_1.response_time < 0.1
        passed = passed + 1;
    end
    
    % TC1.2 checks
    if tc1_2.f_peak < 50.5 && tc1_2.settling_time < 2 && tc1_2.response_time < 0.1
        passed = passed + 1;
    end
    
    % TC2.1 checks
    if tc2_1.v_min > 0.2 && tc2_1.v_unbalance_max < 2 && tc2_1.response_time < 0.05
        passed = passed + 1;
    end
    
    % TC2.2 checks
    if tc2_2.recovery_time < 0.1 && tc2_2.v_recovery > 0.9 && tc2_2.final_VUF < 2
        passed = passed + 1;
    end
end

function failed = calculate_failed_tests(tc1_1, tc1_2, tc2_1, tc2_2)
    passed = calculate_passed_tests(tc1_1, tc1_2, tc2_1, tc2_2);
    failed = 4 - passed;
end 