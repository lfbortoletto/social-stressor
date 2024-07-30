% This script is intended to build the raw folder from the backup data.

%% Clear workspace and command window.
clear; clc

%% Define paths.
backupPath = 'C:\Users\User\Desktop\datasets\social-interaction\backup\';
rawPath = 'C:\Users\User\Desktop\datasets\social-interaction\raw\';

%% Compact backup data to raw data path.
validExtensionList = {'.eda','.nirs','.finometer','.G3C','.gw4'};
dataCompact(backupPath, rawPath, validExtensionList);

%% Synchronize systems from backup data into the raw folder.
for participant = 1:29
    disp(['Subject: ', num2str(participant)]);
    if participant < 10
        dataName = ['subject-00',num2str(participant)];
    else
        dataName = ['subject-0',num2str(participant)];
    end
    
    clear syncIdx
    if participant == 8 || participant == 10
        validExtensionList = {'.eda','.nirs','.finometer','.gw4'};
        syncIdx.FINO = 1;
        syncIdx.GW4 = 2;
        syncIdx.EDA = 4;
        syncIdx.lastTrigger = 4;
    elseif participant < 27
        validExtensionList = {'.eda','.nirs','.finometer','.G3C','.gw4'};
        syncIdx.FINO = 1;
        syncIdx.GW4 = 2;
        syncIdx.G3C = 3;
        syncIdx.EDA = 4;
        syncIdx.lastTrigger = 4;
    else
        validExtensionList = {'.eda','.nirs','.finometer','.G3C','.gw4'};
        syncIdx.FINO = 1;
        syncIdx.GW4 = 2;
        syncIdx.G3C = 3;
        syncIdx.EDA = 4;
        syncIdx.AUDIO = 5;
        syncIdx.lastTrigger = 4;
    end
    
    syncSystems(backupPath, rawPath, dataName, syncIdx, validExtensionList)
end

%% Auxiliary functions.
function syncSystems(backupPath, rawPath, dataName, syncIdx, validExtensionList)
%input:
%   folderPath: participant path, which contains all data.
%   dataName: pilot or subject folder name.
%   SyncIdx: synchronization indexes structure (see default).

% if isempty(syncIdx) %Use default synchronization indexes.
%     syncIdx.FINO = 1;
%     syncIdx.GW4 = 2;
%     syncIdx.G3C = 3;
%     syncIdx.EDA = 4;
%     syncIdx.lastTrigger = 4;
% end

[backupPathList, backupNameList] = getAllFiles([backupPath, dataName]);
[rawPathList, rawNameList] = getAllFiles([rawPath, dataName]);

if numel(rawPathList) ~= numel(validExtensionList)
    disp(['Sync not performed: ', num2str(numel(validExtensionList) - numel(rawPathList)), ' files are missing for ', dataName]);
    for extension = 1:length(validExtensionList)
        if ~contains(rawNameList, validExtensionList{extension})
            disp(['Files missing: ', validExtensionList{extension}])
        end
    end
    return
end

for filesBackup = 1:length(backupNameList)
    isContained = 0;
    for filesRaw = 1:length(rawNameList)
        if strcmp(backupNameList{filesBackup}, rawNameList{filesRaw})
            isContained = 1;
        end
    end
    if isContained == 0
        backupPathList{filesBackup} = [];
    end
end
backupPathList = backupPathList(~cellfun('isempty',backupPathList));

%% Load nirs data.
for files = 1:length(backupPathList)
    if contains(backupPathList{files},'.nirs')
        nirs = load(backupPathList{files},'-mat'); 
        nirs = nirs.data;
    end
end
clear backupFilePath savePath

%% Sync finometer.
if isfield(syncIdx, 'FINO')
    for files = 1:length(backupPathList)
        if contains(backupPathList{files},'.finometer')
            backupFilePath = backupPathList{files};
        end
        if contains(rawPathList{files},'.finometer')
            savePath = rawPathList{files};
        end
    end
    SyncFinometer(nirs, backupFilePath, savePath, syncIdx.FINO, syncIdx.lastTrigger)
    disp('Finometer Sync')
else
    disp('Finometer not synchronized')
end
clear backupFilePath savePath

%% Sync G3C.
if isfield(syncIdx, 'G3C')
    nasalCanulaLag = 3.5;
    for files = 1:length(backupPathList)
        if contains(backupPathList{files},'.G3C')
            backupFilePath = backupPathList{files};
        end
        if contains(rawPathList{files},'.G3C')
            savePath = rawPathList{files};
        end
    end
    SyncG3C(nirs, backupFilePath, savePath, nasalCanulaLag, syncIdx.G3C, syncIdx.lastTrigger)
    disp('G3C Sync')
else
    disp('G3C not synchronized')
end
clear backupFilePath savePath

