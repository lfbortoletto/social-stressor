function varargout = ReadNIRSCOUT(folderPath, layoutFilePath, filenameSave)
%
% This function reads NIRScout (NIRx) files used in Mesquita's lab
% and collaborators. It needs 2 input arguments:
%  1) folderPath: folder path that contains all nirs files.
%  2) layoutFilePath: Map and Map3d structure from a .layout file.
%  3) filenameSave: saving filename as a char array.
% The combined data will be stored in an object. 
% If no output argument is passed, a .lob file will be saved in the 
% input folder containing an object called data.
%
% Created by: R. Mesquita (2018/3/14)
% Last Modified by:
%   R. Mesquita (2018/3/14): to read NIRx instruments

% Check if filename and probefile are provided
if ~exist('folderPath', 'var')
    uiwait(msgbox({'Missing a folder to read the data from.' ...
        'Please select the FOLDER where all NIRS data is located'}, ...
        'Warning', 'warn'));
    DataFolder = uigetdir; % get directory list
    DataFolder = {DataFolder};
    if isempty(DataFolder)
        return
    else
        NIRx_file = dir([DataFolder{1} filesep 'NIR*.hdr']); % get file list
        hdrPath = [DataFolder{1} filesep NIRx_file(1).name];
    end
else
    [filePathList, ~] = getAllFiles(folderPath);
    for file = 1:length(filePathList)
        if contains(filePathList{file}(end-4:end), '.hdr')
            hdrPath = filePathList{file};
        end
    end
    if isempty(hdrPath)
        disp('No .HDR was found in the given folder path.')
        return
    end
end
% Unwrap cw-nirs info from NIRx files
data = RunNIRx2nirs(hdrPath, layoutFilePath);
saved_file = [filenameSave '.nirs'];

% Check stimulation vector for run
foo = find(data.s(:) == 1);
if ~isempty(foo)
    [data.s, data.StimTriggers] = ConvertTrigger2Stim(data.t, data.s);
end

if nargout > 0
    varargout{1} = data; % Save data on an argument
else
    save(saved_file, '-mat', 'data');
    uiwait(msgbox({'We saved your data in a nicer .nirs file', ...
        'in the same folder where your data came from', ...
        'Good luck in your analysis!'}, 'Success!'));
end

end

function [data, varargout] = GetNIRxData(filename, probefile)
% Unwrap cw-nirs info from NIRx files
data = RunNIRx2nirs(filename, probefile);

if nargout > 0; varargout{1} = filename; end
end

function data = RunNIRx2nirs(HDRfile, layoutFilePath)
% Part 1: Open and Extract Header Information
[SD, mask, markers] = GetHDRInfo(HDRfile);

% Part 2: Add in the optical geometry information
SD = ReadLayoutFile(layoutFilePath, SD);

% Part 3: Read and Organize Intensity from NIRx Wavelength files
[t, d] = GetIntensityData(HDRfile, mask, SD);

% Part 4: Organize stimulation & auxiliary info from markers
[s, aux] = GetStim(markers, length(t));

% Part 5: create CW-NIRS object
data = cw_nirs;
data.t = t; data.d = d; data.s = s; data.aux = aux; data.SD = SD;
end


function [SD,mask,markers] = GetHDRInfo(HDRfile)

fi = fopen(HDRfile,'rt');

% Locate experiment protocol details from header
position='aaaaaaa';
while sum( position(1:7)~='Sources' ) ~= 0
    clear position
    position = fgetl(fi);
    if length(position) < 7
        position='aaaaaaa';
    end
end
SD.nSrcs = str2num(position(9:end));

position = fgetl(fi);
SD.nDets = str2num(position(11:end));

WavelengthFlag=0;

while(WavelengthFlag==0)
    
    position = fgetl(fi);
    
    if length(position)>11
        if position(1:11) == 'Wavelengths'         
            
            SD.Lambda = str2num(position(14:end-1));           
            WavelengthFlag=1;
            
        end
    end
    
