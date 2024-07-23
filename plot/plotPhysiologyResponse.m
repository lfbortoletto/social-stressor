% This script is intended to plot the average physiological response at the
% group or subject level.
%
% Input:
% 
%   preprocPath: The directory path containing the preprocessed physiology
%   files. If only one file is found, the plot will display the average
%   response for that individual subject. If multiple files are found, the
%   plot will show the group average response.

function plotPhysiologyResponse(preprocPath)
    % Load and preprocess data
    physiologyData = loadPhysiologyData(preprocPath);

    % Remove participants with poor signal quality or exclusion criteria
    physiologyData = removeBadData(physiologyData, []);

    % Compute average responses
    averageResponse = computeAverageResponse(physiologyData);

    % Plot the responses
    plotResponses(physiologyData, averageResponse);
end

function physiologyData = loadPhysiologyData(preprocPath)
    [preprocPathList, ~] = getAllFiles(preprocPath);
    participant = 1;
    physiologyData = {};
    for files = 1:length(preprocPathList)
        if contains(preprocPathList{files}, '.physiology')
            physiologyData{participant, 1} = load(preprocPathList{files}, '-mat');
            participant = participant + 1;
        end
    end
end

function physiologyData = removeBadData(physiologyData, badDataList)
    badDataList = unique(badDataList);
    physiologyData(badDataList, :) = [];
end

function averageResponse = computeAverageResponse(physiologyData)
    averageResponse = struct('controlStart', [], 'controlEnd', [], 'stressStart', [], 'stressEnd', []);
    
    % Define task indices
    tasks = {'control', 1, 3; 'stress', 2, 4};
    
    if numel(physiologyData) > 1
        groupFlag = 1;
    else
        groupFlag = 0;
    end
    
    for taskIdx = 1:size(tasks, 1)
        taskName = tasks{taskIdx, 1};
        hearingIdx = tasks{taskIdx, 2};
        speechIdx = tasks{taskIdx, 3};
        
        for participant = 1:length(physiologyData)
            data = physiologyData{participant}.physiology;
            fSampling = 1 / (data.time(2) - data.time(1));
            components = fields(data.components);
            numberOfComponents = length(components);

            stimStartIdx = find(data.stimuli(:, hearingIdx) == 1);
            totalTaskSamples = round((data.taskDuration{hearingIdx} + data.taskDuration{speechIdx}) * fSampling);
            stimEndIdx = stimStartIdx + totalTaskSamples;
            baselineLength = round(10 * fSampling);
            stimuliLength = round(100 * fSampling);

            for physiologicalVariable = 1:numberOfComponents
                physiologyTimeSeries = data.components.(components{physiologicalVariable});
                [averageStartTemp] = BlockAverage(physiologyTimeSeries, stimStartIdx, stimuliLength, baselineLength, groupFlag);
                [averageEndTemp] = BlockAverage(physiologyTimeSeries, stimEndIdx, stimuliLength, baselineLength, groupFlag);
                
                if groupFlag == 1
                    averageResponse.([taskName 'Start']).(components{physiologicalVariable})(:, participant) = averageStartTemp;
                    averageResponse.([taskName 'End']).(components{physiologicalVariable})(:, participant) = averageEndTemp;
                else
                    averageResponse.([taskName 'Start']).(components{physiologicalVariable}) = averageStartTemp;
                    averageResponse.([taskName 'End']).(components{physiologicalVariable}) = averageEndTemp;
                end
            end
        end
    end
end