%% Sync edamove.
if isfield(syncIdx, 'EDA')
for files = 1:length(backupPathList)
    if contains(backupPathList{files},'.eda')
        backupFilePath = backupPathList{files};
    end
    if contains(rawPathList{files},'.eda')
        savePath = rawPathList{files};
    end
end
SyncEDA(nirs, backupFilePath, savePath, syncIdx.EDA, syncIdx.lastTrigger)
disp('EDA Sync')
else
    disp('EDA not synchronized')
end
clear backupFilePath savePath

%% GW4.
if isfield(syncIdx, 'GW4')
for files = 1:length(backupPathList)
    if contains(backupPathList{files},'.gw4')
        backupFilePath = backupPathList{files};
    end
    if contains(rawPathList{files},'.gw4')
        savePath = rawPathList{files};
    end
end
SyncGW4(nirs, backupFilePath, savePath, syncIdx.GW4, syncIdx.lastTrigger)
disp('GW4 Sync')
else
    disp('GW4 not synchronized')
end
clear backupFilePath savePath

%% Sync NIRS.
for files = 1:length(backupPathList)
    if contains(backupPathList{files},'.nirs')
        backupFilePath = backupPathList{files};
    end
    if contains(rawPathList{files},'.nirs')
        savePath = rawPathList{files};
    end
end
SyncNIRS(backupFilePath, savePath, syncIdx)
disp('Synchronization was successfully performed.')
clear backupFilePath savePath

end

%% Auxiliar functions.
function SyncFinometer(nirs, backuppath, savepath, finoSyncIdx, lastTrigger)

%% Fileinfo.
load(backuppath,'-mat')

%% Sync Finometer.
finometer_trigger = find(data.waveforms.Markers == "Marker key pressed");
if length(finometer_trigger) > 1
    disp(['Finometer has ' , num2str(length(finometer_trigger)), ' trigger(s). Considering first trigger for sync.'])
    finometer_trigger = finometer_trigger(1);
end
data.waveforms(1:(finometer_trigger-1), :) = []; %waveforms SYNC'ed.

waveforms = data.waveforms.("Time (s)");
brs = data.brs.("Time (s)");
beats = data.beats.("Time (s)");

data.waveforms.("Time (s)") = round(waveforms - waveforms(1),3);
data.brs.("Time (s)") = round(brs - waveforms(1),3);
data.beats.("Time (s)") = round(beats - waveforms(1),3);

data.beats(1:find((beats - waveforms(1))<0, 1, 'last' ), :) = []; %beats SYNC'ed.
data.brs(1:find((brs - waveforms(1))<0, 1, 'last' ), :) = []; %brs SYNC'ed.

trigger_time = nirs.t(find(nirs.s));  %#ok<FNDSB>
delay_start = trigger_time(lastTrigger) - trigger_time(finoSyncIdx);
total_length = nirs.t(end) - trigger_time(lastTrigger);

data.waveforms.("Time (s)") = data.waveforms.("Time (s)") - delay_start;
data.beats.("Time (s)") = data.beats.("Time (s)") - delay_start;
data.brs.("Time (s)") = data.brs.("Time (s)") - delay_start;

data.waveforms(data.waveforms.("Time (s)")<0, :) = [];
data.beats(data.beats.("Time (s)")<0, :) = [];
data.brs(data.brs.("Time (s)")<0, :) = [];

data.waveforms(data.waveforms.("Time (s)")>total_length, :) = [];
data.beats(data.beats.("Time (s)")>total_length, :) = [];
data.brs(data.brs.("Time (s)")>total_length, :) = [];

%% Save.
save(savepath,'data')

end

function SyncG3C(nirs, backuppath, savepath, nasalCanulaLag, g3cSyncIdx, lastTrigger)

%% Fileinfo.
data = load(backuppath,'-mat');
data = data.G3C;

%% Sync G3C.  
if isfield(data, 'info')
    data = rmfield(data, 'info');
end
data = rmfield(data, 'cursorPosition');

trigger_time = nirs.t(find(nirs.s));  %#ok<FNDSB>
delay_start = nasalCanulaLag + trigger_time(lastTrigger) - trigger_time(g3cSyncIdx);
total_length = nirs.t(end) - trigger_time(lastTrigger);

data.t = data.t - delay_start;
data.nasalCanulaLag = nasalCanulaLag;

data.d(data.t<0) = [];
data.t(data.t<0) = [];

data.d(data.t>total_length) = [];
data.t(data.t>total_length) = [];

%% Save.
save(savepath,'data')

end

function SyncEDA(nirs, backuppath, savepath, edaSyncIdx, lastTrigger)

%% Fileinfo.
load(backuppath,'-mat')

