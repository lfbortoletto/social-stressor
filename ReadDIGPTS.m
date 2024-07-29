function ReadDIGPTS(folderPath)
% ReadDIGPTS Reads and processes digitizer points data files from a specified folder.
%
% This function searches for fastrak data files in the specified folder, processes the data,
% and saves the digitized points to a new text file.
%
% Syntax:
%   ReadDIGPTS(folderPath)
%
% Input:
%   folderPath - A string specifying the path to the folder containing the digitizer data files.
%
% Example:
%   ReadDIGPTS('C:\Data\DIGPTS\')
%
% Note:
%   - The function expects the folder to contain files with the suffix '-fastrak.txt'.
%   - The function will process these files and save the digitized points in a new text file.
%
% -------------------------------------------------------------------------

    % Ensure folderPath ends with a file separator
    if ~(folderPath(end) == '\' || folderPath(end) == '/')
        folderPath = [folderPath, '\'];
    end

    [filePathList, ~] = getAllFiles(folderPath);
    dig = [];

    % Search for fastrak data files and load the data
    for file = 1:length(filePathList)
        if contains(filePathList{file}, '-fastrak.txt')
            readFilename = [filePathList{file}(1:end - length('-fastrak.txt')), '.txt'];
            dig = load(filePathList{file});
            originalFileID = file;
        end
    end

    % Check if any fastrak files were found
    if isempty(dig)
        disp('No fastrak files were found in the given folder path.')
        return
    end

    nSrcs = 16; % Number of sources
    nDets = 31; % Number of detectors

    % Check if the data size matches the expected number of sources and detectors
    if size(dig,1) == (nSrcs + nDets + 5)
        dig = 10 * dig(:, [2, 3, 4]); % Convert to appropriate units

        % Extract positions of sources and detectors
        digpts = extract_positions(dig, nSrcs, nDets);
        
        % Original file copy 
        copyfile(filePathList{originalFileID}, readFilename, 'f');

        % Open the file for writing the digitized points
        fid = fopen(readFilename, 'w');

        % Write fiducial markers
        fprintf(fid, ['a1: \t' num2str(dig(1,1)) '\t' num2str(dig(1,2)) '\t' num2str(dig(1,3)) '\r\n']);
        fprintf(fid, ['a2: \t' num2str(dig(2,1)) '\t' num2str(dig(2,2)) '\t' num2str(dig(2,3)) '\r\n']);
        fprintf(fid, ['nz: \t' num2str(dig(3,1)) '\t' num2str(dig(3,2)) '\t' num2str(dig(3,3)) '\r\n']);
        fprintf(fid, ['cz: \t' num2str(dig(4,1)) '\t' num2str(dig(4,2)) '\t' num2str(dig(4,3)) '\r\n']);
        fprintf(fid, ['iz: \t' num2str(dig(5,1)) '\t' num2str(dig(5,2)) '\t' num2str(dig(5,3)) '\r\n']);

        % Write source positions
        for rk = 1:nSrcs
            fprintf(fid, ['s' num2str(rk) ': \t' num2str(dig(rk + 5, 1)) '\t' num2str(dig(rk + 5, 2)) '\t' num2str(dig(rk + 5, 3)) '\r\n']);
        end

        % Write detector positions
        for rk = 1:nDets
            fprintf(fid, ['d' num2str(rk) ': \t' num2str(dig(rk + 5 + nSrcs, 1)) '\t' num2str(dig(rk + 5 + nSrcs, 2)) '\t' num2str(dig(rk + 5 + nSrcs, 3)) '\r\n']);
        end
        fclose(fid);
        % Display success message
        disp('The script was successfully performed and the data was saved.');
    else
        dig = 10 * dig(:, [2, 3, 4]);
        for i = 1:size(dig, 1)
            for j = 1:size(dig, 1)
                digptsDistance(i, j) = norm(dig(i, :) - dig(j, :));
            end
        end
        [badIdx(:, 1), badIdx(:, 2)] = find(digptsDistance < 10);
        removeDigpts = (badIdx(:, 2) - badIdx(:, 1)) == 0;
        badIdx(removeDigpts, :) = [];
        disp(['Fail to convert file "', filePathList{1}, '". There are ', num2str(size(dig, 1) - (nSrcs + nDets + 5)), ' lines missing/exceeding.']);
        disp(['The following lines seem to match: ', num2str(badIdx(:, 1)')])
        disp(['                                    ', num2str(badIdx(:, 2)')])
        return
    end

end

function digpts = extract_positions(dig, nSrcs, nDets)
% Extract positions of sources and detectors from the digitized data
%
% This helper function extracts the positions of sources and detectors from the digitized data.
%
% Inputs:
%   dig   - A matrix containing the digitized data.
%   nSrcs - Number of sources.
%   nDets - Number of detectors.
%
% Output:
%   digpts - A struct containing the positions of fiducial markers, sources, and detectors.

    % Extract fiducial markers
    digpts.a1 = dig(1, :);
    digpts.a2 = dig(2, :);
    digpts.nz = dig(3, :);
    digpts.cz = dig(4, :);
    digpts.iz = dig(5, :);

    % Extract sources
    for rk = 1:nSrcs
        digpts.(['s', num2str(rk)]) = dig(rk + 5, :);
    end

    % Extract detectors
    for rk = 1:nDets
        digpts.(['d', num2str(rk)]) = dig(rk + 5 + nSrcs, :);
    end

end
