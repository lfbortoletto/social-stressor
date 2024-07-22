function varargout = ReadVivaSensing(folderPath, filenameSave)
% ReadVivaSensing Reads and processes Viva Sensing data files in the specified folder.
%
% This function reads Viva Sensing data files from the given folder path, processes the data,
% and optionally saves it into a MATLAB file (.gw4) or returns the data in a struct.
%
% Syntax:
%   ReadVivaSensing(folderPath, filenameSave)
%   dataStruct = ReadVivaSensing(folderPath, filenameSave)
%
% Inputs:
%   folderPath   - A string specifying the path to the folder containing the Viva Sensing data files.
%   filenameSave - A string specifying the name of the file to save the processed data.
%
% Output (optional):
%   dataStruct - A struct containing the raw and processed data.
%
% Example:
%   ReadVivaSensing('C:\Data\VivaSensing\', 'processedData')
%   dataStruct = ReadVivaSensing('C:\Data\VivaSensing\', 'processedData')
%
% Note:
%   - The function expects the folder to contain files named with 'Acc', 'PpgI', 'PpgG', and 'HR'.
%   - The function will process these files and save the output in the same folder with a .gw4 extension unless varargout is provided.
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

    GW4 = struct();
    [filePathList, ~] = getAllFiles(folderPath);

    % Check existence of files
    if isempty(filePathList)
        disp(['No GW4 files found in ', folderPath])
        if nargout > 0
            varargout{1} = GW4;
        end
        return
    end

    % Load files
    for k = 1:numel(filePathList)
        if contains(filePathList{k}, 'Acc')
            acc = readtable(filePathList{k}, 'PreserveVariableNames', true);
        elseif contains(filePathList{k}, 'PpgI')
            ppgIR = readtable(filePathList{k}, 'PreserveVariableNames', true);
        elseif contains(filePathList{k}, 'PpgG')
            ppgG = readtable(filePathList{k}, 'PreserveVariableNames', true);
        elseif contains(filePathList{k}, 'HR')
            hr = readtable(filePathList{k}, 'PreserveVariableNames', true);
        end  
    end

    if ~exist('acc', 'var')
        disp(['No GW4 files found in ', folderPath])
        if nargout > 0
            varargout{1} = GW4;
        end
        return
    end

    % Adjust timestamp
    acc.Timestamp = (acc.Timestamp - acc.Timestamp(1)) / 10^3;
    ppgIR.Timestamp = (ppgIR.Timestamp - ppgIR.Timestamp(1)) / 10^3;
    ppgG.Timestamp = (ppgG.Timestamp - ppgG.Timestamp(1)) / 10^3;
    hr.Timestamp = (hr.Timestamp - hr.Timestamp(1)) / 10^3;

    % Find triggers (abrupt changes in acc)
    acc_freq = 1 / nanmedian(diff(acc.Timestamp));
    acc_data = acc.(4);
    f1 = figure; plot(acc.Timestamp, acc_data);
    trigger_time = input('Insert trigger time (s): ');
    close(f1)
    trigger_time = round(trigger_time * acc_freq) / acc_freq;

    % Adjust trigger time to zero
    acc.Timestamp = acc.Timestamp - trigger_time;
    ppgIR.Timestamp = ppgIR.Timestamp - trigger_time;
    ppgG.Timestamp = ppgG.Timestamp - trigger_time;
    hr.Timestamp = hr.Timestamp - trigger_time;

    % Remove data prior to trigger
    acc(acc.Timestamp < 0, :) = [];
    ppgIR(ppgIR.Timestamp < 0, :) = [];
    ppgG(ppgG.Timestamp < 0, :) = [];
    hr(hr.Timestamp < 0, :) = [];

    % Store smartwatch data in GW4 struct
    GW4.acc = acc; 
    GW4.ppgIR = ppgIR;
    GW4.ppgG = ppgG;
    GW4.hr = hr;

    if nargout > 0
        % Return data if varargout is provided
        varargout{1} = GW4;
    else
        % Save the processed data to a .gw4 file
        save([folderPath, filenameSave, '.gw4'], 'GW4')
    end
end
