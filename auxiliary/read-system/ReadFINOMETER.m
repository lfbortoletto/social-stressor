function varargout = ReadFINOMETER(folderPath)
% ReadFINOMETER Reads and processes Finometer data files in the specified folder.
%
% This function reads Finometer data files with specific keywords (waveforms, brs, beats)
% from the given folder path, processes the data, and optionally saves it into a MATLAB file (.finometer).
%
% Syntax:
%   ReadFINOMETER(folderPath)
%   dataStruct = ReadFINOMETER(folderPath)
%
% Input:
%   folderPath - A string specifying the path to the folder containing the Finometer data files.
%
% Output (optional):
%   dataStruct - A struct containing the raw and processed data.
%
% Example:
%   ReadFINOMETER('C:\Data\Finometer\')
%   dataStruct = ReadFINOMETER('C:\Data\Finometer\')
%
% Note:
%   - The function expects the folder to contain files with the keywords 'waveforms', 'brs', and 'beats'.
%   - The function will process these files and save the output in the same folder with a .finometer extension unless varargout is provided.
%
% Created by: L. F. Bortoletto (2024/7/22)
%
% Last Modified by:
%   L. F. Bortoletto (2024/7/22): script documentation and varargout update.
%
% -------------------------------------------------------------------------

    % Ensure folderPath ends with a file separator
    if ~(folderPath(end) == '\' || folderPath(end) == '/')
        folderPath = [folderPath, '\'];
    end

    % Get list of all files in the folder
    [filePathList, fileNameList] = getAllFiles(folderPath);
    
    % Initialize filepaths structure
    filepaths = struct();
    
    % Identify and store file paths based on keywords
    for files = 1:length(filePathList)
        if contains(filePathList{files}, 'waveforms')
            filepaths.waveforms = filePathList{files};
        elseif contains(filePathList{files}, 'brs')
            filepaths.brs = filePathList{files};
        elseif contains(filePathList{files}, 'beats')
            filepaths.beats = filePathList{files};
        elseif contains(filePathList{files}, '.fpf')
            savePath = [folderPath, fileNameList{files}(1:end-4)];
        end
    end

    % Read data from each identified file and store in a structure
    fn = fieldnames(filepaths);
    for i = 1:numel(fn)
        opts = detectImportOptions(filepaths.(fn{i}), 'NumHeaderLines', 8, 'Delimiter', ';', 'PreserveVariableNames', true); 
        opts = setvartype(opts, 'char');
        data.(fn{i}) = readtable(filepaths.(fn{i}), opts);
    end

    % Report the number of markers in waveforms data
    keyPressedIdx = find(string(data.waveforms.Markers) == "Marker key pressed");
    if length(keyPressedIdx) > 1
        disp(['Number of Finometer markers: ', num2str(length(keyPressedIdx)), '. Fix before you continue.']);
        if nargout > 0
            varargout{1} = data;
        end
        return
    else
        disp(['Number of Finometer markers: ', num2str(length(keyPressedIdx))]);
    end

    % Convert datetime to seconds using the first waveform time as the reference (t0)
    t0 = datetime(strrep(data.waveforms.("Time (s)"){1}, ',', '.')); % Use waveform start time as reference

    % Process and convert times for waveforms, beats, and brs data
    data.waveforms.("Time (s)") = convertTime(data.waveforms.("Time (s)"), t0);
    data.beats.("Time (s)") = convertTime(data.beats.("Time (s)"), t0);
    data.brs.("Time(s)") = convertTime(data.brs.("Time(s)"), t0);
    data.brs = renamevars(data.brs, 'Time(s)', 'Time (s)');

    % Convert data columns from string to numeric for waveforms, beats, and brs
    data.waveforms = convertColumns(data.waveforms, 2:6);
    data.beats = convertColumns(data.beats, 2:12);
    data.brs = convertColumns(data.brs, 2:8);

    if nargout > 0
        % Return data if varargout is provided
        varargout{1} = data;
    else
        % Save the processed data to a .finometer file, overwriting if it already exists
        if isfile([savePath, '.finometer'])
            disp('A .finometer was found in the current folder. Overwriting previous file.')
            delete([savePath, '.finometer'])
        end
        save([savePath, '.finometer'], 'data')
    end
end

function timeInSeconds = convertTime(timeColumn, t0)
% Converts a time column from string to seconds relative to t0
    time = string(cell2mat(timeColumn));
    time = strrep(time, ',', '.');
    time = datetime(time) - t0;
    timeInSeconds = seconds(time);
end

function dataTable = convertColumns(dataTable, columns)
% Converts specified columns from string to numeric
    for i = columns
        dataTable.(i) = str2num(char(replace(dataTable.(i), ',', '.')));
    end
end
