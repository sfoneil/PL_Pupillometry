function et_main_analysis(subjectID, markerFile, opts)
%ET_MAIN_ANALYIS Main function for running pupilometry
%   Input:
%       subjectID: char or string. ID correspoding to folder within
%           \Results_data\
%       markerFile: char or string. Filename of .xlsx file output by MATLAB
%           experiment containing timing information.

arguments
    % Required in this order
    subjectID {mustBeTextScalar}
    markerFile {mustBeTextScalar}

    % Optionals, use name="value" notation to change these. Current
    % defaults set up for intended values from et_start()



    %%%%%%% Preprocessing %%%%%%%

    % Remove periods outside of experiment window
    opts.removeExcess = 1;
    % Use Pupil Lab's confidence rating
    opts.removeConf = 1;
    % Their recommended threshold, won't do anything if removeConf==0
    opts.confidenceThreshold = 0.6;

    % Do initial cleaning steps %
    opts.cleanit = 1;

    % Detect and remove blinks
    opts.removeBlinks = 1;
    % 0==just remove periods identified as blinks by PL
    % 1==Use Nystrom pre/post window
    % Won't do anything if removeBlinks==0
    opts.useBlinkWindow = 1;

    % Interpolate after blink detection
    opts.doInterp = 1;
    %scaleXAxis = 0; % ON: truncate periods to match shortest period.
    
    % Get average of same conditions
    opts.doAvg = 1;
    % Seconds to average
    opts.avgSecs = 2;
    % Do/display statistics
    opts.doStats = 0;

    %%%%%%% Plots %%%%%%%
    % Display plots. Some will not work if "do" steps above aren't run.
    opts.plotRaw = 1;
    opts.plotSeg = 1;
    opts.plotAvg = 0;

    % Autosave .png to \Plots\
    opts.savePlots = 1;

end

% Define locally for readability
removeExcess = opts.removeExcess;
removeConf = opts.removeConf;
confidenceThreshold = opts.confidenceThreshold;
cleanit = opts.cleanit;
removeBlinks = opts.removeBlinks;
useBlinkWindow = opts.useBlinkWindow;
doInterp = opts.doInterp;
doAvg = opts.doAvg;
avgSecs = opts.avgSecs;
doStats = opts.doStats;
plotRaw = opts.plotRaw;
plotSeg = opts.plotSeg;
plotAvg = opts.plotAvg;
savePlots = opts.savePlots;

% Notes:
% EYE0 = right
% EYE1 = left

% todo:
%adjust peak parameters - MinDistance?
%heat map for peak mms - where do they cluster?
%fix interpolation

%FINDPEAKS notes
% MinPeakDistance - min acceptable peak separations (X)
% MinPeakHeight - height over 0 (Y)
% MinPeakProminence - min drop between neighbors(Y)
% Threshold - over nearest neighbors (Y)
% Annotate

close all
screen_size = get(0, 'screensize');

%% Subject vars to change as needed
% Need to define a subjectPath, trialPath, markerFile for each run
% Some runs have 1 trialPath with 3 markerFiles, representing that Pupil
% Player was run in one session with 3 MATLAB conditions (e.g. PSB in file
% name means Partner was run first, then Stranger, then Ball).
% Other times there may be 2 or more Pupil Player recordings and therefore
% 2 or more trialPath links. One of more markerFiles may be associated to
% either one. Therefore, only uncomment the last one you want to use.

% Where data is stored, should only rarely change
baseDataPath = 'Results_data';
funcPath = 'subfunctions';
addpath(funcPath);

% if nargin < 3
%     % Use default
%     warning('Subject ID not specified, selecting first subject.')
%     subjectPath = 'P1_12.18.25';
%     trialPath = 'P1_ARSL_312_12.18.25';
%     markerFile = '2025-12-18_1916_TESS_P1_Arousal_new_conds-312_rand-312.xlsx';
% end

% Useful data columns to simplify large Pupil-Labs data file
columnsToUse = ["pupil_timestamp", "world_index", "eye_id", "diameter_3d", "confidence", "model_confidence"];

%% OPTIONS

% Should be const for this experiment
nBlocks = 3;
nTrialsInBlock = 24;
nTrialsTotal = nBlocks * nTrialsInBlock;
fs = 120;


%nBlocks = 48;
nPerFigure = 1; % So with 48 it will make 3 figures...