end

position='aaaaaaaaaaaa';
while sum( position(1:12)~='SamplingRate' ) ~= 0
    clear position
    position = fgetl(fi);
    if length(position) < 12
        position = 'aaaaaaaaaaaa';
    end
end
SD.f = str2num(position(14:end));
%SD.Lambda = [760 850];
%if Nfiles == 1
%    disp(' ')
%    disp('IMPORTANT: We are assuming your NIRx system has the following wavelengths: 760 & 850 nm')
%    disp('          (in this order!) If that is not true, please contact someone to fix this.')
%end
%disp(['Starting to work on file ' num2str(Nfiles)])

% Get Event markers from .HDR (it will be used later to build the s
% variable)
while position(1:3)~='Eve'
    clear position
    position = fgetl(fi);
    if length(position) < 3
        position='aaa';
    end
end
position = fgetl(fi);

cnt = 1;
while position(1)~='#'
    markers(cnt,:) = str2num(position);
    position = fgetl(fi);
    cnt=cnt+1;
end
if ~exist('markers')
    markers = [];
end

% Store the SD map distribution
for i=1:5
    position = fgetl(fi);
end
cnt = 1;
while position(1)~='#'
    mask(cnt,:) = str2num(position);
    position = fgetl(fi);
    cnt=cnt+1;
end
fclose(fi);

% Create the MeasList Matrix
SD.MeasList = [];
cnt = 1;
for i=1:SD.nSrcs,
    for j=1:SD.nDets,
        if mask(i,j)~=0
            SD.MeasList(cnt,1) = i;
            SD.MeasList(cnt,2) = j;
            SD.MeasList(cnt,3) = 1;
            cnt = cnt+1;
        end
    end
end

MeasListAux = SD.MeasList;
% SD.MeasList = [SD.MeasList ones(size(SD.MeasList,1),1);...
%     SD.MeasList ones(size(SD.MeasList,1),1)*2];


SD.MeasList = [MeasListAux ones(size(SD.MeasList,1),1)];

for Nlambda = 2:size(SD.Lambda,2)
   SD.MeasList = [SD.MeasList;...
        [MeasListAux Nlambda*ones(size(MeasListAux,1),1)]];        
end

end

function SD = ReadLayoutFile(layoutFilePath,SD)

% Find the SD info for Homer. The .layout file was created by our lab to
% add in structural information (by simple mapping or by digitalization
% with a digitizer).
% IF THERE IS A DIGITIZER, their x,y,z coordinates should be in a
% structure called 'RS_MRI'. The structure contains 2 variables:
% RS_MRI.Map (with 2D topographic info) and RS_MRI.Map3d (with 3D
% coordinates).
% IF THERE IS NO DIGITIZER, then it will look for a variable called Map
% (dimension: Mx3). The first s lines are the x,y,z coordinates of the
% S sources, and the last d lines are the x,y,z coordinates of the D
% detectors. Therefore, M = S + D!
%
% But now NIRx can make you export information on probe through a
% *_nirsInfo.mat file. The below works for both ways.
% (adapted by RM, 1/19/2017).
%
% (adapted by SL,  23/03/2017) - 1. Comented lines 219-223
%                                2. Added a condition to delete
%                                    the SD.SrcPOS and DetPos in the
%                                    second data.
%

% Commented after change on Sep 25, 2017 (not sure if we still need this):


% There is a .layout file in the folder
if ~isempty(layoutFilePath)
    layoutFile = load(layoutFilePath,'-mat');
    variable_name = fieldnames(layoutFile);
    layoutFile = layoutFile.(variable_name{1});
    
    if isfield(layoutFile, 'Map') && isfield(layoutFile, 'Map3d')
        SD.SrcPos = layoutFile.Map(1:SD.nSrcs, :);
        SD.SrcPos_3d = layoutFile.Map3d(1:SD.nSrcs, :);
        SD.DetPos = layoutFile.Map(SD.nSrcs + 1 : end, :);
        SD.DetPos_3d = layoutFile.Map3d(SD.nSrcs + 1 : end, :);
        SD.SrcPos(:,3) = 0;
        SD.DetPos(:,3) = 0;
        SD.SpatialUnit = 'cm';
    else
        disp('There is an error with your .layout file. Please fix it before you continue...')
    end