function plotResponses(physiologyData, averageResponse)
    components = fields(averageResponse.controlStart);
    numberOfComponents = length(components);
    colorList = {'b', 'r', 'c', 'y', [0.9290 0.6940 0.1250], 'g', 'b'};
    yUnit = {'(bpm)', '(mmHg)', '(ml)', '(bpm)', '(a.u.)', '(mS)', '(a.u.)'};
    titleList = ["Heart Rate", "Mean Arterial Pressure", "Stroke Volume", "Respiration Rate", "End-tidal CO2", "Electrodermal Activity", "Accelerometry"];

    for physiologicalVariable = 1:numberOfComponents
        % Figure properties
        f = figure;
        subplot(1,2,1); box off; hold on;
        title(titleList(physiologicalVariable), 'fontweight', 'bold');
        ylabel(['Baseline changes ', yUnit{physiologicalVariable}]);

        % Plot control response
        plotGroupData(averageResponse.controlStart.(components{physiologicalVariable}), physiologyData, 'k', '-');

        % Plot stress response
        plotGroupData(averageResponse.stressStart.(components{physiologicalVariable}), physiologyData, colorList{physiologicalVariable}, '-');

        % Figure formatting
        yline(0, '-k');
        xline(0, '-k');
        legend('Control', 'Stress', 'Location', 'northeast');
        xlabel('Elapsed time post-stimuli start (s)');
        xlim([-10, 60]);
        ax = gca;
        ax.FontSize = 18;
        ax.FontName = 'Times New Roman';
        pbaspect([1,1,1]);
        
        % Figure properties
        subplot(1,2,2); box off; hold on;
        title(titleList(physiologicalVariable), 'fontweight', 'bold');
        ylabel(['Baseline changes ', yUnit{physiologicalVariable}]);
        
        % Plot control response
        plotGroupData(averageResponse.controlEnd.(components{physiologicalVariable}), physiologyData, 'k', '-');

        % Plot stress response
        plotGroupData(averageResponse.stressEnd.(components{physiologicalVariable}), physiologyData, colorList{physiologicalVariable}, '-');

        % Figure formatting
        yline(0, '-k');
        xline(0, '-k');
        legend('Control', 'Stress', 'Location', 'northeast');
        xlabel('Elapsed time post-stimuli end (s)');
        xlim([-10, 60]);
        ax = gca;
        ax.FontSize = 18;
        ax.FontName = 'Times New Roman';
        pbaspect([1,1,1]);
        
        monitorDimensions = getMonitorSize;
        monitorWidth = monitorDimensions(3);
        monitorHeight = monitorDimensions(4);
        figureWidth = monitorWidth/2;
        figureHeight = monitorHeight/2;
        f.Position = [monitorWidth/4, monitorHeight/4, figureWidth, figureHeight];
    end
end

function plotGroupData(groupResponse, physiologyData, color, lineStyle)
    sampleSizeArray = size(groupResponse, 2) - sum(isnan(groupResponse'), 1)';
    maxSeriesIndex = size(groupResponse, 1);
    baselineTimeLength = 10;
    timings = physiologyData{1}.physiology.time;
    timings = timings(1:maxSeriesIndex) - baselineTimeLength;

    M = nanmean(groupResponse, 2);
    STD = nanstd(groupResponse, [], 2);
    SEM = STD ./ sqrt(sampleSizeArray);

    X = [timings; flipud(timings)];
    Y = [M + SEM; flipud(M - SEM)];
    h = patch(X, Y, lineStyle);
    h.EdgeColor = 'none';
    h.FaceColor = color;
    alpha(h, 0.5);
    plot(timings, M, lineStyle, 'color', 'k', 'linewidth', 1, 'HandleVisibility','off');
end

function [averageResponse] = BlockAverage(timeSeries, stimuliIdx, stimuliLength, baselineLength, groupFlag)
    stimuliIdx = stimuliIdx(:);
    numberOfStimuli = length(stimuliIdx);
    blockTimeSeries = nan(stimuliLength + baselineLength, numberOfStimuli);

    for stimuli = 1:numberOfStimuli
        baseline = mean(timeSeries(stimuliIdx(stimuli) - baselineLength : stimuliIdx(stimuli)));
        blockTimeSeries(:, stimuli) = timeSeries(stimuliIdx(stimuli) - baselineLength : stimuliIdx(stimuli) + stimuliLength - 1) - baseline;
    end
    
    if groupFlag == 1
        averageResponse = mean(blockTimeSeries, 2);
    else
        averageResponse = blockTimeSeries;
    end
end
