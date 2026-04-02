function [segTrials, blockEdges, trialLidx, trialRidx] = et_segment(segType, tpL, tpR, timestamps, condOrder)
%ETSEGMENT Segment eye tracking data on events
%   Inputs:
%       segType: 'wait' or 'audio'
%       tpL, tpR: eye tracking blocks
%       timestamp: 72x4 table, also 3rd and 4th column, rows are 24 per block
%       condOrder:
%   Output:
%       segTrials: 3x2 cell, Contents is 24x1 cell
%           These contents are Nx12 segments, with new column 'x' for time
%           0:max
%       blockEdges: 6x2 double, odd rows == start of each block, 
%       even rows == end of each block, columns == eye
%       trialLidx, trialRidx = indices of each trial

arguments
    segType {mustBeMember(segType, {'wait', 'audio'})}
    tpL
    tpR
    timestamps
    condOrder
end

nBlocks = length(condOrder);
nTrialsInBlock = size(timestamps, 1)/nBlocks;
% Find span of 3 blocks
blockEdges = zeros(6,2);
for i = 1:3
    % Find first and last for each condition
    blockEdges(i*2-1, 1) = find(strcmp(condOrder(i), tpL.Condition),1);
    blockEdges(i*2, 1) = find(strcmp(condOrder(i), tpL.Condition),1, "last");
    blockEdges(i*2-1, 2) = find(strcmp(condOrder(i), tpR.Condition),1);
    blockEdges(i*2, 2) = find(strcmp(condOrder(i), tpR.Condition),1, "last");
end

if strcmpi(segType, 'wait')
    starttimes = timestamps.PLWaitTime; %trialT.PLWaitTime;
    stoptimes = timestamps.PLWaitFromStart;% == trialT.PLWaitFromStart;
elseif strcmpi(segType, 'audio')
    starttimes = timestamps.PLAudioTime;
    stoptimes = timestamps.PLAudioFromStart;
end

% These are same as above
trialLidx = [knnsearch(tpL.pupil_timestamp, starttimes), ...
    knnsearch(tpL.pupil_timestamp, stoptimes)];
trialRidx = [knnsearch(tpR.pupil_timestamp, starttimes), ...
    knnsearch(tpR.pupil_timestamp, stoptimes)];

waitDiffs = stoptimes - starttimes;
fprintf('Waits were displayed for %2.4f s (SD = %2.4f s). Range: %d to %d\n', ...
    mean(waitDiffs), std(waitDiffs), round(min(waitDiffs)), round(max(waitDiffs)));

% Init
segBlocks = cell(nBlocks, 2);
segTrials = cell(nBlocks, 2); % Will be nested


for b = 1:nBlocks
    % Segment blocks from start to finish
    segBlocks{b, 1} = tpL(blockEdges(b*2-1, 1):blockEdges(b*2,1), :);
    segBlocks{b, 2} = tpR(blockEdges(b*2-1, 2):blockEdges(b*2,2), :);

    segTrials{b, 1} = cell(nTrialsInBlock, 1);
    segTrials{b, 2} = cell(nTrialsInBlock, 1);
    trial_idxL = [];
    trial_idxR = [];

    % Redefine [start stop], these may be redundant but error checking...
    currTrialStarts = starttimes(b*nTrialsInBlock-(nTrialsInBlock-1): ...
        b*nTrialsInBlock);
    currTrialStops = stoptimes(b*nTrialsInBlock-(nTrialsInBlock-1): ...
        b*nTrialsInBlock);
    trial_idxL = [trial_idxL;
        knnsearch(segBlocks{b, 1}.pupil_timestamp, currTrialStarts), ...
        knnsearch(segBlocks{b, 1}.pupil_timestamp, currTrialStops)];
    trial_idxR = [trial_idxR;
        knnsearch(segBlocks{b, 2}.pupil_timestamp, currTrialStarts), ...
        knnsearch(segBlocks{b, 2}.pupil_timestamp, currTrialStops)];

    % Segment
    for t = 1:nTrialsInBlock
        segTrials{b, 1}{t} = segBlocks{b, 1}(trial_idxL(t,1):trial_idxL(t,2), :);
        segTrials{b, 2}{t} = segBlocks{b, 2}(trial_idxR(t,1):trial_idxR(t,2), :);
        x = segTrials{b, 1}{t}.pupil_timestamp - segTrials{b, 1}{t}{1, 'pupil_timestamp'};
        segTrials{b, 1}{t} = addvars(segTrials{b, 1}{t}, x, 'NewVariableNames', 'x', 'After', 'pupil_timestamp');
        x = segTrials{b, 2}{t}.pupil_timestamp - segTrials{b, 2}{t}{1, 'pupil_timestamp'};
        segTrials{b, 2}{t} = addvars(segTrials{b, 2}{t}, x, 'NewVariableNames', 'x', 'After', 'pupil_timestamp');
    end
end
end