%buffer = 0.5; % Whitespace to add to plots
% fs = 124; % SR of pupil cams, not world cam
% analysisWindow = [2.5 5.0].*fs; % Window to average around, separate from total average
% restWindow = [(8*fs)-(baselineTime*fs), 8*fs];

% Constant to remove before and after identified blinks per Winn (2018)
% We will use [-50 150] which in samples is [-6, 18]
blink_window = [-50 150] * fs / 1000;
baselineTime = 1; % Only used in next line, last second of rest==baseline

% Options for peaks, change up here
peakopts = struct;
% MinPeakHeight: should be changed dynamically, here for reference
%peakopts.MPH = avg_left(t);
% MinPeakProminence: tweak this (DEFAULT 0.1)
peakopts.MinPeakProminence = 0.05; % Prominence
% MinPeakDistance: X separation, units of seconds if using x_ant_left,right
peakopts.MinPeakDistance = 0.5;
% NPeaks: find the N most prominent (DEFAULT 5)
peakopts.NPeaks = 100;
% SortStr: DEFAULT 'descend'. Shouldn't need to change, this sorts them by
% the most prominent first. Works in conjunction with NPeaks.
peakopts.SortStr = 'descend';

%% Load files
pupilPath = string(fullfile(pwd, baseDataPath, subjectID, 'pupil_positions.csv'));
markerPath = string(fullfile(pwd, baseDataPath, subjectID, markerFile));
blinkPath = string(fullfile(pwd, baseDataPath, subjectID, 'blinks.csv'));

trialT = readtable(markerPath, 'Sheet', 'Trials', 'Range', "E1:J" + num2str(nTrialsTotal+1));
fulltrialT = readtable(markerPath, 'Sheet', 'FullTrial');
summaryT = readtable(markerPath, 'Sheet', 'Summary'); % StartTime is pretty worthless, before KbWait...

% Get limits of conditions
expStart = fulltrialT{1, 'PLTrialTime'};
dotTimes = readtable(markerPath, 'Sheet', 'Trials', 'Range', 'A1:D4');
waitTimes = readtable(markerPath, 'Sheet', 'Trials', 'Range', 'G1:J73');
% Test if newer version of Arousal_new
%audioTest = table2array(readtable(markerPath, 'Sheet', 'Trials', 'Range', 'O4:R1'));
audioTest = table2array(readtable(markerPath, 'Sheet', 'Trials', 'Range', 'O1:R4'));
if all(isnan(audioTest(:)))
    warning('Identified old file without audio times.');
    restTimes = readtable(markerPath, 'Sheet', 'Trials', 'Range', 'K1:N4');
    audioTimes = table(repmat(4, nTrialsTotal, 1), ...
        waitTimes{:, 2} + 4, ...
        waitTimes{:,4}, ...
        waitTimes{:,4} + 4, ...
        'VariableNames', ["MLAudioTime", "MLAudioFromStart", "PLAudioTime", "PLAudioFromStart"]);
elseif all(isnumeric(audioTest(:)))
    warning('Identified new file with audio times.');
    audioTimes = readtable(markerPath, 'Sheet', 'Trials', 'Range', 'K1:N73');
    restTimes = readtable(markerPath, 'Sheet', 'Trials', 'Range', 'O1:R4');
else
    error('Issue with loading audio times.')
end
%restTimes = readtable(markerPath, 'Sheet', 'Trials', 'Range', 'K1:N4');
expEnd = fulltrialT{3, 'PLTrialFromStart'}; % or summaryT('EndTime') ?

% Load sounds, add column and name sounds
sounds = readtable(markerPath, 'Sheet', 'Trials', 'Range', 'E1:F73');
soundsN = string(sounds{:, 'Condition'}); % Make string
soundsN(strcmp(soundsN, 'baseline')) = "water";
soundsN(strcmp(soundsN, 'threat_together')) = "scream";
soundsN(strcmp(soundsN, 'threat_alone')) = "scream";
soundsN = table(soundsN + sounds.Sound, 'VariableNames', {'SoundFile'});
sounds = [sounds, soundsN];

% Total experiment duration. Should be close...
% pl_exptDuration = endDotTrials{3, "PLRestFromStart"} - startDotTrials{1, "PLWaitTime"};
% ml_exptDuration = endDotTrials{3, "MLRestFromStart"} - startDotTrials{1, "MLWaitFromStart"} + startDotTrials{1,"MLWaitTime"};
% pl_expt2 = fulltrialT{3, "PLTrialFromStart"} - fulltrialT{1, "PLTrialTime"};
%ml_expt2 = fulltrialT{3, "MLTrialFromStart"}; %?
%ts = 0:1/fs:pl_expt2;

