% This script is intended to build the backup files from each data
% acquisition performed. All files extracted from each system must be
% already organized in the following folder format:
%
% (backupPath)\subject-XXX
%                   \nirs
%                   \eda
%                   \finometer
%                   \g3c
%                   \gw4
%                   \digpts

%% Clear workspace and command window.
clear; clc

%% Define paths.
backupPath = 'C:\Users\User\Desktop\datasets\social-interaction\backup\';

%% Read systems from raw data.
for k = 1:21
    if k < 10
        dataName = ['subject-00',num2str(k)];
    else
        dataName = ['subject-0',num2str(k)];
    end
readFiles(backupPath, rawPath, dataName, 'eda')
readFiles(backupPath, rawPath, dataName, 'gw4')
readFiles(backupPath, rawPath, dataName, 'g3c')
readFiles(backupPath, rawPath, dataName, 'finometer')
readFiles(backupPath, rawPath, dataName, 'nirs')
readFiles(backupPath, rawPath, dataName, 'digpts')
end


%% Auxliary functions.
function readFiles(rawPath, savePath, dataName, file)
%input:
%   folderPath: participant path, which contains all data.
%   dataName: pilot or subject folder name.
%   file: File data type: eda; digpts; nirs; g3c; finometer, or; gw4.

if ~exist([savePath, dataName],"dir")
    mkdir([savePath, dataName])
end

%% MIST.
if strcmp(file, 'mist') || isempty(file)
ReadMIST([rawPath, dataName, '\mist\'], dataName);
copyfile([rawPath, dataName, '\mist\', dataName, '.mist'], [savePath, dataName, '\mist\'])
end

%% Edamove.
if strcmp(file, 'eda') || isempty(file)
ReadEDAMOVE4([rawPath, dataName, '\eda'], dataName);
if ~isfolder([savePath, dataName, '\eda\'])
    mkdir([savePath, dataName, '\eda\']);
end
copyfile([rawPath, dataName, '\eda\', dataName, '.eda'], [savePath, dataName, '\eda\'])
end

%% Digpts.
if strcmp(file, 'digpts') || isempty(file)
[DigptsName,~] = getAllFiles([rawPath, dataName, '\digpts']);
oldFileName = DigptsName{1};
newFileName = [savePath, dataName, '\digpts\', dataName, '.txt'];
if ~isfolder([savePath, dataName, '\digpts\'])
    mkdir([savePath, dataName, '\digpts\']);
end
copyfile(oldFileName, newFileName);
ReadDIGPTS([savePath, dataName, '\digpts']);
end

%% Finometer.
if strcmp(file, 'finometer') || isempty(file)
clear data
ReadFINOMETER([rawPath, dataName, '\finometer']);
end

%% GW4.
if strcmp(file, 'gw4') || isempty(file)
clear data
ReadVIVASENSING([rawPath, dataName, '\gw4'], dataName);
end

%% NIRS.
if strcmp(file, 'nirs') || isempty(file)
clear data
[filenames, ~] = getAllFiles([rawPath, dataName, '\nirs']);
for files = 1:length(filenames)
    if strcmp(filenames{files}(end-3:end),'.hdr')
        HDRname = filenames{files};
    end
end
data = ReadNIRS;
save([rawPath, dataName, '\nirs\',dataName,'.nirs'],'data');
if ~isfolder([savePath, dataName, '\nirs\'])
    mkdir([savePath, dataName, '\nirs\']);
end
copyfile([rawPath, dataName, '\nirs\',dataName,'.nirs'], [savePath, dataName, '\nirs\'])
end

%% G3C.
if strcmp(file, 'g3c') || isempty(file)
clear data
[filenames, ~] = getAllFiles([rawPath, dataName, '\g3c']);
videoPath = filenames{1};
[data] = ReadG3C(videoPath);
save([rawPath, dataName, '\g3c\',dataName,'.g3c'],'data');
save([savePath,dataName,'\g3c\',dataName,'.g3c'],'data');
figure; plot(data.t, data.d); title('Check for G3C data quality');
end

end