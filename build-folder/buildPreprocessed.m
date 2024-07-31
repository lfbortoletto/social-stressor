clear; clc;

%% Define paths.
backupPath = '';
rawPath = '';
preprocPath = '';

%% Preprocess physiology data and store GLM data.
dispFigure = 0;
for participant = 21
    if participant < 10
        dataName = ['subject-00',num2str(participant)];
    else
        dataName = ['subject-0',num2str(participant)];
    end
    disp(participant)
    PreprocessPhysiology(rawPath, preprocPath, dataName);
end
close all

%% Auxiliary functions.

function PreprocessPhysiology(rawPath, savePath, dataName)

%% Pre-processing parameters.
physiology.PreProcParams.FilterFreq.HR = [0.005 0.5]; 
physiology.PreProcParams.FilterFreq.MAP = [0.005 0.5]; 
physiology.PreProcParams.FilterFreq.CO = [0.005 0.5]; 
physiology.PreProcParams.FilterFreq.RR = [0.005 0.5]; 
physiology.PreProcParams.FilterFreq.CO2 = [0.005 0.5]; 
physiology.PreProcParams.FilterFreq.EDA = [0.005 0.5]; 
physiology.PreProcParams.FilterFreq.ACC = [0.005 0.5]; 
physiology.PreProcParams.fSample = 6.25;

%% Load physiology data.

[rawPathList, ~] = getAllFiles([rawPath, dataName]);
for files = 1:length(rawPathList)
    
    if contains(rawPathList{files},'.nirs')
        nirs = load(rawPathList{files},'-mat'); 
        nirs = nirs.data;
    end
    
    if contains(rawPathList{files},'.finometer')
        finometer = load(rawPathList{files},'-mat'); 
        finometer = finometer.data;
    end
    
    if contains(rawPathList{files},'.G3C')
        g3c = load(rawPathList{files},'-mat'); 
        g3c = g3c.data;
    end
    
    if contains(rawPathList{files},'.eda')
        eda = load(rawPathList{files},'-mat'); 
        eda = eda.edamove;
    end
    
end

if ~exist('nirs', 'var')
    disp([dataName, ' nirs file not found.']);
    return
end

%% Find stimuli durations. 
[nirs, taskDuration] = fillStimuli(nirs, dataName, physiology);
physiology.stimuli = nirs.s;
physiology.taskDuration = taskDuration;

%% Process physiology data.
if exist('finometer', 'var')
    [physiology] = PreProcessFinometer(physiology, finometer, nirs);
end

if exist('g3c', 'var')
    [physiology] = PreProcessG3C(physiology, g3c, nirs);
end

if exist('eda', 'var')
    [physiology] = PreProcessEda(physiology, eda, nirs);
end

%% Save physiology data into new directory.
if ~exist([savePath, dataName], "dir")
    mkdir([savePath, dataName])