condOrder = string([trialT.Condition(1), trialT.Condition(nTrialsInBlock+1), trialT.Condition(nTrialsInBlock*2+1)]);

% Read whole table
t_all = readtable(pupilPath);

% Extract columns
tp = t_all(:, columnsToUse);
szRaw = size(unique(tp.pupil_timestamp),1);

% Omit rows that don't use diameter_3d and therefore have nan
tp = tp(~any(ismissing(tp),2),:);

% Init conditions
conditionT = table(strings(size(tp,1), 1), 'VariableNames', {'Condition'});

for i = 1:nBlocks
    blockStart = dotTimes.PLDotTime(i);
    blockEnd = restTimes.PLRestFromStart(i);
    blockIdx = knnsearch(tp.pupil_timestamp, [blockStart; blockEnd]);

    % Mark blocks as condition
    conds = repmat(condOrder(i), blockIdx(2)-blockIdx(1)+1, 1);
    conditionT{blockIdx(1):blockIdx(2), 1} = conds;
end

% Add condition column in
tp = [tp conditionT];
tp_rawL = tp(tp.eye_id==0, :);
tp_rawR = tp(tp.eye_id==1, :);

% Remove time outside trials (e.g. setup, calibration)
if removeExcess
    expIdx = knnsearch(tp.pupil_timestamp, [expStart; expEnd]);
    tpTrim = tp(expIdx(1):expIdx(2), :);

    expIdxL = knnsearch(tp_rawL.pupil_timestamp, [expStart; expEnd]);
    tpL = tp_rawL(expIdxL(1):expIdxL(2), :);

    expIdxR = knnsearch(tp_rawR.pupil_timestamp, [expStart; expEnd]);
    tpR = tp_rawR(expIdxR(1):expIdxR(2), :);
else
    % Copy them if removeExcess is off
    tpL = tp_rawL;
    tpR = tp_rawR;
end
szDuringExpt = [size(unique(tp.pupil_timestamp),1), ...
    size(unique(tpL.pupil_timestamp),1), ...
    size(unique(tpR.pupil_timestamp),1)];

% Time differences
diff_left = 1./(diff(tpL.pupil_timestamp));
diff_right = 1./(diff(tpR.pupil_timestamp));
fprintf('Left diffs: %.4f (SD: %.4f), range: %.4f to %.4f\n', ...
    mean(diff_left), std(diff_left), min(diff_left), max(diff_left));
fprintf('Right diffs: %.4f (SD: %.4f), range: %.4f to %.4f\n', ...
    mean(diff_right), std(diff_right), min(diff_right), max(diff_right));

%fs = mean([mean(diff_left), mean(diff_right)]); % SR of pupil cams, not world cam

%% Filter on confidence rating by Pupil-Labs, they recommend 0.6

% Back up
tpLPreConf = tpL;
tpRPreConf = tpR;
szLeft = size(unique(tpL.pupil_timestamp),1);
szRight = size(unique(tpR.pupil_timestamp),1);

if removeConf
    tpL = tpL(tpL.confidence >= confidenceThreshold, :);
    tpR = tpR(tpR.confidence >= confidenceThreshold, :);
end

szLeftConf = size(unique(tpL.pupil_timestamp),1);
szRightConf = size(unique(tpR.pupil_timestamp),1);

