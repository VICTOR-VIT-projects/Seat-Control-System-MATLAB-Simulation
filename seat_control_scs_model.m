modelName = 'SeatControlSCS';

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
open_system(modelName);

set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'Solver', 'ode4');
set_param(modelName, 'FixedStep', '0.01');
set_param(modelName, 'StopTime', '30');

add_block('simulink/Sources/Pulse Generator', [modelName '/Fwd_Switch'], ...
    'Position', [40 105 100 135], 'Amplitude', '1', 'Period', '30', ...
    'PulseWidth', '30', 'PhaseDelay', '0');

add_block('simulink/Sources/Pulse Generator', [modelName '/Bwd_Switch'], ...
    'Position', [40 305 100 335], 'Amplitude', '1', 'Period', '30', ...
    'PulseWidth', '20', 'PhaseDelay', '15');

add_block('simulink/Logic and Bit Operations/Compare To Constant', ...
    [modelName '/Front_Limit_Sensor'], 'Position', [180 15 270 45], ...
    'relop', '>=', 'const', '100');

add_block('simulink/Logic and Bit Operations/Compare To Constant', ...
    [modelName '/Rear_Limit_Sensor'], 'Position', [180 415 270 445], ...
    'relop', '<=', 'const', '0');

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
    [modelName '/Fault_AND'], 'Position', [180 195 220 245], ...
    'Operator', 'AND', 'Inputs', '2');

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
    [modelName '/Fault_NOT'], 'Position', [320 205 360 235], ...
    'Operator', 'NOT');

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
    [modelName '/FrontLim_NOT'], 'Position', [360 15 400 45], ...
    'Operator', 'NOT');

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
    [modelName '/RearLim_NOT'], 'Position', [360 415 400 445], ...
    'Operator', 'NOT');

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
    [modelName '/FwdAllowed_AND'], 'Position', [480 85 520 155], ...
    'Operator', 'AND', 'Inputs', '3');

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
    [modelName '/BwdAllowed_AND'], 'Position', [480 285 520 355], ...
    'Operator', 'AND', 'Inputs', '3');

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
    [modelName '/Enable_OR'], 'Position', [600 500 640 550], ...
    'Operator', 'OR', 'Inputs', '2');

add_block('simulink/Signal Attributes/Data Type Conversion', ...
    [modelName '/DTC_Fwd'], 'Position', [600 105 650 135], ...
    'OutDataTypeStr', 'double');

add_block('simulink/Signal Attributes/Data Type Conversion', ...
    [modelName '/DTC_Bwd'], 'Position', [600 305 650 335], ...
    'OutDataTypeStr', 'double');

add_block('simulink/Math Operations/Sum', [modelName '/Cmd_Sum'], ...
    'Position', [720 200 750 240], 'Inputs', '+-', ...
    'IconShape', 'rectangular');

add_block('simulink/Discontinuities/Rate Limiter', [modelName '/Comfort_Ramp'], ...
    'Position', [820 200 880 240], 'RisingSlewLimit', '2', ...
    'FallingSlewLimit', '-2');

add_block('simulink/Math Operations/Gain', [modelName '/Motor_Speed_Gain'], ...
    'Position', [960 200 1020 240], 'Gain', '15');

add_block('simulink/Continuous/Integrator', [modelName '/Seat_Position'], ...
    'Position', [1100 200 1150 240], 'LimitOutput', 'on', ...
    'UpperSaturationLimit', '100', 'LowerSaturationLimit', '0');

add_block('simulink/Signal Attributes/Data Type Conversion', ...
    [modelName '/DTC_Enable'], 'Position', [720 510 770 540], ...
    'OutDataTypeStr', 'double');

add_block('simulink/Signal Attributes/Data Type Conversion', ...
    [modelName '/DTC_Fault'], 'Position', [720 590 770 620], ...
    'OutDataTypeStr', 'double');