trigger_time = nirs.t(find(nirs.s));  %#ok<FNDSB>
delay_start = trigger_time(lastTrigger) - trigger_time(edaSyncIdx);
total_length = nirs.t(end) - trigger_time(lastTrigger);

edamove.eda.t = edamove.eda.t - delay_start - edamove.marker.t;
edamove.eda.data(edamove.eda.t<0) = [];
edamove.eda.t(edamove.eda.t<0) = [];
edamove.eda.data(edamove.eda.t>total_length) = [];
edamove.eda.t(edamove.eda.t>total_length) = [];

edamove.acc.t = edamove.acc.t - delay_start - edamove.marker.t;
edamove.acc.data_1(edamove.acc.t<0) = [];
edamove.acc.data_2(edamove.acc.t<0) = [];
edamove.acc.data_3(edamove.acc.t<0) = [];
edamove.acc.t(edamove.acc.t<0) = [];
edamove.acc.data_1(edamove.acc.t>total_length) = [];
edamove.acc.data_2(edamove.acc.t>total_length) = [];
edamove.acc.data_3(edamove.acc.t>total_length) = [];
edamove.acc.t(edamove.acc.t>total_length) = [];

edamove.temp.t = edamove.temp.t - delay_start - edamove.marker.t;
edamove.temp.data(edamove.temp.t<0) = [];
edamove.temp.t(edamove.temp.t<0) = [];
edamove.temp.data(edamove.temp.t>total_length) = [];
edamove.temp.t(edamove.temp.t>total_length) = [];

edamove.ang.t = edamove.ang.t - delay_start - edamove.marker.t;
edamove.ang.data_1(edamove.ang.t<0) = [];
edamove.ang.data_2(edamove.ang.t<0) = [];
edamove.ang.data_3(edamove.ang.t<0) = [];
edamove.ang.t(edamove.ang.t<0) = [];
edamove.ang.data_1(edamove.ang.t>total_length) = [];
edamove.ang.data_2(edamove.ang.t>total_length) = [];
edamove.ang.data_3(edamove.ang.t>total_length) = [];
edamove.ang.t(edamove.ang.t>total_length) = [];

%% Save.
save(savepath, 'edamove')

end

function SyncGW4(nirs, backuppath, savepath, gw4SyncIdx, lastTrigger)

%% Fileinfo.
load(backuppath,'-mat')

if exist('GW4')
    data = GW4;
end

trigger_time = nirs.t(find(nirs.s));  %#ok<FNDSB>
delay_start = trigger_time(lastTrigger) - trigger_time(gw4SyncIdx);
total_length = nirs.t(end) - trigger_time(lastTrigger);

data.acc.Timestamp = data.acc.Timestamp - delay_start;
data.acc(data.acc.Timestamp<0, :) = [];
data.acc(data.acc.Timestamp>total_length, :) = [];
data.acc(isnan(data.acc.Timestamp), :) = [];

data.ppgIR.Timestamp = data.ppgIR.Timestamp - delay_start;
data.ppgIR(data.ppgIR.Timestamp<0, :) = [];
data.ppgIR(data.ppgIR.Timestamp>total_length, :) = [];
data.ppgIR(isnan(data.ppgIR.Timestamp), :) = [];

data.ppgG.Timestamp = data.ppgG.Timestamp - delay_start;
data.ppgG(data.ppgG.Timestamp<0, :) = [];
data.ppgG(data.ppgG.Timestamp>total_length, :) = [];
data.ppgG(isnan(data.ppgG.Timestamp), :) = [];

data.hr.Timestamp = data.hr.Timestamp - delay_start;
data.hr(data.hr.Timestamp<0, :) = [];
data.hr(data.hr.Timestamp>total_length, :) = [];
data.hr(isnan(data.hr.Timestamp), :) = [];

%% Save.
save(savepath, 'data')

end

function SyncNIRS(backuppath, savepath, syncIdx)

%% Fileinfo.
load(backuppath,'-mat')

lastTrigger = syncIdx.lastTrigger;

if isfield(syncIdx, 'AUDIO')
    allTriggers = find(nirs.s);
    audioTrigger = allTriggers(syncIdx.AUDIO);
    data.s(audioTrigger) = 0;
end

trigger_time = data.t(find(data.s));  
disp(['NIRS has ', num2str(length(trigger_time)),' triggers.'])
delay_start = trigger_time(lastTrigger);
total_length = data.t(end) - trigger_time(lastTrigger);
data.t = data.t - delay_start;

data.d(data.t<0,:) = [];
data.s(data.t<0) = [];
data.aux(data.t<0,:) = [];
data.t(data.t<0) = [];

data.d(data.t>total_length,:) = [];
data.s(data.t>total_length) = [];
data.aux(data.t>total_length,:) = [];
data.t(data.t>total_length) = [];

%% Save.
save(savepath, 'data');
end
