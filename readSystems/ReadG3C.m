function [varargout] = ReadG3C(videoPath, edgeRemove, cursorLag, frameDiff)
%
% This function converts video files of physiological monitoring from G3C
% patient's monitor system to its corresponding values. Videos should be 
% at least 3 minutes, to reduce instrument noise. Three input arguments can
% be added:
%
% 1) videoPath: file path corresponding to the .mp4 video. If omitted,
% displays a dialog box for the user to fill in.
% 2) edgeRemove: amount of pixels to be removed from the lateral edges of
% the physiological time series selected. (Default '5').
% 3) cursorLag: pixel difference between measured physiology and G3C
% cursor. (Default '10').
% 4) frameDiff: Distance between the two frames used to find G3C moving
% cursor. Increasing frameDiff yields higher precision but lower accuracy
% for cursor identification. (Default '15')
%
% If one output argument is passed, the converted data will be stored in a 
% struct containing the raw data in units proportional to mmHg (d), video 
% frame acquisition time (t) and file informations (info). Otherwise, if no
% output argument is passed then a .G3C file will be saved on the file 
% folder containing an struct called G3C.
%
% Created by: L. F. Bortoletto (2023/2/24)
%
% Last Modified by:
%   L. F. Bortoletto (2023/2/25): addition of edgeRemove and cursorLag to
% increase video to data correspondence.
%   L. F. Bortoletto (2023/3/31): remove static objects throughout the
% video. This comes with the assumption that the video is long enough 
% (>3 minutes) so that non-static objects do not interfer with global pixel
% intensity.
%   L. F. Bortoletto (2023/4/01): Minor update. Display time estimate to
% complete steps processing.
%   L. F. Bortoletto (2023/4/05): addition of frameDiff to improve cursor
% identification.
%   L. F. Bortoletto (2023/8/03): draw rectangle over the middle frame.
%   L. F. Bortoletto (2024/3/20): video segmentation to reduce memory.
%   L. F. Bortoletto (2024/7/05): updated elapsed time display.
%
% To-do:
%
% 1. Quality control: cursorPosition is predictable after a few seconds of 
% video. Therefore, we could use deviations from the predictable value to 
% convert CO2 curve to NaN.
%
% 2. Quality control: quantify amount of deviation and use this as an 
% output for signal quality.
%
% 3. General: find selected curve RGB.
%
% -------------------------------------------------------------------------

% Define the path to the mp4 video file
if ~exist('videoPath','var')
    [G3Cfile, filepath] = uigetfile('*.mp4','Choose the .mp4 file to read');
    videoPath = [filepath G3Cfile];
end

% Define the amount of pixels to be removed from the lateral edges of the video
if ~exist('edgeRemove','var')
    edgeRemove = 5;
end

% Define the delay between data acquisition and G3C monitor cursor
if ~exist('cursorLag','var')
    cursorLag = 10;
end

% Define the distance between the two frames used to find G3C moving cursor
if ~exist('frameDiff','var')
    frameDiff = 15;
end

% Create a VideoReader object
vidReader = VideoReader(videoPath);

% Get video information
numFrames = vidReader.NumFrames;
frameHeight = vidReader.Height;
frameWidth = vidReader.Width;

% Read the middle frame of the video and display it
frame1 = read(vidReader, round(numFrames/2));
fig1 = figure;
imshow(frame1);
title('Draw a rectangle around the desired time series');

% Allow the user to select the upper and lower bounds in the image
roi = drawrectangle;
upperBound = round(roi.Position(2));
lowerBound = round(roi.Position(2) + roi.Position(4));
rightBound = round(roi.Position(1) + roi.Position(3));
leftBound  = edgeRemove;

% Close figure
close(fig1)

% Segment video into multiple parts due to memory capacity.
rectangleHeight = lowerBound - upperBound + 1;
rectangleWidth = rightBound - leftBound + 1;
FrameCapacity = vidReader.FrameRate*60*10; % maximum of 10 minutes of video.
numberOfSegments = ceil(numFrames/FrameCapacity);

% Update number of frames per segment.
numFrames = floor(numFrames/numberOfSegments);

% Update number of total steps.
numberOfSteps = numberOfSegments*3;
currentStep = 1;

for segment = 1:numberOfSegments

% Clear video matrix.
clear videoMatrix

% Frames jump to current segment.    
stepToSegment = numFrames*(segment - 1);
    
% Pre-allocate the matrix that will store the video
videoMatrix = zeros(lowerBound - upperBound + 1, rightBound - leftBound + 1, numFrames, 'uint8');

% Pre-allocate the vector of the monitored parameter
if segment == 1
    G3C.d = zeros(1, numFrames*numberOfSegments);
    G3C.t = zeros(1, numFrames*numberOfSegments);
end

% Loop through all the frames and store them in the matrix
n = 1; 
tic;
for i = 1:numFrames
    % Read a frame from the video
    frame = read(vidReader, i + stepToSegment);
    
    % Crop the image between the specified upper and lower bounds
    frameCrop = frame(upperBound:lowerBound, leftBound:rightBound, :);

    % Convert the RGB image to grayscale
    frameGray = rgb2gray(frameCrop);

    % Store the frame in the video matrix
    videoMatrix(:, :, i) = frameGray;
    
    if i >= (numFrames*0.1*n)
        t1 = toc; 
        elapsedTime = t1;
        timeLeft = elapsedTime/(0.1*n) - elapsedTime;
        clc
        disp(['Step ', num2str(currentStep),'/', num2str(numberOfSteps), ': ', num2str(10*n), ...
            '% completed. Estimated time left on this step: ', num2str(timeLeft), ' (s).']); 
        n = n + 1;
    end