end
save([savePath, dataName, '\', dataName, '.physiology'], 'physiology');

end

function [physiology] = PreProcessFinometer(physiology, finometer, nirs)

bpf = physiology.PreProcParams.FilterFreq;

% Store data variables.
tWaveforms = finometer.waveforms.("Time (s)");
tBeats = finometer.beats.("Time (s)");
yHR = finometer.beats.("Heart rate (bpm)");
yMAP = finometer.beats.("Mean Pressure (mmHg)");
ySV = finometer.beats.("Stroke Volume (ml)");

% Downsample.
timeArray = min(nirs.t) : 1/physiology.PreProcParams.fSample : max(nirs.t); timeArray(:);
yqHR = interp1(tBeats, yHR, timeArray)';
yqMAP = interp1(tBeats, yMAP, timeArray)';
yqSV = interp1(tBeats, ySV, timeArray)';

% Frequency filter.
filtHR = hmrBandpassFiltLOB(yqHR, physiology.PreProcParams.fSample, bpf.HR(1), bpf.HR(2));
filtMAP = hmrBandpassFiltLOB(yqMAP, physiology.PreProcParams.fSample, bpf.MAP(1), bpf.MAP(2));
filtSV = hmrBandpassFiltLOB(yqSV, physiology.PreProcParams.fSample, bpf.CO(1), bpf.CO(2));

% Store data into new field.
physiology.time = timeArray - timeArray(1); physiology.time = physiology.time(:);
physiology.components.hr  = filtHR(:);
physiology.components.map  = filtMAP(:);
physiology.components.sv  = filtSV(:);

end

function [physiology] = PreProcessEda(physiology, eda, nirs)

bpf = physiology.PreProcParams.FilterFreq;

% Store data variables.
tEDA = eda.eda.t;
tACC = eda.acc.t;
yEDA = eda.eda.data;
yACC = (eda.acc.data_1 + eda.acc.data_2 + eda.acc.data_3)/3;

% Downsample.
timeArray = min(nirs.t) : 1/physiology.PreProcParams.fSample : max(nirs.t); timeArray(:);
yqEDA = interp1(tEDA, yEDA, timeArray)';
yqACC = interp1(tACC, yACC, timeArray)';

% Frequency filter.
filtEDA = hmrBandpassFiltLOB(yqEDA, physiology.PreProcParams.fSample, bpf.EDA(1), bpf.EDA(2));
filtACC = hmrBandpassFiltLOB(yqACC, physiology.PreProcParams.fSample, bpf.ACC(1), bpf.ACC(2));

% Store data into new field.
physiology.time = timeArray - timeArray(1); physiology.time = physiology.time(:);
physiology.components.eda  = filtEDA(:);
physiology.components.acc  = filtACC(:);

end

function [physiology] = PreProcessG3C(physiology, g3c, nirs)

bpf = physiology.PreProcParams.FilterFreq;

% Extract respiration rate.
[timestamp, ETCO2, RR] = ExhaledCO2(g3c.t, g3c.d);

% Downsample.
timeArray = min(nirs.t) : 1/physiology.PreProcParams.fSample : max(nirs.t); timeArray(:);
yqRR = interp1(timestamp, RR, timeArray)';
yqCO2 = interp1(timestamp, ETCO2, timeArray)';

% Frequency filter.
filtRR = hmrBandpassFiltLOB(yqRR, physiology.PreProcParams.fSample, bpf.RR(1), bpf.RR(2));
filtCO2 = hmrBandpassFiltLOB(yqCO2, physiology.PreProcParams.fSample, bpf.CO2(1), bpf.CO2(2));

% Store data into new field.
physiology.time = timeArray - timeArray(1); physiology.time = physiology.time(:);
physiology.components.RR  = filtRR(:);
physiology.components.co2  = filtCO2(:);

end

function [nirs] = PreProcessNIRS(physiology, nirs)
    
    nirs.d = [];
    nirs.aux = [];
    nirs.SD = [];
    nirs.StimTriggers = [];
    
    timeArray = min(nirs.t) : 1/physiology.PreProcParams.fSample : max(nirs.t); 
    timeArray = timeArray(:);
    
    stimIdx = find(nirs.s);
    stimTime = nirs.t(stimIdx);
    
    for stimuli = 1:length(stimIdx)
        [~, newStimIdx(stimuli)] = min(abs(timeArray - stimTime(stimuli)));
    end
    
    nirs.t = timeArray;
    nirs.s = zeros(length(timeArray), 1);
    nirs.s(newStimIdx) = 1;
    
end

function [nirs, taskDuration] = fillStimuli(nirs, dataName, physiology)

    load('G:\Drives compartilhados\LOB\datasets\A10_Ansiedade\social-stressor\SocialStressor.mat')
    controlStart = any(SocialStressor.questionsOrder(1:15, str2double(dataName(end-2:end))) == 1);
    
    nirs.s(1) = 0;
    [nirs] = PreProcessNIRS(physiology, nirs);

    triggerIndex = find(nirs.s);
    triggerTimings = nirs.t(triggerIndex);
    lastConditionTrigger = find(diff(triggerTimings)>90);
    
    if controlStart == 1
        triggersHearingControl = triggerIndex(1 : 3 : lastConditionTrigger);
        triggersHearingStress = triggerIndex(lastConditionTrigger + 1 : 3 : end);
        triggersSpeechControl = triggerIndex(2 : 3 : lastConditionTrigger);
        triggersSpeechStress = triggerIndex(lastConditionTrigger + 2 : 3 : end);
        
        taskSampleSize{1} = triggerIndex(2:3:lastConditionTrigger) - triggerIndex(1:3:lastConditionTrigger);
        taskSampleSize{2} = triggerIndex(lastConditionTrigger + 2 : 3 : end) - triggerIndex(lastConditionTrigger + 1 : 3 : end);
        taskSampleSize{3} = triggerIndex(3:3:lastConditionTrigger) - triggerIndex(2:3:lastConditionTrigger);
        taskSampleSize{4} = triggerIndex(lastConditionTrigger + 3 : 3 : end) - triggerIndex(lastConditionTrigger + 2 : 3 : end);
    else
        triggersHearingStress = triggerIndex(1 : 3 : lastConditionTrigger);
        triggersHearingControl = triggerIndex(lastConditionTrigger + 1 : 3 : end);
        triggersSpeechStress = triggerIndex(2 : 3 : lastConditionTrigger);
        triggersSpeechControl = triggerIndex(lastConditionTrigger + 2 : 3 : end);
        
        taskSampleSize{2} = triggerIndex(2:3:lastConditionTrigger) - triggerIndex(1:3:lastConditionTrigger);
        taskSampleSize{1} = triggerIndex(lastConditionTrigger + 2 : 3 : end) - triggerIndex(lastConditionTrigger + 1 : 3 : end);
        taskSampleSize{4} = triggerIndex(3:3:lastConditionTrigger) - triggerIndex(2:3:lastConditionTrigger);
        taskSampleSize{3} = triggerIndex(lastConditionTrigger + 3 : 3 : end) - triggerIndex(lastConditionTrigger + 2 : 3 : end);
    end
    nirs.s(:,1) = zeros(size(nirs.s, 1), 1);
    nirs.s(:,2) = zeros(size(nirs.s, 1), 1);
    nirs.s(:,3) = zeros(size(nirs.s, 1), 1);
    nirs.s(:,4) = zeros(size(nirs.s, 1), 1);
    
    nirs.s(triggersHearingControl,1) = 1;
    nirs.s(triggersHearingStress, 2) = 1;
    nirs.s(triggersSpeechControl, 3) = 1;
    nirs.s(triggersSpeechStress,  4) = 1;
    
    taskDuration{1} = taskSampleSize{1}./physiology.PreProcParams.fSample;
    taskDuration{2} = taskSampleSize{2}./physiology.PreProcParams.fSample;
    taskDuration{3} = taskSampleSize{3}./physiology.PreProcParams.fSample;
    taskDuration{4} = taskSampleSize{4}./physiology.PreProcParams.fSample;
    
end
