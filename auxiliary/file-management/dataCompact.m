function dataCompact(backupPath, rawPath, validExtensionList)
% Remove all backup files from the raw dataset folder.

% clear raw directory and copy backup.
[filePathList, ~] = getAllFiles(rawPath);
for files = 1:length(filePathList)
    delete(filePathList{files})
end
copyfile(backupPath, rawPath, 'f')

% clear backup files from raw directory.
[filePathList, ~] = getAllFiles(rawPath);
for files = 1:length(filePathList)
    if ~contains(filePathList{files}, validExtensionList)
        delete(filePathList{files})
    end
end

% remove empty folders.
removeEmptyFolders(rawPath);

end

%% Auxiliar functions. 

function removeEmptyFolders(directory)
    % Get the contents of the current directory
    contents = dir(directory);

    % Filter out '.' and '..'
    contents = contents(~ismember({contents.name}, {'.', '..'}));

    % Loop through the contents to check for subdirectories
    for i = 1:length(contents)
        item = contents(i);

        % If the item is a folder, recursively check it
        if item.isdir
            subDir = fullfile(directory, item.name);
            % Recursively remove empty folders in the subdirectory
            removeEmptyFolders(subDir);
        end
    end

    % After recursion, check if this directory is now empty
    % Reload contents to ensure we have the latest information
    contents = dir(directory);
    contents = contents(~ismember({contents.name}, {'.', '..'}));

    if isempty(contents)  % If no contents, remove the empty folder
        rmdir(directory);
    end
end

function deleteFoldersButKeepFiles(directory)
    % Get all contents of the directory
    contents = dir(directory);

    % Loop through each item in the directory
    for i = 1:length(contents)
        item = contents(i);
        
        % Skip '.' and '..'
        if strcmp(item.name, '.') || strcmp(item.name, '..')
            continue;
        end
        
        % Check if the item is a folder
        if item.isdir
            % Get the full path of the folder
            folderPath = fullfile(directory, item.name);
            
            % Recursively delete contents within this folder
            deleteFoldersButKeepFiles(folderPath);
            
            % Delete the folder after all files are moved
            rmdir(folderPath, 's');
        end
    end
end