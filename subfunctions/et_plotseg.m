function f_seg = et_plotseg(segType, segTrials, condOrder, sounds, opts)
%ETPLOTSEG Plot raw eye tracking data in tiledlayout
%   Detailed explanation goes here

arguments
    % Does nothing as of now, future use?
    segType
    % Segmented trials
    segTrials
    % Trials in the order ran
    condOrder
    % Sounds played for each condition
    sounds
    % Percent to add to axes, 1.1 = 10% larger
    opts.buffer = 1.02;
    % Match all axes ranges. May be altered by rezero, zeroY
    opts.redoAxes = 0;
    opts.title_header = ""
    % Change x axis to start at zero time point
    opts.rezero = 0
    % Zero y axis (pupil diameter). Default off, on may compress plot
    opts.zeroY = 0
end

%% Defaults
try
    nBlocks = 3;
    nTrials = 24;
    figRows = 6;
    figCols = 4;

    redoAxes = opts.redoAxes;

    % Get the first trial limits as a start
    xlimits = [min(segTrials{1,1}{1}.x), max(segTrials{1,1}{1}.x)];
    %xlimits = xlimits - xlimits(1);
    ylimits = [min(segTrials{1,1}{1}.diameter_3d), max(segTrials{1,1}{1}.diameter_3d)];

    line_colors = [0 0 0;
        1 0 0];
    line_styles = {'-', '-'};

    f_seg = cell(1, nBlocks);
    tl_block = cell(1, nBlocks);

    if opts.rezero
        segTrials = etrescaleX(segTrials);
    end

    for b = 1:nBlocks
        f_seg{b} = figure; %("Units", "normalized", "Position", [0 1 .3 .3]);
        tl_seg(b) = tiledlayout(f_seg{b}, figRows, figCols, "TileSpacing", "Compact");%, "Padding", "Compact");
        tl_count = 1;

        for t = 1:nTrials
            %fprintf('Plot %d\n', t)
            %   tl_block{tl_count} = nexttile;
            nexttile(tl_count);
            currTrialL = segTrials{b, 1}{t};
            currTrialR = segTrials{b, 2}{t};

            % Get new min/max
            currXLimits = [min(min(xlimits(1), min(currTrialL.x)), ...
                min(xlimits(1), min(currTrialR.x))), ...
                max(max(xlimits(2), max(currTrialL.x)), ...
                max(xlimits(2), max(currTrialR.x)))];
            currYLimits = [min(min(ylimits(1), min(currTrialL.diameter_3d)), ...
                min(ylimits(1), min(currTrialR.diameter_3d))), ...                
                max(max(ylimits(2), max(currTrialL.diameter_3d)), ...
                max(ylimits(2), max(currTrialR.diameter_3d)))];

            % Replace if more extreme
            xlimits = [min(xlimits(1), currXLimits(1)), max(xlimits(2), currXLimits(2))];
            ylimits = [min(ylimits(1), currYLimits(1)), max(ylimits(2), currYLimits(2))];

            % if b == 3 && t == 18
            %     disp('a')
            % end
            % % Rescale to 0
            % if opts.rezero
            %     xlimits = xlimits - xlimits(1);
            % end

            plot(currTrialL.x, currTrialL.diameter_3d_filt, ...
                'Color', line_colors(1,:), 'LineStyle', line_styles{1});
            hold on
            plot(currTrialR.x, currTrialR.diameter_3d_filt, ...
                'Color', line_colors(2,:), 'LineStyle', line_styles{2});
            tl_count = tl_count + 1;
            % switch condOrder(b)
            %     case "baseline"
            %         currSound = "water";
            %     case {"threat_alone", "threat_together"}
            %         currSound = "scream";
            %     otherwise
            %         error('Wrong condition.')
            % end
            % currSound = currSound + ((b-1)*nTrials + t);
            %title(currSound);
            title(sounds{(b-1)*nTrials+t, "SoundFile"});
        end

        % If you want to scale Y to zero
        if opts.zeroY
            ylimits(1) = 0;
        end

        ylimits(2) = ylimits(2) * opts.buffer;

        % Redo axes to largest
        if redoAxes
            tl_count = 1;
            for t = 1:nTrials
                nexttile(tl_count); %(tl_block{b}(t));
                %axis([xlimits, ylimits]);
                xlim([xlimits(1), xlimits(2)]);
                ylim(ylimits);
                tl_count = tl_count + 1;
            end
        end
        sgtitle([opts.title_header; regexprep(condOrder(b), "_", " ")]);
    end

    % % Redo axes to largest
    % tl_count = 1;
    % %nexttile(1);
    % for b = 1:nBlocks
    %     for t = 1:nTrials
    %         nexttile(tl_count); %(tl_block{b}(t));
    %         axis([xlimits, ylimits]);
    %         tl_count = tl_count + 1;
    %     end
    % end
catch
    disp('')
end
hold off
end

