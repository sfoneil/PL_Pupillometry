function segAvg = et_blaverage(seg)
%ETBLAVERAGE Summary of this function goes here
%   Detailed explanation goes here

nBlocks = size(seg, 1);
%nTrialsInBlock = size(seg{1,1},2);

% Allocate output
segAvg = cell(1,2);
minRight = Inf;

for b = 1:nBlocks
    for e = 1:2
        currBlock = seg{b, e};

        % for t = 1:nTrialsInBlock
        %currTrial = currBlock{t};
        %x = currBlock.x;
        % indices = [knnsearch(x, 0), ...
        %     knnsearch(x, minRight)];
        minRight = min(size(currBlock,1), minRight);
        %  end
    end
end

x = seg{1,1}.x;
x = x(1:minRight, :);
ct = 1;
avgTrial = table(x); %x, 'VariableNames', "x");

for e = 1:2
    for b = 1:nBlocks
        currBlock = seg{b, e};
        x = currBlock.x;
        x = x(1:minRight, :);

        %        for t = 1:nTrialsInBlock
        %currTrial = currBlock{t};
        y = currBlock.diameter_3d_filt;
        y = y(1:minRight, :);
        avgTrial = addvars(avgTrial, y, 'NewVariableNames', "y" + ct);
        %  end
        nCols = size(avgTrial,2);

        ct = ct + 1;
    end
    segAvg{e} = table(avgTrial.x, mean(avgTrial{:, 2:nCols}, 2), ...
        std(avgTrial{:, 2:nCols}, [], 2), ...
        std(avgTrial{:, 2:nCols}, [], 2)./sqrt(nCols-1),...
        'VariableNames', ["x", "y_avg", "y_std", "y_sem"]);
end
end