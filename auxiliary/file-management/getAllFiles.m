function [filePathList, fileNameList] = getAllFiles(dirName)
    % Initialize the output file lists
    filePathList = {};
    fileNameList = {};

    % List all files and folders in the current directory
    dirData = dir(dirName);      
    
    % Filter out '.' and '..' directories
    dirIndex = [dirData.isdir];  
    validNames = {dirData(dirIndex).name};
    validNames = validNames(~ismember(validNames,{'.','..'}));

    % Recursively call getAllFiles on subdirectories
    for i = 1:length(validNames)
        nextDir = fullfile(dirName, validNames{i});
        [subFilePaths, subFileNames] = getAllFiles(nextDir);
        filePathList = [filePathList; subFilePaths];
        fileNameList = [fileNameList; subFileNames];
    end

    % Get a list of file names (not directories)
    fileIndex = ~[dirData.isdir];  
    fileName = {dirData(fileIndex).name};

    % Add full path to files and update file lists
    if ~isempty(fileName)
        fullFileName = cellfun(@(x) fullfile(dirName,x),... 
                               fileName, 'UniformOutput', false);
        filePathList = [filePathList; fullFileName']; 
        fileNameList = [fileNameList; fileName']; 
    end
end