end

% Update current step.
currentStep = currentStep + 1;

% Obtain pixel mean intensity throughout the video.
globalFrame = sum(videoMatrix,3);
globalFrame = globalFrame./max(max(globalFrame));

% Increase intensity contrast.
globalFrame = globalFrame.^2;

% Invert color map.
globalFrame = abs(globalFrame-1);

% Binarize image.
threshold = mean(globalFrame,'all') - 5*std(globalFrame,[],'all');
globalFrame(globalFrame<threshold) = 0;
globalFrame(globalFrame>=threshold) = 1;

% Remove global frame noise and inflate region of no interest. (Example
% data processed with and without erode followed by dilation is present on
% "inverse_closing.g3c")
globalFrame = imerode(globalFrame, strel("disk",5));
globalFrame = imdilate(globalFrame, strel("disk",5));

% Invert color map to original.
globalFrame = abs(globalFrame-1);

% Display processed global frame.
figure; imshow(globalFrame); hold off;

% Remove static objects throughout the video.(Assumption: video is long
% enough, so that non-static objects do not interfer with mean pixel 
% intensity.)
n = 1; 
tic;
globalFrame = logical(globalFrame);
for frame = 1:size(videoMatrix,3)
    picture = squeeze(videoMatrix(:,:,frame));
    picture(globalFrame) = 0;
    videoMatrix(:,:,frame) = picture;
    if frame >= (size(videoMatrix,3)*0.1*n)
        t1 = toc; 
        elapsedTime = t1;
        timeLeft = elapsedTime/(0.1*n) - elapsedTime;
        clc
        disp(['Step ', num2str(currentStep),'/', num2str(numberOfSteps), ': ', num2str(10*n), ...
            '% completed. Estimated time left on this step: ', num2str(timeLeft), ' (s).']); 
        n = n + 1;
    end
end

% Update current step.
currentStep = currentStep + 1;

% Reopen globalFrame.
clear globalFrame
globalFrame = sum(videoMatrix,3);

% Find and remove right columns with low pixel intensity change.
columnIntensity = sum(globalFrame,1);
imXCenter = round(rightBound/2);
[~,column] = mink(columnIntensity(imXCenter:end),5);
rightBoundUpdate = imXCenter + round(min(column)) - edgeRemove;

% Pre-allocate matrix to store video data.
videoMatrix = videoMatrix(:, 1:rightBoundUpdate, :);

% Pre-allocate array to store cursor position.
cursorPos = zeros(1,numFrames);

n = 1; 
tic;
for i = 1:numFrames
    % Find displayed time series.
    [~, I] = max(videoMatrix(:, :, i)); 
    I = -I;

    % Find cursor.
    if i <= frameDiff || i >= numFrames - frameDiff
        [~, cursorPos(i)] = min(sum(videoMatrix(:, :, i)));
    else
        [~, highIntensityIdx] = maxk(sum(videoMatrix(:, :, i+frameDiff) - videoMatrix(:, :, i)), frameDiff);
        highIntensityIdx = max(highIntensityIdx);
        cursorPos(i) = highIntensityIdx - frameDiff - 1;
    end
    
    % Store monitored physiological data.
    if cursorPos(i) < cursorLag + 1
        G3C.d(i + stepToSegment) = I(rightBoundUpdate + cursorPos(i) - cursorLag);
        G3C.t(i + stepToSegment) = (i + stepToSegment - 1)/vidReader.FrameRate;
    else
        G3C.d(i + stepToSegment) = I(cursorPos(i) - cursorLag);
        G3C.t(i + stepToSegment) = (i + stepToSegment - 1)/vidReader.FrameRate;
    end
    if i >= (numFrames*0.1*n)
        t1 = toc; 
        elapsedTime = t1;
        timeLeft = elapsedTime/(0.1*n) - elapsedTime;
        clc
        disp(['Step ', num2str(currentStep),'/', num2str(numberOfSteps), ': ', num2str(10*n), ...
            '% completed. Estimated time left on this step: ', num2str(timeLeft), ' (s).']); 
        n = n + 1;
    end
    
    if isfield('G3C', 'cursorPosition')
        G3C.cursorPosition = [G3C.cursorPosition, cursorPos];
    else
        G3C.cursorPosition = cursorPos;
    end
end

% Update current step.
currentStep = currentStep + 1;

end

% Update G3C struct information.
G3C.info.filepath = videoPath;
G3C.info.videoInfo = vidReader;

% Tranpose data.
G3C.d = G3C.d(:);
G3C.t = G3C.t(:);
G3C.cursorPosition = G3C.cursorPosition(:);

if nargout == 0
    if exist(videoPath(1:end-4)+".G3C",'file')
        disp("There is already a .G3C file in the folder. To replace it type (1), otherwise type (0).");
        overwrite = input("Replace: ");
        if overwrite == 1
            save(videoPath(1:end-4)+".G3C",'G3C')
        end
    else
       disp("A .G3C file was saved in the video folder.");
       save(videoPath(1:end-4)+".G3C",'G3C')
    end
elseif nargout == 1
    varargout{1} = G3C;
end

end