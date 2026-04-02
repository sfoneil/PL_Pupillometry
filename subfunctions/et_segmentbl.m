function [segDot, segRest] = et_segmentbl(tpL, tpR, dotTimes, restTimes)
%ETSEGMENTBL Segmentation of dot/fix and rest conditions
%   Detailed explanation goes here


nBlocks = size(dotTimes, 1);
% Define spans of fixation dots, wait, rest
dotStart = dotTimes.PLDotTime;
dotStop = dotTimes.PLDotFromStart;

restStart = restTimes.PLRestTime;
restStop = restTimes.PLRestFromStart;

dotLidx = [knnsearch(tpL.pupil_timestamp, dotStart), ...
    knnsearch(tpL.pupil_timestamp, dotStop)];
dotRidx = [knnsearch(tpR.pupil_timestamp, dotStart), ...
    knnsearch(tpR.pupil_timestamp, dotStop)];

restLidx = [knnsearch(tpL.pupil_timestamp, restStart), ...
    knnsearch(tpL.pupil_timestamp, restStop)];
restRidx = [knnsearch(tpR.pupil_timestamp, restStart), ...
    knnsearch(tpR.pupil_timestamp, restStop)];

segDot = cell(nBlocks, 2);
segRest = cell(nBlocks, 2);
for b = 1:nBlocks
    segDot{b,1} = tpL(dotLidx(b,1):dotLidx(b,2), :);
    segDot{b,2} = tpR(dotRidx(b,1):dotRidx(b,2), :);
    segRest{b,1} = tpL(restLidx(b,1):restLidx(b,2), :);
    segRest{b,2} = tpR(restRidx(b,1):restRidx(b,2), :);
    segDot{b,1} = addvars(segDot{b,1}, segDot{b,1}.pupil_timestamp - ...
        segDot{b, 1}{1, 'pupil_timestamp'}, 'NewVariableNames', 'x', 'After', 'pupil_timestamp');
    segDot{b,2} = addvars(segDot{b,2}, segDot{b,2}.pupil_timestamp - ...
        segDot{b, 2}{1, 'pupil_timestamp'}, 'NewVariableNames', 'x', 'After', 'pupil_timestamp');

    segRest{b,1} = addvars(segRest{b,1}, segRest{b,1}.pupil_timestamp - ...
        segRest{b, 1}{1, 'pupil_timestamp'}, 'NewVariableNames', 'x', 'After', 'pupil_timestamp');
    segRest{b,2} = addvars(segRest{b,2}, segRest{b,2}.pupil_timestamp - ...
        segRest{b, 2}{1, 'pupil_timestamp'}, 'NewVariableNames', 'x', 'After', 'pupil_timestamp');

end

end

