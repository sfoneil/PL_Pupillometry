function segTrunc = et_truncseg(segTrials, winLength)
%ETTRUNCSEG Truncate all trials in segTrials to same length
%   segTrials: 3x2 cell (block x eye) with 24x1 cell trials of varying
%   length
%       winLength: scalar or Nx2
%           positive scalar: truncate from 0s to winLength s
%           negative scalar: truncate from end-winLength to end
%           positive 1x2: truncate range, e.g. [1 3] == 2s

arguments (Input)
    segTrials    
    winLength double {mustBeNumeric, mustBeNonzero, mustBeScalarOr1x2}
end
fs = 120; %@ verify?

% Convert to seconds
% segStart
% segEnd

nBlocks = size(segTrials, 1);
nTrialsInBlock = size(segTrials{1,1},1);

% Find shortest trials among all
smallest = et_findshortesttrial(segTrials);

% Alt for just winLength
% e.g. 5 s total
% + scalar first X secs: 2 == 0 to 2
% - scalar last X secs: -2 == end-2 to end
% 1x2: [2 4] == 2 to 4, 2s length

if isscalar(winLength)
    % Start or end
    if winLength > 0
        xlimits(1) = 1;
        xlimits(2) = winLength * fs;
    elseif winLength < 0
        xlimits(2) = smallest;
        xlimits(1) = xlimits(2) - (abs(winLength)*fs);
    elseif winLength == 0
        error('winLength==0. Shouldn''t happen due to validator!');
    end
elseif all(size(winLength) == [1, 2])
    % Window
    %@ todo

end

% % Determine window in samples
% switch side
%     case 'start'
%         xlimits(1) = 1;
%         xlimits(2) = winLength * fs;
%     case 'end'
%         xlimits(2) = smallest;
%         xlimits(1) = xlimits(2) - (winLength*fs);
%         % Verify: not +/- 1
%     case {'center', 'middle'}
%         % Validate winLength isn't scalar
%         if isscalar(winLength)
%             error('If using argument ''center'' or ''middle'', winLength should be 1x2 [start end].');
%         end
%         xlimits(1) = winLength(1) * fs;
%         xlimits(2) = winLength(2) * fs;
%     case 'secs'
%         xlimits(1) = winLength(1) * fs;
%         xlimits(2) = winLength(2) * fs;
%     otherwise
%         error("Use {'start', 'end', 'center', 'middle', 'secs'} as second argument.");
% end

segTrunc = segTrials;
for b = 1:size(segTrials, 1)
    for e = 1:size(segTrials, 2)
        currBlock = segTrunc{b, e};
        for t = 1:size(currBlock, 1)
            currTrial = currBlock{t};
            % Keep only the range
            currBlock{t} = currTrial(xlimits(1):xlimits(2), :);
        end
        segTrunc{b, e} = currBlock;
    end
end


end

function mustBeScalarOr1x2(x)
% Validate input: must be scalar (1x1) OR 1x2
if ~(isscalar(x) || (length(x) == 2 && isrow(x)))
    eidType = 'mustBeScalarOr1x2:notScalarOr1x2';
    msgType = 'Input must be a scalar or a 1x2 row vector.';
    error(eidType, msgType)
end
end