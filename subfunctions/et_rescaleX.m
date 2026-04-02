function rescaledTrials = et_rescaleX(segTrials)
%ETRESCALEX Shift x column to start at 0
%   Detailed explanation goes here

rescaledTrials = cell(size(segTrials));
for e = 1:size(segTrials, 2)
    for b = 1:size(segTrials, 1)
        currBlock = segTrials{b, e};
        for t = 1:size(currBlock, 1)
            x = currBlock{t}.x;
            currBlock{t}.x = x - x(1);
        end
        rescaledTrials{b, e} = currBlock;
    end
end
end

