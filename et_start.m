function et_start(subjectID)
%ET_START Function to run subjects
%   Finds subject by ID in Excel document 'Subject_list.xlsx', determines
%   corresponding trial and marker data files. Calls et_main_analysis()
%   with these parameters to run all analysis steps.
%
%   Input: subjectPath (char or string): subjectID matching a folder in \Results_data folder.
%

try
    % Get current directory
    thisFilePath = fileparts(mfilename('fullpath'));
    cd(thisFilePath);

    % Path to location data is stored, change if needed
    % Contents are individual folders with data inside, other items are ignored
    % in the base directory including any subject info.
    subjectPath = fullfile(pwd, "Results_data");

    % If no subject specified
    if nargin == 0
        % Get everything
        folders = dir(subjectPath);
        % Get only folders
        folders = folders(cell2mat({folders.isdir})');
        % Remove . & ..
        folders(1:2) = [];
        allSubjects = string({folders.name});
        nSubjects = size(allSubjects, 2);
        nums = 1:nSubjects;

        fprintf('\n');
        fprintf('There were %d subjects found.\n', nSubjects);
        prompt = input('Enter "y" if you want to list them, otherwise hit ENTER.   ', 's');
        fprintf('\n');
        if any(strcmpi(prompt, ["y", "yes"]))
            fprintf('Subject IDs:\n\n');
            fprintf(strjoin(nums + "   " + allSubjects, " \n"));
        end
        fprintf('\n');

        % Get the number, within range
        subjectID = -1;
        while subjectID < 1 || subjectID > nSubjects
            subjectID = input('Which NUMBER do you want to select?   ');
        end
        % Get the name
        subjectID = folders(subjectID).name;
    end

    %% Runs
    %trialPath = fullfile(subjectPath, subjectID);
    markerFile = dir(fullfile(subjectPath, subjectID, '*.xlsx'));
    if any(size(markerFile) ~= [1 1])
        error('Multiple .xlsx files detected. Make sure there is 1 per directory.');
    end
    markerFile = markerFile.name;

    %% Run main function
    et_main_analysis(subjectID, markerFile);

catch EX
    % Return to dir
    cd(thisFilePath);
    rethrow(EX);

end

end