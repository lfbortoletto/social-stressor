function movingPerc = movingPercentile(signal, windowSize, percentile)
    % movingPercentile calculates the moving percentile of a signal
    %
    % movingPerc = movingPercentile(signal, windowSize, percentile)
    %
    % Inputs:
    %   signal     - Input signal (vector)
    %   windowSize - Size of the moving window (scalar)
    %   percentile - Percentile to calculate (scalar, between 0 and 100)
    %
    % Output:
    %   movingPerc - Moving percentile of the input signal (vector)
    
    % Validate inputs
    if ~isvector(signal)
        error('Input signal must be a vector');
    end
    if ~isscalar(windowSize) || windowSize <= 0
        error('Window size must be a positive scalar');
    end
    if ~isscalar(percentile) || percentile < 0 || percentile > 100
        error('Percentile must be a scalar between 0 and 100');
    end
    
    % Initialize the output
    movingPerc = zeros(size(signal));
    
    % Pad the signal with NaNs to handle the edges
    padSize = floor(windowSize / 2);
    paddedSignal = [nan(padSize, 1); signal(:); nan(padSize, 1)];
    
    % Calculate the moving percentile
    for i = 1:length(signal)
        window = paddedSignal(i:i + windowSize - 1);
        movingPerc(i) = prctile(window, percentile);
    end
end
