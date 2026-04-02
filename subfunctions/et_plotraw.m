function f_raw = et_plotraw(tbls, opts)
%ETPLOTRAW Plot raw eye tracking data in tiledlayout
%   Left columns: left eye
%   Right columns: right eye
%   First row:

tpL = tbls{1};
tpR = tbls{2};
tp_rawL = tbls{3};
tp_rawR = tbls{4};
tpLPreConf = tbls{5};
tpRPreConf = tbls{6};
trialLidx = tbls{7};
trialRidx = tbls{8};

[subjectPath, removeExcess, removeConf, ...
    removeBlinks, confidenceThreshold, useBlinkWindow, ...
    blockEdges, condOrder, stacked] = ...
    deal(opts.subjectPath, opts.removeExcess, opts.removeConf, ...
    opts.removeBlinks, opts.confidenceThreshold, opts.useBlinkWindow, ...
    opts.blockEdges, opts.condOrder, opts.stacked);

%% Defaults
line_colors1 = [0.7 0.7 0.7;
    0 0 1;
    0 0 0;
    0 1 0;
    1 0 0];
line_styles1 = {'-',':','-',':','-'};
line_colors2 = [0.7 0.7 0.7;
    0 0 0;
    0 0 1;
    0 0 1];
line_styles2 = {'-', '-', '-', ':'};

%f_full = figure("Units", "normalized", "Position", [0 1 .3 .3]);
f_raw = figure(1);
tl_full = tiledlayout(2, 2, "TileSpacing", "Compact", "Padding", "Compact");
sgtitle(subjectPath, 'Interpreter', 'none');

%% Top left
if stacked
    ax_ext = [min([min(tp_rawL.diameter_3d), min(tpLPreConf.diameter_3d), ...
        min(tpL.diameter_3d), min(tpL.diameter_3d_noblink)]),...
        max([max(tp_rawL.diameter_3d), max(tpLPreConf.diameter_3d), ...
        max(tpL.diameter_3d), max(tpL.diameter_3d_noblink)])];
    stackedH = linspace(0, ax_ext(2)-ax_ext(1), 4);
else
    stackedH = [0,0,0,0];
end
axL1 = nexttile;
plot(tp_rawL.pupil_timestamp, stackedH(1) + tp_rawL.diameter_3d, ...
    'Color', line_colors1(1,:), 'LineStyle',line_styles1{1});
hold on
% Confidence
if removeConf
    plot(tpLPreConf.pupil_timestamp, stackedH(2) + tpLPreConf.diameter_3d, ...
        'Color', line_colors1(2,:), 'LineStyle',line_styles1{2});
end
% Main data
if removeExcess
    plot(tpL.pupil_timestamp, stackedH(3) + tpL.diameter_3d, ...
        'Color', line_colors1(3,:), 'LineStyle',line_styles1{3});
end

if removeBlinks
    plot(tpL.pupil_timestamp, stackedH(4) + tpL.diameter_3d_noblink, ...
        'Color', line_colors1(4,:), 'LineStyle',line_styles1{4});
end

% Plot blinks in red at 90% of max Y
ax = axis;
plot(tpL.pupil_timestamp, tpL.BlinkPeriods*ax(4)*0.9, ...
    'Color', line_colors1(5,:), 'LineStyle',line_styles1{5}, ...
    'LineWidth', 25);
title('Left raw')

%% Top right
if stacked
    ax_ext = [min([min(tp_rawL.diameter_3d), min(tpLPreConf.diameter_3d), ...
        min(tpL.diameter_3d), min(tpL.diameter_3d_noblink)]),...
        max([max(tp_rawL.diameter_3d), max(tpLPreConf.diameter_3d), ...
        max(tpL.diameter_3d), max(tpL.diameter_3d_noblink)])];
    stackedH = linspace(0, ax_ext(2)-ax_ext(1), 4);
else
    stackedH = [0,0,0,0];
end

axR1 = nexttile;
plot(tp_rawR.pupil_timestamp, stackedH(1) + tp_rawR.diameter_3d, ...
    'Color', line_colors1(1,:), 'LineStyle',line_styles1{1});
