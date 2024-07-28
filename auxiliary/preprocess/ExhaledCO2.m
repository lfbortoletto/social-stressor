function [timestamp, ETCO2, RR] = ExhaledCO2(timing, signal)

fSample = round(1/(timing(2) - timing(1)));
signalBaseline = movingPercentile(signal, fSample*10, 1);
signalBaselineCorrected = signal - signalBaseline;
signal = signalBaselineCorrected;

signalNorm = zscore(signal);
signalFilt = movmedian(signalNorm, fSample);
signalDiff = diff(signalFilt);
signalDiff(signalDiff > 0) = 0;
signalDiff = signalDiff.^2;
[~, exhaleIdx] = findpeaks(signalDiff, 'MinPeakDistance',2*fSample);

cropWindowSize = fSample;
for cycle = 2:length(exhaleIdx)-1
    currentIdx = exhaleIdx(cycle);
    cropData = signal(currentIdx - cropWindowSize : currentIdx + cropWindowSize);
    [~, cropMaxIdx] = max(cropData);
    updatedIdx = cropMaxIdx - cropWindowSize + 1 + currentIdx;
    exhaleIdx(cycle) = updatedIdx;
end

timestamp = exhaleIdx/fSample;

ETCO2 = signal(exhaleIdx);
outlierIdx = abs(zscore(ETCO2)) > 2;
ETCO2(outlierIdx) = nan;
exhaleIdx(outlierIdx) = nan;

ETCO2 = smooth(ETCO2,'rlowess', round(fSample/6));
outlierIdx = abs(zscore(ETCO2)) > 2;
ETCO2(outlierIdx) = nan;
exhaleIdx(outlierIdx) = nan;

ETCO2 = fillmissing(ETCO2, 'linear');

figure; hold on;
plot(signal,'b'); plot(signalDiff, 'r');
plot(exhaleIdx, ETCO2, '-r*');

RR = 60./diff(exhaleIdx/fSample);
RR(end+1) = RR(end);
RR = fillmissing(RR, 'linear');
outlierIdx = abs(zscore(RR)) > 2;
RR(outlierIdx) = nan;
RR = fillmissing(RR, 'linear');

timestamp = timestamp(:);
ETCO2 = ETCO2(:);
RR = RR(:);

end