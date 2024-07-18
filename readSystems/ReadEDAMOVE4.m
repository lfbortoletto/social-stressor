function ReadEDAMOVE4(folderpath, filesave)

edamove.eda.f = 32;
eda = readtable([folderpath, '\eda']); 
edamove.eda.data = eda.Var1;
edamove.eda.t = (0:1/edamove.eda.f:(length(edamove.eda.data) - 1)/edamove.eda.f)';
clear eda

edamove.acc.f = 64;
acc = readtable([folderpath, '\acc']); 
edamove.acc.data_1 = acc.Var1;
edamove.acc.data_2 = acc.Var2;
edamove.acc.data_3 = acc.Var3;
edamove.acc.t = (0:1/edamove.acc.f:(length(edamove.acc.data_1) - 1)/edamove.acc.f)';
clear acc

edamove.marker.f = 64;
markerFID = fopen([folderpath, '\marker.csv']);
markerScan = textscan(markerFID,'%s','Delimiter',';');
fclose(markerFID);
if numel(markerScan{1}) ~= 2 
    disp(['Number of EDA markers: ', num2str(numel(markerScan{1})/2), '. Fix before you continue.']);
    return
else
    disp(['Number of EDA markers: ', num2str(numel(markerScan{1})/2), '.']);
end
edamove.marker.index = str2num(markerScan{1}{1}); % Generalize for more than 1 marker.
edamove.marker.t = (edamove.marker.index/edamove.marker.f)';
clear markerScan markerFID

edamove.temp.f = 1;
temp = readtable([folderpath, '\temp']); 
edamove.temp.data = temp.Var1;
edamove.temp.t = (0:1/edamove.temp.f:(length(edamove.temp.data) - 1)/edamove.temp.f)';
clear temp

edamove.ang.f = 64;
ang = readtable([folderpath, '\angularrate']); 
edamove.ang.data_1 = ang.Var1;
edamove.ang.data_2 = ang.Var2;
edamove.ang.data_3 = ang.Var3;
edamove.ang.t = (0:1/edamove.ang.f:(length(edamove.ang.data_1) - 1)/edamove.ang.f)';
clear acc

save([folderpath, '\', filesave, '.eda'],'edamove')
end