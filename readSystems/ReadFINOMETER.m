function ReadFINOMETER(folderPath, filenameSave)
    
%Inputs:
%   filepaths: struct with fieldnames ("waveforms", "brs", "beats") containing
%   the respective directory for each file.
%
%Output:
%   data: Finometer processed data.

[filenames, ~] = getAllFiles(folderPath);
for files = 1:length(filenames)
    if contains(filenames{files},'waveforms')
        filepaths.waveforms = filenames{files};
    elseif contains(filenames{files},'brs')
        filepaths.brs = filenames{files};
    elseif contains(filenames{files},'beats')
        filepaths.beats = filenames{files};
    end
end

fn = fieldnames(filepaths);
for i = 1:size(fn,1)
    opts = detectImportOptions(filepaths.(fn{i}),'NumHeaderLines',8,'Delimiter',';', 'PreserveVariableNames', true); 
    opts = setvartype(opts,'char');
    data.(fn{i}) = readtable(filepaths.(fn{i}), opts);
end

% Report number of markers.
keyPressedIdx = find(string(data.waveforms.Markers) == "Marker key pressed");
if length(keyPressedIdx) > 1
    disp(['Number of markers: ', num2str(length(keyPressedIdx)), '. Fix before you continue.']);
    return
else
    disp(['Number of markers: ', num2str(length(keyPressedIdx))]);
end

%Convert datetime to seconds.
t0 = datetime(strrep(data.waveforms.("Time (s)"){1},',','.')); %take waveforms start as 0.

%waveforms.
time = data.waveforms.("Time (s)");
time = string(cell2mat(time));
time = strrep(time,',','.');
time = datetime(time) - t0;
data.waveforms.("Time (s)") = seconds(time);

%beats.
time = data.beats.("Time (s)");
time = string(cell2mat(time));
time = strrep(time,',','.');
time = datetime(time) - t0;
data.beats.("Time (s)") = seconds(time);

%brs.
time = data.brs.("Time(s)");
time = string(cell2mat(time));
time = strrep(time,',','.');
time = datetime(time) - t0;
data.brs.("Time(s)") = seconds(time);
data.brs = renamevars(data.brs,'Time(s)','Time (s)');

lst.waveforms = 2:6;
lst.beats = 2:12;
lst.brs = 2:8;

for i = lst.waveforms
    data.waveforms.(i) = str2num(char(replace(data.waveforms.(i), ',','.')));
end

for i = lst.beats
    data.beats.(i) = str2num(char(replace(data.beats.(i), ',','.')));
end

for i = lst.brs
    data.brs.(i) = str2num(char(replace(data.brs.(i), ',','.')));
end

save([folderPath, filenameSave, '.finometer'], 'data')

end