end

% Check if the number of sources/detectors match the number described in
% the header file. Sometimes there are extra sources/detectors that are not
% really used; one should change the SD.nSrcs/SD.nDets then.
MeasListMax = max(SD.MeasList);
if MeasListMax(1) ~= SD.nSrcs
    disp(['    ATTENTION: The system says you used ' num2str(SD.nSrcs) ' sources.'])
    disp(['               However, we noticed that only ' num2str(MeasListMax(1)) ' are connected.'])
    disp(['               We will discard the remanining ' num2str(abs(SD.nSrcs - MeasListMax(1))) ' sources... OK?'])
    SD.nSrcs = MeasListMax(1);
end
if MeasListMax(2) ~= SD.nDets
    disp(['    ATTENTION: The system says you used ' num2str(SD.nDets) ' detectors.'])
    disp(['               However, we noticed that only ' num2str(MeasListMax(2)) ' are connected.'])
    disp(['               We will discard the remanining ' num2str(abs(SD.nSrcs - MeasListMax(1))) ' detectors... OK?'])
    SD.nDets = MeasListMax(2);
end

end

function [t,d] = GetIntensityData(HDRfile,mask,SD)

% Import Data from all Wavelengths and save on d 
d=[];
for Nlambda=1:size(SD.Lambda,2)
    
    % Import data from wavelenth Nlambda
    fi = fopen([HDRfile(1:end-4) '.wl' num2str(Nlambda)],'r');
    
    % Concatenate data from wavelength Nlambda
    data{Nlambda} = fscanf(fi,'%g',[size(mask,1)*size(mask,2) inf]);
    data{Nlambda} = data{Nlambda}';
    
    % Close File
    fclose(fi);
    
    % Trash SD pairs that were not used, and keep only the ones listed on
    % MeasList.
    % We will frist assign as NAN the useless data then exclude from
    % variable d
    limpeza = reshape(mask',1,size(mask,1)*size(mask,2));
    rk = find(limpeza==0);
    limpeza(rk) = NaN;
    limpeza = ones(size(data{Nlambda},1),1)*limpeza;
    data{Nlambda} = data{Nlambda}.*limpeza;
    
    % Create matrix similar to .nirs
    d = [d data{Nlambda}];
end

% Remove NANs from the data d
lst = find(isnan(d(1,:)));
d(:,lst)=[];

% Create the time varialbe based on the acquisition frequency
t = linspace(0,length(d)/SD.f,length(d));
t = t';

end

function [s,aux] = GetStim(markers,Tpts)

% Create the stim matrix based on the event markers
if ~isempty(markers)
    s = zeros(Tpts,max(markers(:,2)));
    for i=1:max(markers(:,2))
        lst = find( markers(:,2) == i );
        if ~isempty(markers)
            s(markers(lst,3),i)=1;
        end
    end
else
    s = zeros(Tpts,4);
end

% Create auxiliary variables
aux = zeros(Tpts,4);

end

function probefile = GetProbeFileName
%
% This function will make a window pop up asking for a probe layout file.
% It can read .sd/.layout/nirsInfo.mat files. Once selected, the layout
% file path will be passed as output.
% This function is currently used to ready probe layouts for both DCS and
% NIRS reading functions.

uiwait( msgbox({'Missing a probe configuration for this dataset.'...
    'Please select the probe configuration file (.layout / nirsInfo.mat / .sd) for the dataset'}, ...
    'Warning','warn') );
[probelayout,probepath] = uigetfile('*.layout;*.mat;*.sd','Choose the file containing SD info');
probefile = [probepath probelayout];
end