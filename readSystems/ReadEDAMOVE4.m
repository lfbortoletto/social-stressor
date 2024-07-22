function varargout = ReadEDAMOVE4(folderPath, filenameSave)
% ReadEDAMOVE4 Reads and processes EDA-MOVE4 data files in the specified folder.
%
% This function reads EDA-MOVE4 data files from the given folder path, processes the data,
% and optionally saves it into a MATLAB file (.eda) or returns the data in a struct.
%
% Syntax:
%   ReadEDAMOVE4(folderPath, filesave)
%   dataStruct = ReadEDAMOVE4(folderPath, filesave)
%
% Inputs:
%   folderPath - A string specifying the path to the folder containing the EDA-MOVE4 data files.
%   filenameSave   - A string specifying the name of the file to save the processed data.
%
% Output (optional):
%   dataStruct - A struct containing the raw and processed data.
%
% Example:
%   ReadEDAMOVE4('C:\Data\EDAMOVE4\', 'processedData')
%   dataStruct = ReadEDAMOVE4('C:\Data\EDAMOVE4\', 'processedData')
%
% Note:
%   - The function expects the folder to contain files named 'eda', 'acc', 'marker.csv', 'temp', and 'angularrate'.
%   - The function will process these files and save the output in the same folder with a .eda extension unless varargout is provided.
%
% Created by: L. F. Bortoletto (2024/7/22)
%
% Last Modified by:
%   L. F. Bortoletto (2024/7/22): script documentation.
%
% -------------------------------------------------------------------------

    % Ensure folderPath ends with a file separator
    if ~(folderPath(end) == '\' || folderPath(end) == '/')
        folderPath = [folderPath, '\'];
    end

    % Initialize structure to store raw and processed data
    edamove = struct();
    
    % Read and process EDA data
    edamove.eda.f = 32;
    eda = readtable([folderPath, 'eda']); 
    edamove.eda.data = eda.Var1;
    edamove.eda.t = (0:1/edamove.eda.f:(length(edamove.eda.data) - 1)/edamove.eda.f)';
    clear eda

    % Read and process accelerometer data
    edamove.acc.f = 64;
    acc = readtable([folderPath, 'acc']); 
    edamove.acc.data_1 = acc.Var1;
    edamove.acc.data_2 = acc.Var2;
    edamove.acc.data_3 = acc.Var3;
    edamove.acc.t = (0:1/edamove.acc.f:(length(edamove.acc.data_1) - 1)/edamove.acc.f)';
    clear acc

    % Read and process marker data
    edamove.marker.f = 64;
    markerFID = fopen([folderPath, 'marker.csv']);
    markerScan = textscan(markerFID, '%s', 'Delimiter', ';');
    fclose(markerFID);
    if numel(markerScan{1}) ~= 2 
        disp(['Number of EDA markers: ', num2str(numel(markerScan{1}) / 2), '. Fix before you continue.']);
        if nargout > 0
            varargout{1} = edamove;
        end
        return
    else
        disp(['Number of EDA markers: ', num2str(numel(markerScan{1}) / 2), '.']);
    end
    edamove.marker.index = str2num(markerScan{1}{1}); % Generalize for more than 1 marker.
    edamove.marker.t = (edamove.marker.index / edamove.marker.f)';
    clear markerScan markerFID

    % Read and process temperature data
    edamove.temp.f = 1;
    temp = readtable([folderPath, 'temp']); 
    edamove.temp.data = temp.Var1;
    edamove.temp.t = (0:1/edamove.temp.f:(length(edamove.temp.data) - 1)/edamove.temp.f)';
    clear temp

    % Read and process angular rate data
    edamove.ang.f = 64;
    ang = readtable([folderPath, 'angularrate']); 
    edamove.ang.data_1 = ang.Var1;
    edamove.ang.data_2 = ang.Var2;
    edamove.ang.data_3 = ang.Var3;
    edamove.ang.t = (0:1/edamove.ang.f:(length(edamove.ang.data_1) - 1)/edamove.ang.f)';
    clear ang

    if nargout > 0
        % Return data if varargout is provided
        varargout{1} = edamove;
    else
        % Save the processed data to a .eda file
        save([folderPath, filenameSave, '.eda'], 'edamove')
    end
end
