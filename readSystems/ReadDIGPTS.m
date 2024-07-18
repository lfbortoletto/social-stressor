function ReadDIGPTS(folderPath)

if ~(folderPath(end) == '\' || folderPath(end) == '/')
    folderPath = [folderPath, '\'];
end

[DigptsName,~] = getAllFiles(folderPath);
holdFilename = [DigptsName{1}, 'hold'];
copyfile(DigptsName{1}, holdFilename);
dig = load(DigptsName{1});

nSrcs = 16;
nDets = 31;

if size(dig,1) == (nSrcs + nDets + 5)
    dig = 10*dig(:,[2,3,4]);

    digpts = extract_positions(dig,nSrcs,nDets);

    fid = fopen(DigptsName{1},'w');

    fprintf(fid,['a1: \t ' num2str(dig(1,1)) '\t' num2str(dig(1,2)) '\t' num2str(dig(1,3)) '\r\n']);
    fprintf(fid,['a2: \t ' num2str(dig(2,1)) '\t' num2str(dig(2,2)) '\t' num2str(dig(2,3)) '\r\n']);
    fprintf(fid,['nz: \t ' num2str(dig(3,1)) '\t' num2str(dig(3,2)) '\t' num2str(dig(3,3)) '\r\n']);
    fprintf(fid,['cz: \t ' num2str(dig(4,1)) '\t' num2str(dig(4,2)) '\t' num2str(dig(4,3)) '\r\n']);
    fprintf(fid,['iz: \t ' num2str(dig(5,1)) '\t' num2str(dig(5,2)) '\t' num2str(dig(5,3)) '\r\n']);


    for rk = 1:nSrcs
        fprintf(fid,['s' num2str(rk) ': \t' num2str(dig(rk+5,1)) '\t' num2str(dig(rk+5,2)) '\t' num2str(dig(rk+5,3)) '\r\n'] );
    end
    for rk = 1:nDets
        fprintf(fid, ['d' num2str(rk) ': \t' num2str(dig(rk+5+nSrcs,1)) '\t' num2str(dig(rk+5+nSrcs,2)) '\t' num2str(dig(rk+5+nSrcs,3)) '\r\n']);
    end
    fclose(fid);
else
    dig = 10*dig(:,[2,3,4]);
    for i = 1:size(dig,1)
        for j = 1:size(dig,1)
            digptsDistance(i,j) = norm(dig(i,:) - dig(j,:));
        end
    end
    [badIdx(:,1),badIdx(:,2)] = find(digptsDistance < 10);
    removeDigpts = (badIdx(:,2) - badIdx(:,1)) == 0;
    badIdx(find(removeDigpts), :) = [];
    disp(['Fail to convert file "', DigptsName{1},'". There are ', num2str(size(dig,1) - (nSrcs + nDets + 5)), ' lines missing/exceeding.'])
    disp(['The following lines seems to match: ', num2str(badIdx(:,1)')])
    disp(['                                    ', num2str(badIdx(:,2)')])
end

movefile(DigptsName{1}, [DigptsName{1}(1:end-4), '.digpts'])
movefile(holdFilename, holdFilename(1:end-4))

end