%% Identify blinks
if cleanit
    % Nystrom et al. (2023) What is a blink? Classifying and characterizing blinks in eye openness signals
    % Pupil diameter has high correlation with other measures like EOG or video

    blinks = readtable(blinkPath);
    blinks = blinks(:, ["id", "start_timestamp", "duration", "end_timestamp"]);

    % Remove blinks that were outside experiment from BLINK VAR
    if removeExcess
        % Old method, for error checking. Comment out if slow.
        blinksStartFunc = @(x) min(abs(blinks{:,'start_timestamp'} - x));
        blinksEndFunc = @(x) min(abs(blinks{:,'end_timestamp'} - x));
        [~, blinksStartIdx] = arrayfun(blinksStartFunc, expStart);
        [~, blinksEndIdx] = arrayfun(blinksStartFunc, expEnd);
        %[~, blinksEndIdx2] = arrayfun(blinksEndFunc, expEnd);

        % New method, knn
        blinksIdx = knnsearch(blinks.start_timestamp, [expStart; expEnd]);
        blinksEndIdx2 = knnsearch(blinks.end_timestamp, expEnd);
        % Test that end matches start
        if blinksStartIdx > blinksIdx(2) || ...
                isempty(blinksStartIdx) || isempty(blinksEndIdx)
            error('Blinks not properly detected.');
        end
        % assert(blinksEndIdx == blinksEndIdx2, 'Blink ends don''t match. Which to use?');
        % assert(blinksIdx(2) == blinksEndIdx2, 'Blink ends don''t match. Which to use?');

        blinks = blinks(blinksIdx(1):blinksIdx(2),:);
    end

    % Get indices for each blink, 2 col for start and stop
    idxLBlinks = [knnsearch(tpL.pupil_timestamp, blinks.start_timestamp), ...
        knnsearch(tpL.pupil_timestamp, blinks.end_timestamp)];
    idxRBlinks = [knnsearch(tpR.pupil_timestamp, blinks.start_timestamp), ...
        knnsearch(tpR.pupil_timestamp, blinks.end_timestamp)];

    % Error check differences
    diffLBlinks = tpL{idxLBlinks(:,1), "pupil_timestamp"} - blinks.start_timestamp;
    diffRBlinks = tpR{idxRBlinks(:,1), "pupil_timestamp"} - blinks.start_timestamp;
    fprintf('\n');
    fprintf('Left blinks knn: (%.4f to %.4f), mean=%.4f, sd=%.4f\n', ...
        max(diffLBlinks), min(diffLBlinks), mean(diffLBlinks), std(diffLBlinks));
    fprintf('Right blinks knn: (%.4f to %.4f), mean=%.4f, sd=%.4f\n', ...
        max(diffRBlinks), min(diffRBlinks), mean(diffRBlinks), std(diffRBlinks));
    warning('Left and right are %.2f%% ratio.\n', mean(diffLBlinks)/mean(diffRBlinks));

    % Set threshold for knn @ 110%
    warning('Setting new blink thresholds: 110% of ± mean.');
    blinkThresh = 1.1 * abs(mean([mean(diffLBlinks), mean(diffRBlinks)]));
    idxLExtreme = (diffLBlinks > blinkThresh) | (diffLBlinks < -blinkThresh);
    idxRExtreme = (diffRBlinks > blinkThresh) | (diffRBlinks < -blinkThresh);

    % And remove
    idxLBlinks(idxLExtreme,:) = [];
    idxRBlinks(idxRExtreme,:) = [];

    if useBlinkWindow
        % Apply Nystrom window
        idxLBlinks = idxLBlinks + blink_window;
        idxRBlinks = idxRBlinks + blink_window;
    end

    % Mask out
    blinksL = zeros(size(tpL, 1), 1);
    for bl = 1:size(idxLBlinks,1)
        blinksL(idxLBlinks(bl, 1):idxLBlinks(bl, 2)) = 1;
    end

    blinksR = zeros(size(tpR, 1), 1);
    for bl = 1:size(idxRBlinks,1)
        blinksR(idxRBlinks(bl, 1):idxRBlinks(bl, 2)) = 1;
    end

    % % Obsolete: max(blinksL)==2 for Nystrom?
    % % Create initial mask, starts==1 stops==-1
    % blinksL = accumarray([idxLBlinks(:, 1); idxLBlinks(:, 2)+1], ...
    %     [ones(size(idxLBlinks(:, 1))); -ones(size(idxLBlinks(:, 1)))], ...
    %     [size(tpL,1)+1, 1]);
    %
    % % Convert to blink == 1, no blink == 0
    % blinksL = cumsum(blinksL);
    %
    % % Need to remove last?
    % blinksL(end) = [];
    %
    % blinksR = accumarray([idxRBlinks(:, 1); idxRBlinks(:, 2)+1], ...
    %     [ones(size(idxRBlinks(:, 1))); -ones(size(idxRBlinks(:, 1)))], ...
    %     [size(tpR,1)+1, 1]);
    % blinksR = cumsum(blinksR);
    % blinksR(end) = [];

    % Make 2 versions, for plotting and masking
    blinksLmask = blinksL;
    blinksRmask = blinksR;
    blinksLmask(blinksLmask==1) = nan;
    blinksRmask(blinksRmask==1) = nan;
    blinksLmask(blinksLmask==0) = 1;
    blinksRmask(blinksRmask==0) = 1;
    blinksL(blinksL==0) = nan;
    blinksR(blinksR==0) = nan;

    tpL = [tpL, table(blinksL, 'VariableNames', {'BlinkPeriods'})];
    tpR = [tpR, table(blinksR, 'VariableNames', {'BlinkPeriods'})];

    % Remove blinks from data
    if removeBlinks
        debL = tpL.diameter_3d .* blinksLmask;
        debR = tpR.diameter_3d .* blinksRmask;
        tpL = addvars(tpL, debL, 'NewVariableNames', 'diameter_3d_noblink', 'Before', 'confidence');
        tpR = addvars(tpR, debR, 'NewVariableNames', 'diameter_3d_noblink', 'Before', 'confidence');
    end

    %% Interpolate

    if doInterp
        intL = fillmissing(tpL.diameter_3d_noblink, 'linear');
        intR = fillmissing(tpR.diameter_3d_noblink, 'linear');
        tpL = addvars(tpL, intL, 'NewVariableNames', 'diameter_3d_interp', 'Before', 'confidence');
        tpR = addvars(tpR, intR, 'NewVariableNames', 'diameter_3d_interp', 'Before', 'confidence');
    end

    %% Filter, lowpass at 10 Hz

    filtL = lowpass(intL, 10, fs);
    filtR = lowpass(intR, 10, fs);

    % Make table
    tpL = addvars(tpL, filtL, 'NewVariableNames', 'diameter_3d_filt', 'Before', 'confidence');
    tpR = addvars(tpR, filtR, 'NewVariableNames', 'diameter_3d_filt', 'Before', 'confidence');