hold on
% Confidence
if removeConf
    plot(tpRPreConf.pupil_timestamp, stackedH(2) + tpRPreConf.diameter_3d, ...
        'Color', line_colors1(2,:), 'LineStyle',line_styles1{2});
end
% Main data
if removeExcess
    plot(tpR.pupil_timestamp, stackedH(3) + tpR.diameter_3d, ...
        'Color', line_colors1(3,:), 'LineStyle',line_styles1{3});
end

if removeBlinks
    plot(tpR.pupil_timestamp, stackedH(4) + tpR.diameter_3d_noblink, ...
        'Color', line_colors1(4,:), 'LineStyle',line_styles1{4});
end
% Plot blinks in red at 90% of max Y
ax = axis;
plot(tpR.pupil_timestamp, tpR.BlinkPeriods*ax(4)*0.9, ...
    'Color', line_colors1(5,:), 'LineStyle',line_styles1{5}, ...
    'LineWidth', 25);
title('Right raw')

%% Legend for top graphs
lgd = ["All data"];
if removeConf; lgd = [lgd, string(sprintf('PreConf = %.2f', confidenceThreshold))]; end
if removeExcess; lgd = [lgd, "Experiment period"]; end
if removeBlinks
    if useBlinkWindow
        lgd = [lgd, "Nystrom Blinks removed"];
    else
        lgd = [lgd, "PL Blinks removed"];
    end

end
%if doInterp; lgd = [lgd, "Interpolated"]; end
lgd = [lgd, "Blinks"];
legend(axR1, lgd, 'Location', 'northwest');

%% Bottom left
axL2 = nexttile;
plot(tpL.pupil_timestamp, tpL.diameter_3d, ...
    'Color', line_colors2(1,:), 'LineStyle',line_styles2{1});
hold on
plot(tpL.pupil_timestamp, tpL.diameter_3d_filt, ...
    'Color', line_colors2(2,:), 'LineStyle',line_styles2{2});
for i = 1:6
    xline(tpL{blockEdges(i,1), 'pupil_timestamp'}, ...
        'Color', line_colors2(3,:), 'LineStyle', line_styles2{3});
end
ax = axis;
for i = 1:3
    % Text for condition
    text(tpL{round((blockEdges(i*2-1,1) + blockEdges(i*2, 1))/2), "pupil_timestamp"}, ...
        ax(4) * 0.90, condOrder(i), ...
        'Color', line_colors2(3,:), 'HorizontalAlignment', 'center',...
        'Interpreter', 'none');

    % Trial lines
    for j = 1:24
        xline(tpL{trialLidx((i-1)*24+j), 'pupil_timestamp'}, ...
            'Color', line_colors2(4,:), 'LineStyle', line_styles2{4});
    end
end
title('Left trials')
%% Bottom right
axR2 = nexttile;
plot(tpR.pupil_timestamp, tpR.diameter_3d, ...
    'Color', line_colors2(1,:), 'LineStyle',line_styles2{1});
hold on

plot(tpR.pupil_timestamp, tpR.diameter_3d_filt, ...
    'Color', line_colors2(2,:), 'LineStyle',line_styles2{2});
for i = 1:6
    xline(tpR{blockEdges(i,2), 'pupil_timestamp'}, ...
        'Color', line_colors2(3,:), 'LineStyle', line_styles2{3});
end
ax = axis;
for i = 1:3
    text(tpR{round((blockEdges(i*2-1,1) + blockEdges(i*2, 1))/2), "pupil_timestamp"}, ...
        ax(4) * 0.90, condOrder(i), ...
        'Color', line_colors2(3,:), 'HorizontalAlignment', 'center',...
        'Interpreter', 'none');

    % Trial lines
    for j = 1:24
        xline(tpR{trialRidx((i-1)*24+j), 'pupil_timestamp'}, ...
            'Color', line_colors2(4,:), 'LineStyle', line_styles2{4});
    end
end
title('Right trials')

lgd2 = ["Experiment", "Interp+Filtered"];
legend(axR2, lgd2);

xlabel(tl_full, 'Timestamp');
ylabel(tl_full, 'Pupil diameter (mm)')
hold off
end