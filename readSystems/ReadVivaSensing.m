function [GW4] = ReadVivaSensing(folderPath, filenameSave)

if ~(folderPath(end) == '\' || folderPath(end) == '/')
    folderPath = [folderPath, '\'];
end

GW4 = [];
[filenames, ~] = getAllFiles(folder);

%% Check existance.
if isempty(filenames)
    disp(['No GW4 files found in ', folder])
    return
end

%% Load files.
for k = 1:numel(filenames)
    if contains(filenames{k}, 'Acc')
        acc = readtable(filenames{k},'PreserveVariableNames',1);
    elseif contains(filenames{k}, 'PpgI')
        ppgIR = readtable(filenames{k},'PreserveVariableNames',1);
    elseif contains(filenames{k}, 'PpgG')
        ppgG = readtable(filenames{k},'PreserveVariableNames',1);
    elseif contains(filenames{k}, 'HR')
        hr = readtable(filenames{k},'PreserveVariableNames',1);
    end  
end

if ~exist('acc', 'var')
    disp(['No GW4 files found in ', folder])
    return
end

%% Adjust timestamp.
acc.Timestamp = (acc.Timestamp - acc.Timestamp(1))/10^3;
ppgIR.Timestamp = (ppgIR.Timestamp - ppgIR.Timestamp(1))/10^3;
ppgG.Timestamp = (ppgG.Timestamp - ppgG.Timestamp(1))/10^3;
hr.Timestamp = (hr.Timestamp - hr.Timestamp(1))/10^3;

%% Find triggers (abrupt changes in acc).
acc_freq = 1/nanmedian(diff(acc.Timestamp));
acc_data = acc.(4);
f1 = figure; plot(acc.Timestamp, acc_data);
trigger_time = input('Insert trigger time (s): ');
close(f1)
trigger_time = round(trigger_time*acc_freq)/acc_freq;

%Adjust trigger time to zero.
acc.Timestamp = acc.Timestamp - trigger_time;
ppgIR.Timestamp = ppgIR.Timestamp - trigger_time;
ppgG.Timestamp = ppgG.Timestamp - trigger_time;
hr.Timestamp = hr.Timestamp - trigger_time;

%Remove data prior to trigger.
acc(acc.Timestamp<0,:) = [];
ppgIR(ppgIR.Timestamp<0,:) = [];
ppgG(ppgG.Timestamp<0,:) = [];
hr(hr.Timestamp<0,:) = [];

%% Store smartwatch data in GW4 struct.
GW4.acc = acc; 
GW4.ppgIR = ppgIR;
GW4.ppgG = ppgG;
GW4.hr = hr;

save([folderPath, filenameSave, '.gw4'], 'GW4')


end