else

end

%% Segmenting & Averaging

% 1) First trials only: 2 seconds
% 2) Segment anticipation (wait)
% 3) Peri-scream: 4s during scream
[segWait, blockEdgesWait, waitLidx, waitRidx] = et_segment('wait', tpL, tpR, waitTimes, condOrder);
[segAudio, blockEdgesAudio, audioLidx, audioRidx] = et_segment('audio', tpL, tpR, audioTimes, condOrder);
[segDot, segRest] = et_segmentbl(tpL, tpR, dotTimes, restTimes);

% Truncate to last 3 seconds
if doAvg
    % Take first 2 seconds of each
    truncTrials = et_truncseg(segWait, avgSecs);
    % Get the first trial from each
    first2sTrials = {truncTrials{1,1}{1}, truncTrials{1,2}{1}; ...
        truncTrials{2,1}{1}, truncTrials{2,2}{1}; ...
        truncTrials{3,1}{1}, truncTrials{3,2}{1}};
    waitAvg = et_average(truncTrials);
    dotAvg = et_blaverage(segDot);
    restAvg = et_blaverage(segRest);
else
    truncTrials = segWait;
end

%% Plot raw

if plotRaw
    % Package the variables, to be fixed
    opts.subjectPath = subjectID;
    opts.removeExcess = removeExcess;
    opts.removeConf = removeConf;
    opts.removeBlinks = removeBlinks;
    opts.confidenceThreshold = confidenceThreshold;
    opts.useBlinkWindow = useBlinkWindow;
    opts.blockEdges = blockEdgesWait;
    opts.condOrder = condOrder;
    opts.stacked = 1;

    % Final, raw outside experiment, pre-conf
    f_raw = et_plotraw({tpL, tpR, tp_rawL, tp_rawR, tpLPreConf, tpRPreConf, waitLidx, waitRidx}, opts);
end

%% Plot segmented

if plotSeg
    f_wait = et_plotseg('wait', truncTrials, condOrder, sounds, redoAxes=1, title_header="Anticipation");
    f_audio = et_plotseg('audio', segAudio, condOrder, sounds, redoAxes=1, title_header="Audio 4s");
end

if plotAvg
    f_avg = et_plotavg(waitAvg, dotAvg, restAvg, condOrder, ...
        err="sem", useCondOrder=["baseline", "threat_alone", "threat_together"], ...
        figure=5);
end

% Display some diagnostic length information
fprintf('\n');
fprintf('Size of raw table: %d (approx %5.4fs)\n', szRaw, szRaw/fs);
if removeExcess
    fprintf('Experiment period, Left = %.4fs, Right = %.fs\n', szDuringExpt(2), szDuringExpt(3));
end
if removeConf
    fprintf('Left after confidence: %d (approx %.4fs)\n', szLeftConf, szLeft/fs);
    fprintf('Right after confidence: %d (approx %.4fs)\n', szRightConf, szRight/fs);
