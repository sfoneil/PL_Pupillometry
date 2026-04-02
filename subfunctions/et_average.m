function segAvg = et_average(truncTrials)
%ETAVERAGE Average segments
%   Input:
%       truncTrials: cell 3x2 > cell 24x1 > table NxM

%fs = 120; %@ verify?

try
    nBlocks = size(truncTrials, 1);
    nTrialsInBlock = size(truncTrials{1,1},1);

    % Find shortest trials among all
    smallest = et_findshortesttrial(truncTrials);
    % First pass: truncate all to this length
    %segTrials = ettruncseg(segTrials, 1, smallest);

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
    %     otherwise
    %         error("Use {'start', 'end', 'center', 'none'} as third argument.");
    % end

    % Second pass: segment to length chosen
    %segTrials = ettruncseg(segTrials, xlimits(1), xlimits(2));

    % % Allocate output
    segAvg = cell(size(truncTrials));
    %
    % % Get minimum length
    % minRight = Inf;
    % for b = 1:nBlocks
    %     for e = 1:2
    %         currBlock = segTrials{b, e};
    %         x = currBlock{1,1}.x;
    %         for t = 1:nTrialsInBlock
    %             currTrial = currBlock{t};
    %             x = currTrial.x;
    %             indices = [knnsearch(x, xlimits(1)), ...
    %                 knnsearch(x, xlimits(2))];
    %             minRight = min(indices(2), minRight);
    %         end
    %     end
    % end

    % Get the average
    for e = 1:2
        for b = 1:nBlocks
            currBlock = truncTrials{b, e};
            x = currBlock{1}.x;
            % Recenter to 0
            x = x - x(1);
            avgTrial = table(x);           
            for t = 1:nTrialsInBlock
                currTrial = currBlock{t};
                y = currTrial.diameter_3d_filt;
                avgTrial = addvars(avgTrial, y, 'NewVariableNames', "y" + t);
            end
            % Number of columns, including x so SEM=std/sqrt(N-1)
            nCols = size(avgTrial,2);
            segAvg{b, e} = table(avgTrial.x, mean(avgTrial{:, 2:nCols}, 2), ...
                std(avgTrial{:, 2:nCols}, [], 2), ...
                std(avgTrial{:, 2:nCols}, [], 2)./sqrt(nCols-1),...
                'VariableNames', ["x", "y_avg", "y_std", "y_sem"]);
        end
    end

    % for b = 1:nBlocks
    %     for e = 1:2
    %         %avgTrial = [];
    %         currBlock = segTrials{b, e};
    %         %x = currBlock{1,1}.x;
    %         % indices = [knnsearch(x, xlimits(1)), ...
    %         %     knnsearch(x, xlimits(2))];
    %         % x = x(indices(1):indices(2), :);
    %         %avgTrial = table(x, zeros(size(x)), 'VariableNames', {'x', 'y'});
    %         x = currBlock{1}.x;
    %         % Truncate x
    %         x = x(indices(1):minRight, :);
    %         avgTrial = table(x); %x, 'VariableNames', "x");
    % 
    %         for t = 1:nTrialsInBlock
    %             currTrial = currBlock{t};
    % 
    %             % Pull out full range
    %             % x = currTrial.x;
    %             y = currTrial.diameter_3d_filt;
    % 
    %             % Truncate
    %             if strcmpi(side, 'start')
    %                 % x = x(indices(1):minRight, :);
    %                 y = y(indices(1):minRight, :);
    %             end
    % 
    %             % % indices = [knnsearch(x, xlimits(1)), ...
    %             % %     knnsearch(x, xlimits(2))];
    %             % x = x(indices(1):indices(2), :);
    %             % if isempty(avgTrial)
    %             %     avgTrial.x = x;
    %             % end
    %             % % Account for rounding
    %             % if indices(2) > size(avgTrial, 1)
    %             %     useIndices = [indices(1), indices(2)-1];
    %             % else
    %             %     useIndices = [indices(1), indices(2)];
    %             % end
    %             % y = y(useIndices(1):useIndices(2), :);
    % 
    %             %y = y(indices(1):indices(2), :);
    %             avgTrial = addvars(avgTrial, y, 'NewVariableNames', "y" + t);
    %         end
    %         % Number of columns, including x so SEM=std/sqrt(N-2)
    %         nCols = size(avgTrial,2);
    %         segAvg{b, e} = table(avgTrial.x, mean(avgTrial{:, 2:nCols}, 2), ...
    %             std(avgTrial{:, 2:nCols}, [], 2), ...
    %             std(avgTrial{:, 2:nCols}, [], 2)./sqrt(nCols-2),...
    %             'VariableNames', ["x", "y_avg", "y_std", "y_sem"]);
    %     end
    % end
catch ME
    %fprintf('b = %d e = %d t = %d\n', b, e, t);
    rethrow(ME)
end
end

% function mustBeScalarOr1x2(x)
% % Validate input: must be scalar (1x1) OR 1x2
% if ~(isscalar(x) || (length(x) == 2 && isrow(x)))
%     eidType = 'mustBeScalarOr1x2:notScalarOr1x2';
%     msgType = 'Input must be a scalar or a 1x2 row vector.';
%     error(eidType, msgType)
% end
% end

% function [maxSize, test] = findMin(segTrials)
% % Find the smallest trial
% %todo make this do above
% nBlocks = size(segTrials, 1);
% nTrialsInBlock = size(segTrials{1,1},1);
% 
% maxSize = Inf;
% test = [];
% for b = 1:nBlocks
%     for e = 1:2
%         currBlock = segTrials{b, e};
%         for t = 1:nTrialsInBlock
%             currTrial = currBlock{t};
%             maxSize = min(maxSize, size(currTrial, 1));
%             test = [test; currTrial{maxSize, "x"}];
%         end
%     end
% end

%end
