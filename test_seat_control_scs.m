seat_control_scs_model;
mdl = 'SeatControlSCS';

sigs = { ...
    'Seat_Position', 'pos_log'; ...
    'Comfort_Ramp',  'cmd_log'; ...
    'Fault_AND',     'fault_log'; ...
    'Fwd_Switch',    'fwd_log'; ...
    'Bwd_Switch',    'bwd_log'};

for i = 1:size(sigs, 1)
    ph = get_param([mdl '/' sigs{i, 1}], 'PortHandles');
    set_param(ph.Outport(1), 'DataLogging', 'on', ...
        'DataLoggingNameMode', 'Custom', 'DataLoggingName', sigs{i, 2});
end
set_param(mdl, 'SignalLogging', 'on', 'SignalLoggingName', 'logsout');

getData = @(logs, name) logs.getElement(name).Values.Data;

fixedStep = str2double(get_param(mdl, 'FixedStep'));
slewLimit = str2double(get_param([mdl '/Comfort_Ramp'], 'RisingSlewLimit'));
maxStepChange = slewLimit * fixedStep;

outA = sim(mdl);
logsA = outA.get('logsout');
posA = getData(logsA, 'pos_log');
cmdA = getData(logsA, 'cmd_log');

assert(all(posA >= -1e-9) && all(posA <= 100 + 1e-9), ...
    'Seat position exceeded [0, 100] mm travel range.');
fprintf('PASS  T1: position within [0, 100] mm (min %.2f, max %.2f)\n', min(posA), max(posA));

assert(all(abs(diff(cmdA)) <= maxStepChange + 1e-9), ...
    'Motor command jumped by more than the configured slew rate in one step.');
fprintf('PASS  T2: max command change per step %.4f <= limit %.4f\n', max(abs(diff(cmdA))), maxStepChange);

set_param([mdl '/Bwd_Switch'], 'PhaseDelay', '0');
outB = sim(mdl);
logsB = outB.get('logsout');
faultB = getData(logsB, 'fault_log');
fwdB = getData(logsB, 'fwd_log');
bwdB = getData(logsB, 'bwd_log');
posB = getData(logsB, 'pos_log');
cmdB = getData(logsB, 'cmd_log');

bothPressed = (fwdB > 0.5) & (bwdB > 0.5);
assert(any(bothPressed), ...
    'Overlap input failed to press both switches.');
assert(isequal(logical(faultB), bothPressed), ...
    'Fault flag did not match "both switches pressed" condition.');
fprintf('PASS  T3: fault flag active exactly when both switches pressed (%.2f s)\n', sum(bothPressed) * fixedStep);

assert(all(posB >= -1e-9) && all(posB <= 100 + 1e-9), ...
    'Seat position exceeded travel range during fault scenario.');
assert(all(abs(diff(cmdB)) <= maxStepChange + 1e-9), ...
    'Motor command exceeded slew rate during fault scenario.');
fprintf('PASS  T4: range and slew limits hold during fault scenario\n');

disp('All SeatControlSCS tests passed.');