add_block('simulink/Signal Routing/Mux', [modelName '/Mux'], ...
    'Position', [1260 250 1270 560], 'Inputs', '4');

add_block('simulink/Sinks/Scope', [modelName '/Scope'], ...
    'Position', [1330 385 1370 425]);
set_param([modelName '/Scope'], 'NumInputPorts', '1');
open_system([modelName '/Scope']);

add_line(modelName, 'Fwd_Switch/1', 'Fault_AND/1', 'autorouting', 'on');
add_line(modelName, 'Bwd_Switch/1', 'Fault_AND/2', 'autorouting', 'on');
add_line(modelName, 'Fault_AND/1', 'Fault_NOT/1', 'autorouting', 'on');

add_line(modelName, 'Front_Limit_Sensor/1', 'FrontLim_NOT/1', 'autorouting', 'on');
add_line(modelName, 'Rear_Limit_Sensor/1', 'RearLim_NOT/1', 'autorouting', 'on');

add_line(modelName, 'Fwd_Switch/1', 'FwdAllowed_AND/1', 'autorouting', 'on');
add_line(modelName, 'FrontLim_NOT/1', 'FwdAllowed_AND/2', 'autorouting', 'on');
add_line(modelName, 'Fault_NOT/1', 'FwdAllowed_AND/3', 'autorouting', 'on');

add_line(modelName, 'Bwd_Switch/1', 'BwdAllowed_AND/1', 'autorouting', 'on');
add_line(modelName, 'RearLim_NOT/1', 'BwdAllowed_AND/2', 'autorouting', 'on');
add_line(modelName, 'Fault_NOT/1', 'BwdAllowed_AND/3', 'autorouting', 'on');

add_line(modelName, 'FwdAllowed_AND/1', 'Enable_OR/1', 'autorouting', 'on');
add_line(modelName, 'BwdAllowed_AND/1', 'Enable_OR/2', 'autorouting', 'on');

add_line(modelName, 'FwdAllowed_AND/1', 'DTC_Fwd/1', 'autorouting', 'on');
add_line(modelName, 'BwdAllowed_AND/1', 'DTC_Bwd/1', 'autorouting', 'on');
add_line(modelName, 'DTC_Fwd/1', 'Cmd_Sum/1', 'autorouting', 'on');
add_line(modelName, 'DTC_Bwd/1', 'Cmd_Sum/2', 'autorouting', 'on');

add_line(modelName, 'Cmd_Sum/1', 'Comfort_Ramp/1', 'autorouting', 'on');
add_line(modelName, 'Comfort_Ramp/1', 'Motor_Speed_Gain/1', 'autorouting', 'on');
add_line(modelName, 'Motor_Speed_Gain/1', 'Seat_Position/1', 'autorouting', 'on');

add_line(modelName, 'Seat_Position/1', 'Front_Limit_Sensor/1', 'autorouting', 'on');
add_line(modelName, 'Seat_Position/1', 'Rear_Limit_Sensor/1', 'autorouting', 'on');

add_line(modelName, 'Seat_Position/1', 'Mux/1', 'autorouting', 'on');
add_line(modelName, 'Comfort_Ramp/1', 'Mux/2', 'autorouting', 'on');
add_line(modelName, 'Enable_OR/1', 'DTC_Enable/1', 'autorouting', 'on');
add_line(modelName, 'DTC_Enable/1', 'Mux/3', 'autorouting', 'on');
add_line(modelName, 'Fault_AND/1', 'DTC_Fault/1', 'autorouting', 'on');
add_line(modelName, 'DTC_Fault/1', 'Mux/4', 'autorouting', 'on');
add_line(modelName, 'Mux/1', 'Scope/1', 'autorouting', 'on');

save_system(modelName);
sim(modelName);

disp('Model built and simulated: SeatControlSCS');
disp('Open the Scope block to see seat position, motor command, enable, and fault signals.');
