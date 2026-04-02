function f_avg = et_plotavg(waitAvg, dotAvg, restAvg, condOrder, opts)
%ETPLOTAVG Plot averaged segments
%   Plots average of 3 10s dot conditions, average of 24 trials for each of
%   baseline, threat_together, threat_alone (in that order if not
%   specified) and average of 3 10s rest conditions.

% Layout
%        ---     baseline    ---
% AvgDot --- threat_together --- AvgRest
%        ---   threat_alone  ---
%

arguments (Input)
    % Averaged data
    waitAvg
    dotAvg
    restAvg
    % Conditions as given
    condOrder
    % Optionals
    opts.err {mustBeTextScalar,mustBeMember(opts.err, {'sd', 'std', 'sem', 'se'})} = 'sem';
    opts.useCondOrder (1,3) {mustBeText} = "keep";
    opts.scale = 1;
    opts.showstats = 1;
    % Show normalized plots
    %opts.normalize = 0;
    opts.figure = []
end
if strcmpi(opts.useCondOrder, "keep")
    opts.useCondOrder = condOrder;
end

nBlocks = size(waitAvg, 1);
%nTrialsInBlock = size(truncTrials{1,1},1);

% Consts for now
buffer = 0.20;
% X axis with buffer
blLength = 10.10;
% Colors to use
eyeColors = {'k', 'r'};
%eyeColorsScale = repmat(linspace(0, 1, nTrialsInBlock+1)', 1, 3);
%eyeColorsScale(end, :) = [];

% Shuffle to order you want
waitTemp = cell(size(waitAvg));
numOrder = zeros(1,3);
for i = 1:numel(opts.useCondOrder)   
    whichRow = find(strcmpi(opts.useCondOrder(i), condOrder));
    numOrder(i) = whichRow;
    waitTemp{i,1} = waitAvg{whichRow, 1};
    waitTemp{i,2} = waitAvg{whichRow, 2};
end
waitAvg = waitTemp;

% Normalize
% if opts.normalize
%     for e = 1:2
%         dotAvg{e}.y_avg = dotAvg{e}.y_avg - mean(dotAvg{e}.y_avg);
%         restAvg{e}.y_avg = restAvg{e}.y_avg - mean(restAvg{e}.y_avg);
%         for b = 1:nBlocks
%             waitAvg{b,e}.y_avg = waitAvg{b,e}.y_avg - mean(waitAvg{b,e}.y_avg);
%         end
%     end
% end

if isempty(opts.figure)
    f_avg = figure;
elseif isnumeric(opts.figure)
    f_avg = figure(opts.figure);
else
    error('''figure'' argument should be integer or empty.');
end
tl_avg = tiledlayout(f_avg, 3, 3);

% Get limits
if opts.scale
    y_min = Inf;
    y_max = -Inf;
    for e = 1:2
        % Min, max of dot, for each eye
        y_min = min(y_min, min(dotAvg{e}.y_avg));
        y_max = max(y_max, max(dotAvg{e}.y_avg));
        % Min, max of rest, for each eye
        y_min = min(y_min, min(restAvg{e}.y_avg));
        y_max = max(y_max, max(restAvg{e}.y_avg));

        for b = 1:3
            y_min = min(y_min, min(waitAvg{b,e}.y_avg));
            y_max = max(y_max, max(waitAvg{b,e}.y_avg));
        end
    end
end
y_min = y_min - buffer;
y_max = y_max + buffer;

%% Dot
%nexttile(1);
%axis off;
nexttile(2);
plot(dotAvg{1}.x, dotAvg{1}.y_avg, eyeColors{1});
hold on
plot(dotAvg{2}.x, dotAvg{2}.y_avg, eyeColors{2});
if any(strcmpi(opts.err, {'sem', 'se'}))
    plot(dotAvg{1}.x, dotAvg{1}.y_avg + dotAvg{1}.y_sem, 'k:');
    plot(dotAvg{1}.x, dotAvg{1}.y_avg - dotAvg{1}.y_sem, 'k:');
    plot(dotAvg{2}.x, dotAvg{2}.y_avg + dotAvg{2}.y_sem, 'r:');
    plot(dotAvg{2}.x, dotAvg{2}.y_avg - dotAvg{2}.y_sem, 'r:');
elseif any(strcmpi(opts.err, {'std', 'sd'}))
    plot(dotAvg{1}.x, dotAvg{1}.y_avg + dotAvg{1}.y_std, 'k:');
    plot(dotAvg{1}.x, dotAvg{1}.y_avg - dotAvg{1}.y_std, 'k:');
    plot(dotAvg{2}.x, dotAvg{2}.y_avg + dotAvg{2}.y_std, 'r:');
    plot(dotAvg{2}.x, dotAvg{2}.y_avg - dotAvg{2}.y_std, 'r:');
end
title('Dot');
xlabel('s');
ylabel('Pupil diameter (mm)');
xlim([0, blLength]);
if opts.scale; ylim([y_min, y_max]); end

% Show mean and SD or SEM on graph
if opts.showstats
    dotAvg_all = zeros(2,2);
    dotAvg_all(1,1) = mean(dotAvg{1}.y_avg);    
    dotAvg_all(1,2) = mean(dotAvg{2}.y_avg);    

    dotstrL = "L dot: %.2fmm ";
    dotstrR = "R dot: %.2fmm ";
    
    if any(strcmpi(opts.err, {'sem', 'se'}))      
        dotAvg_all(2,1) = std(dotAvg{1}.y_avg) ./ sqrt(size(dotAvg{1},1));
        dotAvg_all(2,2) = std(dotAvg{2}.y_avg) ./ sqrt(size(dotAvg{2},1));
        dotstrL = dotstrL + "± %.4f SEM";
        dotstrR = dotstrR + "± %.4f SEM";
    elseif any(strcmpi(opts.err, {'std', 'sd'}))
        dotAvg_all(2,1) = std(dotAvg{1}.y_avg);
        dotAvg_all(2,2) = std(dotAvg{2}.y_avg);
        dotstrL = dotstrL + "± %.4f SD";
        dotstrR = dotstrR + "± %.4f SD";
    %else
    end
    dotstrL = sprintf(dotstrL, dotAvg_all(1,1), dotAvg_all(2,1));
    dotstrR = sprintf(dotstrR, dotAvg_all(1,2), dotAvg_all(2,2));
    % Put text beyond axes
    text(1.1*dotAvg{1}{end, "x"}, dotAvg_all(1,1), dotstrL, Color=eyeColors{1});
    text(1.1*dotAvg{2}{end, "x"}, dotAvg_all(1,2), dotstrR, Color=eyeColors{2});
    
end
%nexttile(3);
%axis off;

%% Wait, average
for t = 1:3
    nexttile(3+t);
    plot(waitAvg{t, 1}.x, waitAvg{t, 1}.y_avg, eyeColors{1});
    hold on
    plot(waitAvg{t, 2}.x, waitAvg{t, 2}.y_avg, eyeColors{2});
    if any(strcmpi(opts.err, {'sem', 'se'}))
        plot(waitAvg{t,1}.x, waitAvg{t,1}.y_avg + waitAvg{t,1}.y_sem, 'k:');
        plot(waitAvg{t,1}.x, waitAvg{t,1}.y_avg - waitAvg{t,1}.y_sem, 'k:');
        plot(waitAvg{t,2}.x, waitAvg{t,2}.y_avg + waitAvg{t,2}.y_sem, 'r:');
        plot(waitAvg{t,2}.x, waitAvg{t,2}.y_avg - waitAvg{t,2}.y_sem, 'r:');
    elseif any(strcmpi(opts.err, {'std', 'sd'}))
        plot(waitAvg{t,1}.x, waitAvg{t,1}.y_avg + waitAvg{t,1}.y_std, 'k:');
        plot(waitAvg{t,1}.x, waitAvg{t,1}.y_avg - waitAvg{t,1}.y_std, 'k:');
        plot(waitAvg{t,2}.x, waitAvg{t,2}.y_avg + waitAvg{t,2}.y_std, 'r:');
        plot(waitAvg{t,2}.x, waitAvg{t,2}.y_avg - waitAvg{t,2}.y_std, 'r:');
    end
    title(regexprep(opts.useCondOrder(t), '_', ' ') + ' ' + numOrder(t));
    xlabel('s');
    ylabel('Pupil diameter (mm)');
    if opts.scale; ylim([y_min, y_max]); end

    % Show mean and SD or SEM on graph
if opts.showstats
    waitAvg_all = zeros(2,2);
    waitAvg_all(1,1) = mean(waitAvg{t,1}.y_avg);    
    waitAvg_all(1,2) = mean(waitAvg{t,2}.y_avg);    

    waitstrL = "L dot: %.2fmm ";
    waitstrR = "R dot: %.2fmm ";
    
    if any(strcmpi(opts.err, {'sem', 'se'}))      
        waitAvg_all(2,1) = std(waitAvg{t,1}.y_avg) ./ sqrt(size(waitAvg{t,1},1));
        waitAvg_all(2,2) = std(waitAvg{t,2}.y_avg) ./ sqrt(size(waitAvg{t,2},1));
        waitstrL = waitstrL + "± %.4f SEM";
        waitstrR = waitstrR + "± %.4f SEM";
    elseif any(strcmpi(opts.err, {'std', 'sd'}))
        waitAvg_all(2,1) = std(waitAvg{t,1}.y_avg);
        waitAvg_all(2,2) = std(waitAvg{t,2}.y_avg);
        waitstrL = waitstrL + "± %.4f SD";
        waitstrR = waitstrR + "± %.4f SD";
    %else
    end
    waitstrL = sprintf(waitstrL, waitAvg_all(1,1), waitAvg_all(2,1));
    waitstrR = sprintf(waitstrR, waitAvg_all(1,2), waitAvg_all(2,2));
    % Put text beyond axes
    text(0, 0.85*y_min, waitstrL, Color=eyeColors{1});
    text(0, 0.75*y_min, waitstrR, Color=eyeColors{2});
    % Test: show mean
    % yline(waitAvg_all(1,1), Color='g');
    % yline(waitAvg_all(1,2), Color='g');
end
end

% %% Wait, all
% for t = 1:3
%     nexttile(6+t);
%     for tt = 1:nTrialsInBlock
%         plot(truncTrials{t, 1}{tt}.x, truncTrials{t, 1}{tt}.diameter_3d_filt, ...
%             Color=eyeColorsScale(tt, :));
%         hold on
%         plot(truncTrials{t, 2}{tt}.x, truncTrials{t, 2}{tt}.diameter_3d_filt, ...
%             Color=eyeColorsScale(tt, :).*[1 0 0]);
%     end
% end
    

%% Rest
%nexttile(7);
%axis off;
nexttile(8);
plot(restAvg{1}.x, restAvg{1}.y_avg, eyeColors{1});
hold on
plot(restAvg{2}.x, restAvg{2}.y_avg, eyeColors{2});
if any(strcmpi(opts.err, {'sem', 'se'}))
    plot(restAvg{1}.x, restAvg{1}.y_avg + restAvg{1}.y_sem, 'k:');
    plot(restAvg{1}.x, restAvg{1}.y_avg - restAvg{1}.y_sem, 'k:');
    plot(restAvg{2}.x, restAvg{2}.y_avg + restAvg{2}.y_sem, 'r:');
    plot(restAvg{2}.x, restAvg{2}.y_avg - restAvg{2}.y_sem, 'r:');
elseif any(strcmpi(opts.err, {'std', 'sd'}))
    plot(restAvg{1}.x, restAvg{1}.y_avg + restAvg{1}.y_std, 'k:');
    plot(restAvg{1}.x, restAvg{1}.y_avg - restAvg{1}.y_std, 'k:');
    plot(restAvg{2}.x, restAvg{2}.y_avg + restAvg{2}.y_std, 'r:');
    plot(restAvg{2}.x, restAvg{2}.y_avg - restAvg{2}.y_std, 'r:');
end
title('Rest');
xlabel('s');
ylabel('Pupil diameter (mm)');
xlim([0, blLength]);
if opts.scale; ylim([y_min, y_max]); end

% Show mean and SD or SEM on graph
if opts.showstats
    restAvg_all = zeros(2,2);
    restAvg_all(1,1) = mean(restAvg{1}.y_avg);    
    restAvg_all(1,2) = mean(restAvg{2}.y_avg);    

    reststrL = "L rest: %.2fmm ";
    reststrR = "R rest: %.2fmm ";
    
    if any(strcmpi(opts.err, {'sem', 'se'}))      
        restAvg_all(2,1) = std(restAvg{1}.y_avg) ./ sqrt(size(restAvg{1},1));
        restAvg_all(2,2) = std(restAvg{2}.y_avg) ./ sqrt(size(restAvg{2},1));
        reststrL = reststrL + "± %.4f SEM";
        reststrR = reststrR + "± %.4f SEM";
    elseif any(strcmpi(opts.err, {'std', 'sd'}))
        restAvg_all(2,1) = std(restAvg{1}.y_avg);
        restAvg_all(2,2) = std(restAvg{2}.y_avg);
        reststrL = reststrL + "± %.4f SD";
        reststrR = reststrR + "± %.4f SD";
    %else
    end
    reststrL = sprintf(reststrL, restAvg_all(1,1), restAvg_all(2,1));
    reststrR = sprintf(reststrR, restAvg_all(1,2), restAvg_all(2,2));
    % Put text beyond axes
    text(1.1*restAvg{1}{end, "x"}, restAvg_all(1,1), reststrL, Color=eyeColors{1});
    text(1.1*restAvg{2}{end, "x"}, restAvg_all(1,2), reststrR, Color=eyeColors{2});
    
end


lgd = legend({'Left', 'Right'},'Orientation',"horizontal");
lgd.Layout.Tile = 'south';
end