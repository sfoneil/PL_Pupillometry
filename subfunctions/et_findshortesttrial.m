function minSize = findshortesttrial(segTrials)
%FINDSHORTESTTRIAL Find the shortest trial (# of samples) in segTrials
%   Inputs:
%       segTrials:  3x2 cell (condition x eye). Each cell has 24x1 cells
%       containing tables Nx12
%
%   Outputs:
%       minSize:    double, length of smallest trial

% Find the smallest trial
nBlocks = size(segTrials, 1); % 3
nTrialsInBlock = size(segTrials{1,1},1); %24


% minSize = Inf;
% for b = 1:nBlocks
%     for e = 1:2
%         currBlock = segTrials{b, e};
%         for t = 1:nTrialsInBlock
%             currTrial = currBlock{t};
%             minSize = min(minSize, size(currTrial, 1));
%           %  test = [test; currTrial{maxSize, "x"}];
%         end
%     end
% end

szs = [];
for b = 1:nBlocks
    for e = 1:2
        szs = [szs; cell2mat(cellfun(@size, segTrials{b,e}, UniformOutput=false))];
    end
end
minSize = min(szs);
minSize = minSize(1);

% 620

end

