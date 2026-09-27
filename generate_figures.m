seat_control_scs_model;
mdl = 'SeatControlSCS';

figDir = fullfile(pwd, 'figures');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

print(['-s' mdl], '-dpng', '-r200', fullfile(figDir, 'fig1_simulink_model.png'));

sigs = { ...
    'Seat_Position', 'pos_log'; ...
    'Comfort_Ramp',  'cmd_log'; ...
    'Enable_OR',     'en_log'; ...
    'Fault_AND',     'fault_log'; ...
    'Fwd_Switch',    'fwd_log'; ...
    'Bwd_Switch',    'bwd_log'};

for i = 1:size(sigs, 1)
    ph = get_param([mdl '/' sigs{i, 1}], 'PortHandles');
    set_param(ph.Outport(1), 'DataLogging', 'on', ...
        'DataLoggingNameMode', 'Custom', 'DataLoggingName', sigs{i, 2});
end
set_param(mdl, 'SignalLogging', 'on', 'SignalLoggingName', 'logsout');

outA = sim(mdl);
logsA = outA.get('logsout');
plotResponse(logsA, 'Nominal operation', fullfile(figDir, 'fig2_nominal_response.png'));
reportNumbers(logsA, 'Nominal');

set_param([mdl '/Bwd_Switch'], 'PhaseDelay', '0');
outB = sim(mdl);
logsB = outB.get('logsout');
plotResponse(logsB, 'Fault scenario (both switches pressed)', fullfile(figDir, 'fig3_fault_response.png'));
reportNumbers(logsB, 'Fault');

disp('Figures written to the figures folder.');

function plotResponse(logs, titleText, fileName)
    v = @(n) logs.getElement(n).Values;
    fwd = v('fwd_log'); bwd = v('bwd_log'); pos = v('pos_log');
    cmd = v('cmd_log'); en = v('en_log'); flt = v('fault_log');

    f = figure('Position', [100 100 900 900], 'Color', 'w', 'Visible', 'off');
    if ~isMATLABReleaseOlderThan('R2025a')
        theme(f, 'light');
    end

    subplot(5, 1, 1);
    stairs(fwd.Time, double(fwd.Data), 'LineWidth', 1.5); hold on;
    stairs(bwd.Time, double(bwd.Data), '--', 'LineWidth', 1.5);
    grid on; ylim([-0.2 1.6]); ylabel('Switch');
    legend('Forward', 'Backward', 'Location', 'north', 'Orientation', 'horizontal');
    title(['Driver inputs - ' titleText]);

    subplot(5, 1, 2);
    plot(pos.Time, pos.Data, 'LineWidth', 1.5, 'Color', [0 0.45 0.74]);
    grid on; ylim([-5 105]); ylabel('mm'); title('Seat position');

    subplot(5, 1, 3);
    plot(cmd.Time, cmd.Data, 'LineWidth', 1.5, 'Color', [0.85 0.33 0.1]);
    grid on; ylim([-1.3 1.3]); ylabel('Command'); title('Motor command after comfort ramp');

    subplot(5, 1, 4);
    stairs(en.Time, double(en.Data), 'LineWidth', 1.5, 'Color', [0.2 0.6 0.2]);
    grid on; ylim([-0.2 1.2]); ylabel('Enable'); title('Motor enable');

    subplot(5, 1, 5);
    stairs(flt.Time, double(flt.Data), 'LineWidth', 1.5, 'Color', [0.8 0 0]);
    grid on; ylim([-0.2 1.2]); ylabel('Fault'); xlabel('Time (s)'); title('Fault flag');

    exportgraphics(f, fileName, 'Resolution', 200);
    close(f);
end

function reportNumbers(logs, label)
    pos = logs.getElement('pos_log').Values;
    cmd = logs.getElement('cmd_log').Values;
    flt = logs.getElement('fault_log').Values;
    tFront = pos.Time(find(pos.Data >= 100 - 1e-6, 1));
    if isempty(tFront), tFront = NaN; end
    dt = mean(diff(cmd.Time));
    fprintf('[%s] front limit reached at t = %.2f s\n', label, tFront);
    fprintf('[%s] final position = %.2f mm, min = %.2f, max = %.2f\n', ...
        label, pos.Data(end), min(pos.Data), max(pos.Data));
    fprintf('[%s] max command change per step = %.4f\n', label, max(abs(diff(cmd.Data))));
    fprintf('[%s] fault active for %.2f s\n', label, sum(logical(flt.Data)) * dt);
end