end

%% Save

if savePlots
    fmt = ".png";
    saveDir = fullfile(pwd, "Plots");
    if plotRaw
        exportgraphics(f_raw, saveDir + filesep + subjectID + " raw" + fmt);
    end
    if plotSeg
        for p = 1:3
            exportgraphics(f_wait{p}, saveDir + filesep + subjectID + " " + condOrder(p) + fmt)
        end
    end
    if plotAvg
        exportgraphics(f_avg, saveDir + filesep + subjectID + " average" + fmt)
    end
    fprintf('\n');
    fprintf('Plots saved...\n');
    fprintf('\n');
end

%% Statistics

% Per trial
% Init tables
if doStats
    conditionsX = repelem(condOrder', nTrialsInBlock+2, 1); % +2
    trialsX = repmat(["Dot"; num2str((1:nTrialsInBlock)'); "Rest"], nBlocks, 1);
    zerosY = zeros((nTrialsInBlock+2)*nBlocks, 1);
    dataL = repmat(zerosY, 1, 3);
    dataR = dataL;

    ct = 1;
    for b = 1:nBlocks
        for t = 1:nTrialsInBlock
            % Left
            data = truncTrials{b, 1}{t}.diameter_3d_filt;
            m = mean(data);
            s = std(data);
            sem = s./sqrt(numel(data));
            dataL(ct, 1) = m;
            dataL(ct, 2) = s;
            dataL(ct, 3) = sem;

            % Right
            data = truncTrials{b, 2}{t}.diameter_3d_filt;
            m = mean(data);
            s = std(data);
            sem = s./sqrt(numel(data));
            dataR(ct, 1) = m;
            dataR(ct, 2) = s;
            dataR(ct, 3) = sem;

            ct = ct + 1;
        end
    end
    descL = table(conditionsX, trialsX, dataL(:,1), dataL(:,2), dataL(:,3), ...
        'VariableNames', ["Condition", "Trial", "Mean", "SD", "SEM"]);
    descR = table(conditionsX, trialsX, dataR(:,1), dataR(:,2), dataR(:,3), ...
        'VariableNames', ["Condition", "Trial", "Mean", "SD", "SEM"]);

    % Per condition
    means = zeros(nBlocks, 2);
    sds = zeros(nBlocks, 2);
    sems = zeros(nBlocks, 2);
    for e = 1:2
        for b = 1:nBlocks
            data = [];
            for t = 1:nTrialsInBlock
                currTrial = truncTrials{b, e}{t};
                data = [data; currTrial.diameter_3d_filt];
            end
            means(b, e) = mean(data);
            sds(b,e) = std(data);
            sems(b,e) = sds(b,e)./numel(data);
        end
    end

    % All data
    allData = table;
    for b = 1:nBlocks
        blockData = [];
        for t = 1:nTrialsInBlock
            currDataL = truncTrials{b, 1}{t}.diameter_3d_filt;
            currDataR = truncTrials{b, 2}{t}.diameter_3d_filt;
            blockData = [blockData; currDataL, currDataR];
        end
        cc = repmat(condOrder(b), size(blockData, 1), 1);
        allData = [allData; table(cc, blockData(:,1), blockData(:,2))];
    end
    allData.Properties.VariableNames = ["Condition", "Left", "Right"];

    % Stats
    idx_bl = strcmpi(allData.Condition,"baseline");
    idx_ta = strcmpi(allData.Condition,"threat_alone");
    idx_tt = strcmpi(allData.Condition,"threat_together");

    hs = zeros(3,2);
    ps = zeros(3,2);
    ts = zeros(3,2);

    for eye = 1:2
        [h,p,ci,stats] = ttest(allData{idx_bl, eye+1}, allData{idx_ta, eye+1});
        hs(1,eye) = h;
        ps(1,eye) = p;
        ts(1,eye) = stats.tstat;

        [h,p,ci,stats] = ttest(allData{idx_bl, eye+1}, allData{idx_tt, eye+1});
        hs(2,eye) = h;
        ps(2,eye) = p;
        ts(2,eye) = stats.tstat;

        [h,p,ci,stats] = ttest(allData{idx_ta, eye+1}, allData{idx_tt, eye+1});
        hs(3,eye) = h;
        ps(3,eye) = p;
        ts(3,eye) = stats.tstat;
    end
end

end